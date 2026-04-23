provider "aws" {
  region            = "eu-central-1"  # Франкфурт
  s3_use_path_style = var.environment == "dev" ? true : false
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "${var.project_name}-${var.environment}-tf-state-123"
  table_name  = "${var.project_name}-${var.environment}-locks"
}

module "vpc" {
  source             = "./modules/vpc"
  environment        = var.environment
  project_name       = var.project_name
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  vpc_name           = "${var.project_name}-${var.environment}-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "${var.project_name}-${var.environment}-ecr"
  scan_on_push = var.environment == "prod" ? true : false
}
