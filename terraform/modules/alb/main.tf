resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Allow HTTP/HTTPS inbound"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 443 はリスナーを作るまで開けない（HTTPS はドメイン取得後に ACM 変数で有効化する想定。
  # リスナーの無いポートの開放は不要な攻撃面になるだけ）。

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_lb" "main" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  tags               = var.tags
}

resource "aws_lb_target_group" "api" {
  name        = "${var.name}-api"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # 既定 300 秒の drain は ephemeral（毎晩 destroy）には長すぎ、down を無駄に遅くする。
  deregistration_delay = 15

  health_check {
    path                = "/healthz"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}
