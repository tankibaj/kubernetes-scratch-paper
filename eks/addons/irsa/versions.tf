terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }
  }
#  backend "s3" {
#    bucket         = "terraform-state"
#    key            = "aws/irsa.tfstate"
#    dynamodb_table = "terraform-state"
#    region         = "eu-central-1"
#    kms_key_id     = "arn:aws:kms:eu-central-1:000000000000:alias/terraform"
#  }
}

provider "aws" {
  region = "eu-central-1"

#  assume_role {
#    role_arn = "arn:aws:iam::111111111111:role/OrganizationAccountAccessRole"
#  }
}