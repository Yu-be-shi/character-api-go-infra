variable "name" {
  description = "ALB の名前（リソース名のプレフィックス）"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALB を配置するパブリックサブネット ID のリスト"
  type        = list(string)
}

variable "target_port" {
  description = "ALB がトラフィックを転送するコンテナのポート"
  type        = number
  default     = 8080
}

variable "tags" {
  type    = map(string)
  default = {}
}
