resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "${var.project}-api"
  protocol_type = "HTTP"

  disable_execute_api_endpoint = false
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id = aws_apigatewayv2_api.api_gateway.id

  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "fargate" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.vpc_link.id
  integration_uri    = aws_lb_listener.api_listener_http.arn

}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "ANY /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.fargate.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_authorizer.id

}

resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = "vpc-link-to-internal-load-balancer"
  subnet_ids         = var.private_subnets_ids
  security_group_ids = []

  tags = local.tags
}


resource "aws_apigatewayv2_authorizer" "cognito_authorizer" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  name             = "cognito-authorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = var.cognito_authorizer_issuer
    audience = var.cognito_authorizer_audience
  }
}
