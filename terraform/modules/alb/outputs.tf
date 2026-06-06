output "dns_name" {
  description = "ALB の DNS 名"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ECS サービスに渡すターゲットグループ ARN"
  value       = aws_lb_target_group.api.arn
}

output "listener_arn" {
  description = "ECS サービスの depends_on に渡すリスナー ARN"
  value       = aws_lb_listener.http.arn
}

output "security_group_id" {
  description = "ECS の ingress 設定に渡す ALB セキュリティグループ ID"
  value       = aws_security_group.alb.id
}
