terraform {
  cloud {
    organization = "sanam-default-org"
    workspaces {
      name = "roster-telegram"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.63.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5.0"
    }
  }

  required_version = "~> 1.10.2"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Name  = local.service_name
      Stage = var.stage_name
    }
  }
}

locals {
  service_name = "roster-telegram"
  binary_name  = "bootstrap" # for runtime "provided.al2023" binary name must be "bootstrap"
  binary_path  = "${path.module}/${local.binary_name}"
  archive_path = "${path.module}/${local.service_name}.zip"
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "ap-southeast-2"
}

variable "stage_name" {
  description = "Deployment stage name."
  type        = string
  default     = "prod"
}

variable "my_chat_id" {
  description = "My Telegram chat ID."
  type        = number
}

variable "bot_api_token" {
  description = "Telegram bot api token."
  type        = string
}

data "archive_file" "function_archive" {
  type        = "zip"
  source_file = local.binary_path
  output_path = local.archive_path
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "partner-${local.service_name}-lambda-bucket"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.lambda_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "versioning-bucket-config" {
  bucket = aws_s3_bucket.lambda_bucket.id

  rule {
    status = "Enabled"
    id     = "delete_previous_versions"

    noncurrent_version_expiration {
      noncurrent_days = 5
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket_ownership_controls" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket_ownership_controls]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "${local.service_name}.zip"
  source = data.archive_file.function_archive.output_path
  etag   = filemd5(data.archive_file.function_archive.output_path)
}

resource "aws_lambda_function" "function" {
  function_name = local.service_name
  description   = "Roster Telegram Bot"
  role          = aws_iam_role.lambda_exec.arn
  handler       = local.binary_name

  memory_size = 128
  s3_bucket   = aws_s3_bucket.lambda_bucket.id
  s3_key      = aws_s3_object.lambda_zip.key

  source_code_hash = data.archive_file.function_archive.output_base64sha256

  timeout = 30
  runtime = "provided.al2023"
  environment {
    variables = {
      "BOT_API_TOKEN"          = var.bot_api_token,
      "MY_CHAT_ID"         = var.my_chat_id,
    }
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name        = "${local.service_name}-lambda-role"
  description = "Allow lambda to access AWS services or resources."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_event_rule" "everyday_send_roster" {
  name                = "${local.service_name}-everyday-send-roster"
  description         = "Trigger everyday at 8am Perth time."
  schedule_expression = "cron(0 23 ? * * *)" # 11pm UTC (7am AWST)
}

resource "aws_cloudwatch_event_target" "everyday_send_roster" {
  rule = aws_cloudwatch_event_rule.everyday_send_roster.name
  arn  = aws_lambda_function.function.arn

  depends_on = [
    aws_lambda_function.function
  ]
}

resource "aws_lambda_permission" "allow_event_rule" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.everyday_send_roster.arn
}





