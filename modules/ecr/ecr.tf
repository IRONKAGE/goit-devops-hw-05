resource "aws_ecr_repository" "repo" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}
