#------------------------------------------------------------------------------
#
# This creates the ECR respository where the docker image from the pipeline will
# be stored
#
resource "aws_ecr_repository" "repository" {
  name = "ziniollc-devops-test-62f1178138d1"

  image_tag_mutability = "MUTABLE" # for convenience

  image_scanning_configuration {
    scan_on_push = true
  }
}