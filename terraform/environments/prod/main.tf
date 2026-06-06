provider "aws" {
  region = var.aws_region
}

module "alb" {
  source = "../../modules/alb"

  name              = "character-api-prod"
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  target_port       = 8080

  tags = local.tags
}

module "ecs" {
  source = "../../modules/ecs"

  service_name   = "character-api"
  cluster_name   = "character-api-prod"
  ecr_name       = "character-api"
  image_tag      = var.image_tag
  aws_region     = var.aws_region
  vpc_id         = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn
  alb_listener_arn      = module.alb.listener_arn

  # db-infra の terraform output から取得した値を設定する
  db_secret_arn          = var.db_secret_arn
  rds_security_group_id  = var.rds_security_group_id
  api_key_secret_arn     = var.api_key_secret_arn

  cors_origins = "https://your-domain.com"

  tags = local.tags
}

locals {
  tags = {
    Environment = "prod"
    Project     = "character-system"
    ManagedBy   = "terraform"
  }
}
