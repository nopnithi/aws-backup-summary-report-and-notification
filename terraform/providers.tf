terraform {
  required_version = ">= 1.1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.5.0"
    }
  }
}

provider "aws" {
  region                   = var.region
  profile                  = "default"
  shared_credentials_files = ["~/.aws/credentials"]

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.account_id}:role/terraform"
  # }
}