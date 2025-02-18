data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["KY-*"]
  }
}

data "http" "public_ip" {
  url = "http://checkip.amazonaws.com/"
}

data "aws_lb" "alb" {
  arn = var.lb_arn
}