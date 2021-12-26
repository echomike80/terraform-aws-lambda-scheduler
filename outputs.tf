output "scheduler_lambda_arn" {
  value = concat(aws_lambda_function.scheduler_lambda.*.arn, [""])[0]
}

output "scheduler_lambda_function_name" {
  value = concat(aws_lambda_function.scheduler_lambda.*.function_name, [""])[0]
}
