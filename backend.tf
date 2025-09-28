terraform {
  backend "s3" {
    bucket = "b-infrastructure"
    key    = "key/terraform.tfstate"
    region = "us-east-1"
  }
}