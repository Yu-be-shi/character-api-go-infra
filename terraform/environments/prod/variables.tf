variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "image_tag" {
  description = "デプロイする Docker イメージのタグ（CI から渡す）"
  type        = string
  default     = "latest"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "ALB を配置するパブリックサブネット ID"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "ECS タスクを配置するプライベートサブネット ID"
  type        = list(string)
}

# ── db-infra の terraform output から取得して設定する ──────────────────────────

variable "db_secret_arn" {
  description = "DB 認証情報の Secrets Manager ARN（db-infra output: db_secret_arn）"
  type        = string
}

variable "rds_security_group_id" {
  description = "RDS のセキュリティグループ ID（db-infra output: rds_security_group_id）"
  type        = string
}

variable "api_key_secret_arn" {
  description = "INTERNAL_API_KEY の Secrets Manager ARN（手動で作成して ARN を設定）"
  type        = string
}

variable "cors_origins" {
  description = "CORS 許可オリジン（カンマ区切り）。ドメイン未取得なら一時的に '*' か STG オリジン等"
  type        = string
  default     = "*"
}

variable "ephemeral" {
  description = "使い捨て(up/down)環境か。true で destroy 容易な設定（ECR force_delete 等）になる"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "CloudWatch アラーム通知先 ARN（SNS 等）。空なら記録のみ"
  type        = list(string)
  default     = []
}
