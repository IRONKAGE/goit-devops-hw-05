output "s3_bucket" { value = module.s3_backend.s3_bucket_name }
output "vpc_id" { value = module.vpc.vpc_id }
output "ecr_url" { value = module.ecr.repository_url }
