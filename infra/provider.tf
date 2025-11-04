terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "bucket-soutenance"
    key            = "devops-project-appointment/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dynamo-soutenance"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
