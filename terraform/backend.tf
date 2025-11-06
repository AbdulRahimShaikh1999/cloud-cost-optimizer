terraform {
  backend "s3" {
    bucket         = "terraform-backend-cloud-cost-optimizer"
    key            = "envs/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-backend-cloud-cost-optimizer"
    encrypt        = true
  }
  
}
