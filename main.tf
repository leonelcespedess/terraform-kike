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

resource "aws_apigatewayv2_api" "kike_gateway" {
  name          = "kike-gateway"
  protocol_type = "HTTP"
  description   = "API Gateway for EC2 Nginx instance"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
    max_age       = 300
  }
}

# Resource: aws_apigatewayv2_integration (Integración con la Elastic IP del EC2)
resource "aws_apigatewayv2_integration" "ec2_integration" {
  api_id             = aws_apigatewayv2_api.kike_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"

  # Usa la Elastic IP expuesta por el módulo `ec2_instance`
  integration_uri      = "http://${module.ec2_instance.elastic_ip}"
  timeout_milliseconds = 29000
}

# Resource: aws_apigatewayv2_route (Ruta /instancia)
resource "aws_apigatewayv2_route" "instancia_route" {
  api_id    = aws_apigatewayv2_api.kike_gateway.id
  route_key = "ANY /instancia"
  target    = "integrations/${aws_apigatewayv2_integration.ec2_integration.id}"
}

# Resource: aws_apigatewayv2_stage (Stage por defecto $default)
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.kike_gateway.id
  name        = "$default"
  auto_deploy = true
}

# Output: URL del API Gateway para que puedas probarlo
output "api_gateway_url" {
  description = "The invoke URL of the API Gateway HTTP"
  value       = aws_apigatewayv2_api.kike_gateway.api_endpoint
}