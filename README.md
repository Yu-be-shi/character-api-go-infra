# api-infra

character-api（Go/Echo）専用のインフラリポジトリ。
API サーバーのプロビジョニング・デプロイ・セキュリティ境界を管理する。

## 責務

- AWS ECS Fargate + ALB + ECR のプロビジョニング（Terraform）
- Docker イメージのビルド・push・ECS デプロイ CI（GitHub Actions）
- ローカル・CI 用の API + DB 起動（Docker Compose）

## リポジトリレイアウト前提

```
workspace/
├── db/         # character-db
├── api/        # character-api
└── api-infra/  # このリポジトリ
```

## 環境別の使い方

### ローカル / CI（API + DB 起動）

```bash
docker compose up
```

### 本番（Terraform）

```bash
cd terraform/environments/prod

terraform init
cp prod.tfvars.example prod.tfvars  # 値を編集する

terraform plan  -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

`prod.tfvars` に設定する値のうち、`db_secret_arn` と `rds_security_group_id` は
**db-infra の `terraform output`** から取得する。

## セキュリティ境界

- ECS タスクはプライベートサブネットに配置し、ALB 経由でのみ公開
- DB 接続情報（DSN）は Secrets Manager から取得。タスク定義に平文で書かない
- DB へのアクセスは ECS のセキュリティグループのみに限定（db-infra 側で制御）
- `INTERNAL_API_KEY` も Secrets Manager から注入（`TF_VAR_API_KEY_SECRET_ARN`）。
  application 側の `CHARACTER_API_KEY` と同値にすること（不一致だと API が 401）

## 冪等性キー用 Redis（character-api 専有）

`POST /characters` の二重送信を重複排除するため、character-api は Redis を使う。これは
**character-api だけが使う private なストア**で、共有スキーマの `character-db` とは別物（Database per Service）。

- **ローカル**：この compose に `character-api-redis`（redis:7-alpine）を同梱。API へ
  `REDIS_ADDR=character-api-redis:6379` を渡す。`REDIS_ADDR` 未設定なら冪等性機能は無効。
- **本番（TODO）**：ElastiCache for Redis を Terraform で作成し、エンドポイントを ECS タスクの
  `REDIS_ADDR` 環境変数に渡す（DB と同様、API の SG からのみ到達可能にする）。現状は
  ローカル compose のみ実装済みで、ElastiCache モジュールは未作成。

## 今後の改善（運用上の推奨）

現状の構成に対する、優先度付きの改善候補。

- **ALB を HTTPS 化（推奨・高）**：現在 ALB リスナーは HTTP のみ。本番では ACM 証明書を発行し
  HTTPS(443) リスナー + HTTP→HTTPS リダイレクトを追加する。
- **CORS オリジンを変数化（中）**：`modules/ecs` の `cors_origins` をハードコードせず
  `variables.tf` / `prod.tfvars` から渡す。
- **ECR タグの不変化（中）**：`image_tag_mutability` を `IMMUTABLE` にする（CI は既に commit SHA
  タグで push しているため整合する）。`latest` の上書き事故を防ぐ。
- **OpenAPI 型の自動生成を CI へ（低）**：application 側の `generate:types`（`openapi-typescript`）を
  CI に組み込み、手書きの `Character` 型と API スキーマの乖離を防ぐ。

## 初回セットアップの順序

1. **db-infra** で `terraform apply` → `db_secret_arn`、`rds_security_group_id` を取得
2. **api-infra** の `prod.tfvars` に上記の値を設定して `terraform apply`
3. api-infra の `terraform output` の `ecs_security_group_id` を db-infra の `api_security_group_ids` に追加して `terraform apply`

## GitHub Actions に設定する Secrets / Variables

| 種別 | 名前 | 説明 |
|---|---|---|
| Secret | `AWS_ACCESS_KEY_ID` | AWS 認証情報 |
| Secret | `AWS_SECRET_ACCESS_KEY` | AWS 認証情報 |
| Secret | `TF_VAR_VPC_ID` | VPC ID |
| Secret | `TF_VAR_PUBLIC_SUBNET_IDS` | パブリックサブネット ID（JSON 配列形式） |
| Secret | `TF_VAR_PRIVATE_SUBNET_IDS` | プライベートサブネット ID（JSON 配列形式） |
| Secret | `TF_VAR_DB_SECRET_ARN` | db-infra output: db_secret_arn |
| Secret | `TF_VAR_RDS_SG_ID` | db-infra output: rds_security_group_id |
| Secret | `TF_VAR_API_KEY_SECRET_ARN` | INTERNAL_API_KEY の Secrets Manager ARN |
| Variable | `AWS_ECR_REPOSITORY` | terraform output: ecr_repository_url |
| Variable | `ECS_CLUSTER` | terraform output: ecs_cluster_name |
| Variable | `ECS_SERVICE` | terraform output: ecs_service_name |
