terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-kike"
    key            = "./terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table-kike"  # Optional, for state locking
  }
}

provider "aws" {
  region = "us-east-1"
}

module "ec2_instance" {
  source        = "./modules/ec2-instance"
  ami           = "ami-0e2c8caa4b6378d8c"
  instance_type = "t2.micro"
}

module "ayudantia_frontend" {
  source = "./modules/s3"
  bucket_name = "front-kike-2025"

  website_content_path = "./dist"

}