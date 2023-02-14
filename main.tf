locals {
  lambda_function_name = var.lambda_function_prefix == null ? format("%saws-scheduler", var.resource_name_prefix) : format("%s%saws-scheduler", var.lambda_function_prefix, var.resource_name_prefix)
}

# Cloudwatch event rule
resource "aws_cloudwatch_event_rule" "check-scheduler-event" {
  count               = var.create ? 1 : 0
  name                = var.cloudwatch_event_rule_prefix == null ? format("%slambda-scheduler-check-event", var.resource_name_prefix) : format("%s%slambda-scheduler-check-event", var.cloudwatch_event_rule_prefix, var.resource_name_prefix)
  description         = "check-scheduler-event"
  schedule_expression = var.schedule_expression
  depends_on          = [aws_lambda_function.scheduler_lambda]
}

# Cloudwatch event target
resource "aws_cloudwatch_event_target" "check-scheduler-event-lambda-target" {
  count     = var.create ? 1 : 0
  target_id = "check-scheduler-event-lambda-target"
  rule      = aws_cloudwatch_event_rule.check-scheduler-event[0].name
  arn       = aws_lambda_function.scheduler_lambda[0].arn
}

# IAM Role for Lambda function
resource "aws_iam_role" "scheduler_lambda" {
  count              = var.create ? 1 : 0
  name               = var.iam_role_prefix == null ? format("%slambda-scheduler", var.resource_name_prefix) : format("%s%slambda-scheduler", var.iam_role_prefix, var.resource_name_prefix)
  permissions_boundary = var.permissions_boundary != "" ? var.permissions_boundary : ""
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

data "aws_iam_policy_document" "ec2-access-scheduler" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:RebootInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:CreateTags",
      "rds:DescribeDBInstances",
      "rds:DescribeDBClusters",
      ## not yet implemented in lambda function
      # "rds:RebootDBCluster",
      # "rds:RebootDBInstance",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
      "rds:ListTagsForResource",
      "rds:AddTagsToResource",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ec2-access-scheduler" {
  count  = var.create ? 1 : 0
  name   = var.iam_policy_prefix == null ? format("%slambda-scheduler-ec2-access", var.resource_name_prefix) : format("%s%slambda-scheduler-ec2-access", var.iam_policy_prefix, var.resource_name_prefix)
  path   = "/"
  policy = data.aws_iam_policy_document.ec2-access-scheduler.json
}

resource "aws_iam_role_policy_attachment" "ec2-access-scheduler" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.scheduler_lambda[0].name
  policy_arn = aws_iam_policy.ec2-access-scheduler[0].arn
}

## create custom role

resource "aws_iam_policy" "scheduler_aws_lambda_basic_execution_role" {
  count       = var.create ? 1 : 0
  name        = var.iam_policy_prefix == null ? format("%slambda-scheduler-aws-lambda-basic-execution", var.resource_name_prefix) : format("%s%slambda-scheduler-aws-lambda-basic-execution", var.iam_policy_prefix, var.resource_name_prefix)
  path        = "/"
  description = "AWSLambdaBasicExecutionRole"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "basic-exec-role" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.scheduler_lambda[0].name
  policy_arn = aws_iam_policy.scheduler_aws_lambda_basic_execution_role[0].arn
}

# AWS Lambda need a zip file
data "archive_file" "aws-scheduler" {
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/aws-scheduler.zip"
}

# AWS Lambda function
resource "aws_lambda_function" "scheduler_lambda" {
  count            = var.create ? 1 : 0
  filename         = data.archive_file.aws-scheduler.output_path
  function_name    = var.lambda_function_prefix == null ? format("%saws-scheduler", var.resource_name_prefix) : format("%s%saws-scheduler", var.lambda_function_prefix, var.resource_name_prefix)
  role             = aws_iam_role.scheduler_lambda[0].arn
  handler          = "aws-scheduler.handler"
  runtime          = "python3.7"
  timeout          = 300
  source_code_hash = data.archive_file.aws-scheduler.output_base64sha256
  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }
  environment {
    variables = {
      TAG                = var.tag
      SCHEDULE_TAG_FORCE = var.schedule_tag_force ? "true" : "false"
      EXCLUDE            = var.exclude
      DEFAULT            = var.default
      TIME               = var.time
      RDS_SCHEDULE       = var.rds_schedule ? "true" : "false"
      EC2_SCHEDULE       = var.ec2_schedule ? "true" : "false"
    }
  }
}

resource "aws_cloudwatch_log_group" "scheduler_lambda" {
  count             = var.create ? 1 : 0
  name              = format("/aws/lambda/%s", local.lambda_function_name)
  retention_in_days = var.cloudwatch_loggroup_retention
  kms_key_id        = var.cloudwatch_loggroup_kms_key_arn != null ? var.cloudwatch_loggroup_kms_key_arn : null
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_scheduler" {
  count         = var.create ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check-scheduler-event[0].arn
}
