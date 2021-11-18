terraform {
  backend "s3" {
    bucket  = "playground.tf"
    key     = "tfdeploypipe/terraform.tfstate"
    region  = "us-east-2"
    profile = "personal"
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "personal"
}
