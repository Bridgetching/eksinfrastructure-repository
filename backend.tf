terraform {
  backend "s3" {
    bucket = "b-eks-terraform-state-sandbox"
    key    = "key/terraform.tfstate"
    region = "us-east-1"
  }
}
