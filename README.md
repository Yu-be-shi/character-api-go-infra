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
