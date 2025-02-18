terraform {
  backend "s3" {
    bucket = "ky-s3-terraform"
    key    = "ky-tf-waf-acl.tfstate"
    region = "us-east-1"
  }
}