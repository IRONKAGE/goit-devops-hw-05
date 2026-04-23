output "repository_url" {
  # Якщо ми на prod (є репозиторій) - виводимо його URL. Якщо на dev - виводимо заглушку.
  value = var.scan_on_push ? aws_ecr_repository.repo[0].repository_url : "Емулятор (ECR вимкнено локально)"
}
