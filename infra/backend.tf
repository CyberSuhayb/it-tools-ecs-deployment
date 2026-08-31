terraform {
  backend "s3" {
    bucket         = "it-tools-tfstate-940702769327"
    key            = "it-tools/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "it-tools-tfstate-lock"
    encrypt        = true
  }
}