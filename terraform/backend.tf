terraform {
  backend "s3" {
    bucket  = "bbhealthapp-tfstate-ajit-20261004"
    key     = "bbhealthapp/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
