# this bucket contains the terraform state for the infrastructure
resource "aws_s3_bucket" "terraform_tfstates" {
  bucket = "ziniollc-devops-test-62f1178138d1"
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# this dynamodb table is used to avoid concurrent changes on the 
# infrastructure
resource "aws_dynamodb_table" "terraform_tfstates_lock" {
  name         = "ziniollc-devops-test-62f1178138d1-tfstates-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

}


#
