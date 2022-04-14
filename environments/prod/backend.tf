terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "sym-tfstate-456302726331"
    key            = "prod/terraform.tfstate"
    dynamodb_table = "sym-tfstate-456302726331-lock"
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
}
