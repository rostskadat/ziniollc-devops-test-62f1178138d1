provider "aws" {
  //For the profile is better to set environment variables
  //Use the afb-tf-deployment from lz-deployment account
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

# BEWARE: make sure that the dynamodb and the S3 bucket are in sync with the 
# names in the bootstrap folder

# The S3 bucket and DynamoDB table should have been created before hand.
# Refere to the README for more details.
terraform {
  backend "s3" {
    bucket         = "ziniollc-devops-test-62f1178138d1"
    key            = "eu-west-1/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "ziniollc-devops-test-62f1178138d1-tfstates-lock"

    # NOTE: we should not use a profile (with the associated key) but 
    # using IAM roles is out of scope of the excercise
    profile = "ziniollc-devops-test-62f1178138d1"

  }

  required_providers {
    aws = {
      version = "~> 4.17.0"
      source  = "hashicorp/aws"
    }
  }
}
