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
- **本番**：コスト最小化のため ElastiCache を使わず、**ECS タスクに Redis サイドカーコンテナ**を同梱
  （`modules/ecs`）。awsvpc なので API は `localhost:6379` で到達。タスクと一緒に作られ・消える。

## 本番スイッチ（AWS ephemeral / up・down）

使う時だけ立てて普段は完全に消す「使い捨て本番」。`.github/workflows/prod-switch.yml` を手動実行
（Actions → Run workflow）で **up=一気に構築 / down=全削除**。毎日深夜に自動 down（消し忘れ防止）。

- データは永続させない（`ephemeral=true` で RDS は削除保護無効・final snapshot 無し）。up のたびに
  seeds で初期データを再投入。
- up は循環依存（RDS↔API SG）を3段（DB→API→DB 再適用）で解消し、イメージ build/push と
  マイグレーション・ECS 再デプロイまで実施。down は API→DB の順に destroy。
- VPC/サブネット・`INTERNAL_API_KEY` の Secret は switch 外（恒久）。
- **HTTPS は保留**（独自ドメイン未取得のため HTTP）。`modules/alb` は将来 ACM 証明書 ARN を変数で
  受け取れば 443 リスナーを足せる構成にする余地を残す。

## CI（このリポジトリ）

- `deploy.yml` … `main` への通常デプロイ（ECS ローリング）。
- `prod-switch.yml` … 上記の up/down スイッチ。
- `deploy-stg.yml` … `develop` で**自宅 STG**（self-hosted runner）に compose デプロイ（後述）。
- `security.yml` … gitleaks（秘密混入検査）。`dependabot.yml` で terraform/actions を定期更新。

## STG（自宅サーバー）デプロイ

`develop` への push で、自宅 WSL の **self-hosted runner（ラベル `character-stg`）** が
`$STG_ROOT/apis/character-api-go-infra` を最新化し `docker compose up -d --build`。
詳細・runner セットアップはメタリポジトリ README の「STG（自宅）」を参照。

## 初回セットアップの順序

1. **db-infra** で `terraform apply` → `db_secret_arn`、`rds_security_group_id` を取得
2. **api-infra** の `prod.tfvars` に上記の値を設定して `terraform apply`
3. api-infra の `terraform output` の `ecs_security_group_id` を db-infra の `api_security_group_ids` に追加して `terraform apply`

## GitHub Actions に設定する Secrets / Variables

| 種別 | 名前 | 説明 |
|---|---|---|
| Secret | `AWS_ACCESS_KEY_ID` | AWS 認証情報 |
| Secret | `AWS_SECRET_ACCESS_KEY` | AWS 認証情報 |
| Secret | `GH_PAT` | prod-switch が他リポジトリ(db-infra/api/db)を checkout する PAT（repo 読み取り） |
| Secret | `TF_VAR_VPC_ID` | VPC ID |
| Secret | `TF_VAR_PUBLIC_SUBNET_IDS` | パブリックサブネット ID（JSON 配列形式） |
| Secret | `TF_VAR_PRIVATE_SUBNET_IDS` | プライベートサブネット ID（JSON 配列形式） |
| Secret | `TF_VAR_DB_SECRET_ARN` | db-infra output: db_secret_arn |
| Secret | `TF_VAR_RDS_SG_ID` | db-infra output: rds_security_group_id |
| Secret | `TF_VAR_API_KEY_SECRET_ARN` | INTERNAL_API_KEY の Secrets Manager ARN |
| Variable | `AWS_ECR_REPOSITORY` | terraform output: ecr_repository_url |
| Variable | `ECS_CLUSTER` | terraform output: ecs_cluster_name |
| Variable | `ECS_SERVICE` | terraform output: ecs_service_name |
