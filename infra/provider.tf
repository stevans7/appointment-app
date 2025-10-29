terraform {
  required_version = ">= 1.3.0"
  backend "s3" {
    bucket         = "bucket-soutenance" # replace before use
    key            = "devops-project-appointment/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "dynamo-soutenance"   # replace before use
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
