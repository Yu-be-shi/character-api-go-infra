output "api_endpoint" {
  description = "API の公開エンドポイント"
  value       = "http://${module.alb.dns_name}"
}

output "ecr_repository_url" {
  description = "Docker イメージの push 先（CI の AWS_ECR_REPOSITORY に設定する）"
  value       = module.ecs.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "CI の ECS_CLUSTER に設定する"
  value       = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  description = "CI の ECS_SERVICE に設定する"
  value       = module.ecs.ecs_service_name
}

output "ecs_security_group_id" {
  description = "db-infra の api_security_group_ids に追加する ECS SG ID"
  value       = module.ecs.ecs_security_group_id
}
