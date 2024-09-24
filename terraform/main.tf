terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "prod-terraform-backend-2023"
    key            = "ec2/prod/wireguard-server/terraform.tfstate"
    dynamodb_table = "terraform-lock"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      project     = "wireguard"
      environment = "prod"
      managed     = "terraform"
      repo        = "https://bitbucket.org/williseed1/wireguard-server"
    }
  }
}
