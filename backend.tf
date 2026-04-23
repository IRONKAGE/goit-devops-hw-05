# terraform {
#   backend "s3" {
#     bucket         = "ironkage-tf-state-2026-unique-123"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "eu-central-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
