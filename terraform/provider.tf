terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.72.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Terrform Init run error: 5.71.0 Not Available via registry.terraform.io
# https://github.com/hashicorp/terraform-provider-aws/issues/39694 