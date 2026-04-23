resource "aws_ecr_repository" "repo" {
  # Обходимо баг LocalStack: створюємо ECR тільки на Проді (де scan_on_push = true)
  count = var.scan_on_push ? 1 : 0
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}
