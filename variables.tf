variable "create" {
  description = "Whether to create all resources"
  type        = bool
  default     = true
}

variable "schedule_expression" {
  default     = "cron(5 * * * ? *)"
  description = "the aws cloudwatch event rule scheule expression that specifies when the scheduler runs. Default is 5 minuts past the hour. for debugging use 'rate(5 minutes)'. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
}

variable "tag" {
  default     = "schedule"
  description = "the tag name used on the EC2 or RDS instance to contain the schedule json string for the instance."
}

variable "schedule_tag_force" {
  type        = bool
  default     = false
  description = "Whether to force the EC2 or RDS instance to have the default schedule tag is no schedule tag exists for the instance."
}

variable "permissions_boundary" {
  type 		  = string
  default 	  = ""
  description = "AWS IAM Permissions Boundary ARN to be attached to the IAM Role"
}

variable "exclude" {
  default     = ""
  description = "common separated list of EC2 and RDS instance ids to exclude from scheduling."
}

variable "default" {
  default     = "{\"mon\": {\"start\": 7, \"stop\": 20},\"tue\": {\"start\": 7, \"stop\": 20},\"wed\": {\"start\": 7, \"stop\": 20},\"thu\": {\"start\": 7, \"stop\": 20}, \"fri\": {\"start\": 7, \"stop\": 20}}"
  description = "the default schedule tag containing json schedule information to add to instance when schedule_tag_force set to true."
}

variable "time" {
  default     = "gmt"
  description = "timezone to use for scheduler. Can be 'local', 'gmt' or an Olson timezone from https://gist.github.com/ykessler/3349954. default is 'gmt'. local time is for the AWS region."
}

variable "ec2_schedule" {
  type        = bool
  default     = true
  description = "Whether to do scheduling for EC2 instances."
}

variable "rds_schedule" {
  type        = bool
  default     = true
  description = "Whether to do scheduling for RDS instances."
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "list of the vpc security groups to run lambda scheduler in."
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "list of subnet_ids that the scheduler runs in."
}

variable "resource_name_prefix" {
  type        = string
  default     = ""
  description = "a prefix to apply to resource names created by this module."
}

variable "cloudwatch_event_rule_prefix" {
  type        = string
  default     = null
  description = "a prefix to apply to cloudwatch event rule resources."
}

variable "cloudwatch_loggroup_kms_key_arn" {
  description = "KMS key id for encrypting the logging destination"
  type        = string
  default     = null
}

variable "cloudwatch_loggroup_retention" {
  type        = number
  default     = 14
  description = "number of days to keep the logs"
}

variable "iam_role_prefix" {
  type        = string
  default     = null
  description = "a prefix to apply to IAM role resources."
}

variable "iam_policy_prefix" {
  type        = string
  default     = null
  description = "a prefix to apply to IAM policy resources."
}

variable "lambda_function_prefix" {
  type        = string
  default     = null
  description = "a prefix to apply to lambda function resources."
}
