# コスト・監視のガードレール（恒久リソース）。
# ephemeral な本番 up/down とは別 state で一度だけ apply する。環境を down しても
# 「消し忘れ・想定外課金」を検知できるよう、これは destroy しない。
#
# 出力の sns_topic_arn を、本番 up 時の TF_VAR_alarm_actions（CloudWatch アラームの通知先）に渡す。
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# アラート通知用 SNS トピック（CloudWatch アラーム・Budgets 共通の通知先）。
resource "aws_sns_topic" "alerts" {
  name = "character-system-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# AWS Budgets が SNS に publish できるようトピックポリシーを許可する。
data "aws_iam_policy_document" "sns_publish" {
  statement {
    sid     = "AllowBudgetsPublish"
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    resources = [aws_sns_topic.alerts.arn]
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.sns_publish.json
}

# 月次コスト予算。実コストが閾値%を超えたら通知、予測が 100% 超でも通知。
resource "aws_budgets_budget" "monthly" {
  name         = "character-system-monthly"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.alerts.arn]
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
