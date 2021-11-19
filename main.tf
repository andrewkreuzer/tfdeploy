terraform {
  backend "s3" {
    bucket  = "terraform.playground"
    key     = "tfdeploypipe/terraform.tfstate"
    region  = "us-east-2"
    profile = "sandbox"
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "sandbox"
}
