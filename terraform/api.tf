locals {
  api_gateway = {
    name            = "ec2-instance-manager"
    description     = "API to manage EC2 instance states"
    lambda_arn      = "arn:aws:lambda:us-east-1:005343251202:function:ec2_instance_manager_lambda"
    domain_endpoint = "api.williseed.com"
    domain_zone_id  = data.aws_route53_zone.public.zone_id
  }
}

data "aws_route53_zone" "public" {
  name         = "williseed.com"
  private_zone = false
}

resource "aws_api_gateway_rest_api" "ec2_instance_manager" {
  name        = local.api_gateway.name
  description = local.api_gateway.description
}

resource "aws_api_gateway_resource" "instance_resource" {
  rest_api_id = aws_api_gateway_rest_api.ec2_instance_manager.id
  parent_id   = aws_api_gateway_rest_api.ec2_instance_manager.root_resource_id
  path_part   = "instance"
}

resource "aws_api_gateway_method" "get_instance_status_method" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_instance_manager.id
  resource_id      = aws_api_gateway_resource.instance_resource.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "post_start_instance_method" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_instance_manager.id
  resource_id      = aws_api_gateway_resource.instance_resource.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "put_stop_instance_method" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_instance_manager.id
  resource_id      = aws_api_gateway_resource.instance_resource.id
  http_method      = "PUT"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "delete_terminate_instance_method" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_instance_manager.id
  resource_id      = aws_api_gateway_resource.instance_resource.id
  http_method      = "DELETE"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "get_instance_status_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_instance_manager.id
  resource_id             = aws_api_gateway_resource.instance_resource.id
  http_method             = aws_api_gateway_method.get_instance_status_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${local.api_gateway.lambda_arn}/invocations"
}

resource "aws_api_gateway_integration" "post_start_instance_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_instance_manager.id
  resource_id             = aws_api_gateway_resource.instance_resource.id
  http_method             = aws_api_gateway_method.post_start_instance_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${local.api_gateway.lambda_arn}/invocations"
}

resource "aws_api_gateway_integration" "put_stop_instance_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_instance_manager.id
  resource_id             = aws_api_gateway_resource.instance_resource.id
  http_method             = aws_api_gateway_method.put_stop_instance_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${local.api_gateway.lambda_arn}/invocations"
}

resource "aws_api_gateway_integration" "delete_terminate_instance_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_instance_manager.id
  resource_id             = aws_api_gateway_resource.instance_resource.id
  http_method             = aws_api_gateway_method.delete_terminate_instance_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${local.api_gateway.lambda_arn}/invocations"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.get_instance_status_integration,
    aws_api_gateway_integration.post_start_instance_integration,
    aws_api_gateway_integration.put_stop_instance_integration,
    aws_api_gateway_integration.delete_terminate_instance_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.ec2_instance_manager.id
  stage_name  = "prod"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = local.api_gateway.domain_endpoint
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
  zone_id = local.api_gateway.domain_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_api_gateway_domain_name" "custom_domain" {
  domain_name     = local.api_gateway.domain_endpoint
  certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
}

resource "aws_api_gateway_base_path_mapping" "api_mapping" {
  domain_name = aws_api_gateway_domain_name.custom_domain.domain_name
  api_id      = aws_api_gateway_rest_api.ec2_instance_manager.id
  stage_name  = aws_api_gateway_deployment.api_deployment.stage_name
  # if you don't set this below then the custom domain endpoint should not include the stage name on the URL
  base_path = aws_api_gateway_deployment.api_deployment.stage_name # Explicitly setting the base path
}

resource "aws_route53_record" "api_a_record" {
  zone_id = local.api_gateway.domain_zone_id
  name    = local.api_gateway.domain_endpoint
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.custom_domain.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.custom_domain.cloudfront_zone_id
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_api_key" "api_key" {
  name        = "MyAPIKey"
  description = "API key for accessing the ec2-instance-manager API"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "MyUsagePlan"

  api_stages {
    api_id = aws_api_gateway_rest_api.ec2_instance_manager.id
    stage  = aws_api_gateway_deployment.api_deployment.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}
