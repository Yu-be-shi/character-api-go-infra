variable "service_name" {
  description = "ECS サービス名（リソース名のプレフィックスになる）"
  type        = string
}

variable "cluster_name" {
  description = "ECS クラスター名"
  type        = string
}

variable "ecr_name" {
  description = "ECR リポジトリ名"
  type        = string
}

variable "image_tag" {
  description = "デプロイする Docker イメージのタグ"
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "Fargate タスクの CPU ユニット（256 = 0.25 vCPU）"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate タスクのメモリ (MB)"
  type        = number
  default     = 512
}

variable "container_port" {
  description = "コンテナが LISTEN するポート"
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "ECS タスクの希望稼働数"
  type        = number
  default     = 1
}

variable "log_level" {
  type    = string
  default = "info"
}

variable "cors_origins" {
  description = "CORS 許可オリジン（カンマ区切り）"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "ECS タスクを配置するプライベートサブネット ID"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB のセキュリティグループ ID（alb モジュールの output から取得）"
  type        = string
}

variable "target_group_arn" {
  description = "ALB ターゲットグループ ARN（alb モジュールの output から取得）"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB リスナー ARN（depends_on 用）"
  type        = string
}

variable "db_secret_arn" {
  description = "DB 認証情報の Secrets Manager ARN（db-infra の output から取得）"
  type        = string
}

variable "api_key_secret_arn" {
  description = "INTERNAL_API_KEY の Secrets Manager ARN"
  type        = string
}

variable "rds_security_group_id" {
  description = "RDS セキュリティグループ ID（db-infra の output から取得。ECS SG を RDS に登録するために使用）"
  type        = string
}

variable "aws_region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
