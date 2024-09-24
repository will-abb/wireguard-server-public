locals {
  name        = "ec2_instance_manager_lambda"
  description = "This Lambda function manages EC2 instances (start, stop, terminate)."
  handler     = "manage_instance.lambda_handler"
  api_id      = "ahfyz9wjz0"
}

module "ec2_instance_manager_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.name
  description   = local.description
  handler       = local.handler
  runtime       = "python3.10"
  source_path   = "./code"
  create_role   = true

  assume_role_policy_statements = {
    lambda_assume_role = {
      effect  = "Allow",
      actions = ["sts:AssumeRole"],
      principals = [
        {
          type        = "Service",
          identifiers = ["lambda.amazonaws.com"]
        }
      ]
    }
  }

  attach_policy_statements = true

  policy_statements = {
    ec2_access = {
      effect = "Allow",
      actions = [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ],
      resources = ["*"]
    }
  }

  allowed_triggers = {
    APIGatewayGET = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:us-east-1:005343251202:${local.api_id}/*/GET/instance"
    },
    APIGatewayPOST = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:us-east-1:005343251202:${local.api_id}/*/POST/instance"
    },
    APIGatewayPUT = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:us-east-1:005343251202:${local.api_id}/*/PUT/instance"
    },
    APIGatewayDELETE = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:us-east-1:005343251202:${local.api_id}/*/DELETE/instance"
    }
  }
}

data "aws_caller_identity" "current" {}
