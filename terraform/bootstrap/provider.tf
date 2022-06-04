provider "aws" {
  region = "eu-west-1"

  # NOTE: we should not use a profile (with the associated key) but 
  # using IAM roles is out of scope of the excercise
  profile = "ziniollc-devops-test-62f1178138d1"

  default_tags {
    tags = {
      iac-type = "terraform"
      project  = "ziniollc-devops-test-62f1178138d1"
    }
  }
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    aws = {
      version = "~> 3.70.0"
      source  = "hashicorp/aws"
    }
  }
}
