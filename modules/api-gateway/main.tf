# Resource: aws_apigatewayv2_api (API Gateway HTTP)
resource "aws_apigatewayv2_api" "kike_gateway" {
  name          = "kike-gateway"
  protocol_type = "HTTP"
  description   = "API Gateway for EC2 Nginx instance"

  # Configuración CORS para permitir todos los orígenes
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"] # Permite todos los métodos HTTP
    allow_headers = ["*"] # Permite todas las cabeceras
    max_age       = 300   # Cache preflight requests por 5 minutos
  }
}

# Resource: aws_apigatewayv2_integration (Integración con la Elastic IP)
resource "aws_apigatewayv2_integration" "ec2_integration" {
  api_id           = aws_apigatewayv2_api.kike_gateway.id
  integration_type = "HTTP_PROXY" # Usamos HTTP_PROXY para integración directa con una URL HTTP
  integration_method = "ANY" # Esto permite que cualquier método HTTP (GET, POST, etc.) sea manejado

  # Construimos la URL de destino usando la Elastic IP de tu módulo EC2
  # Asumimos que Nginx escucha en el puerto 80 (HTTP)
  integration_uri  = "http://${module.ec2_instance.elastic_ip}"
  
  # Este timeout es importante para evitar que las peticiones se queden colgadas
  timeout_milliseconds = 29000 # AWS API Gateway tiene un timeout máximo de 29 segundos
}

# Resource: aws_apigatewayv2_route (Ruta /instancia)
resource "aws_apigatewayv2_route" "instancia_route" {
  api_id    = aws_apigatewayv2_api.kike_gateway.id
  route_key = "ANY /instancia" # Esto significa que cualquier método a /instancia será manejado
  target    = "integrations/${aws_apigatewayv2_integration.ec2_integration.id}"
}

# Resource: aws_apigatewayv2_stage (Stage por defecto $default)
# Es necesario un stage para que la API sea invocable
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.kike_gateway.id
  name        = "$default" # El stage por defecto para API Gateway HTTP
  auto_deploy = true       # Despliega automáticamente los cambios
}

# Output: URL del API Gateway
output "api_gateway_url" {
  description = "The invoke URL of the API Gateway HTTP"
  value       = aws_apigatewayv2_api.kike_gateway.api_endpoint
}