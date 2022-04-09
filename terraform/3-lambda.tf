resource "aws_iam_role" "backup_notification" {
  name = "LambdaBackupNotificationExecutionRole"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

# Allow Lambda to read S3, send message to SNS and put logs to CloudWatch
resource "aws_iam_role_policy" "backup_notification" {
  name = "LambdaBackupNotificationExecutionPolicy"
  role = aws_iam_role.backup_notification.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowReadS3",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "${aws_s3_bucket.backup_notification.arn}/*"
        },
        {
            "Sid": "AllowPublishToSNS",
            "Effect": "Allow",
            "Action": "sns:Publish",
            "Resource": "${aws_sns_topic.backup_notification.arn}"
        },
        {
            "Sid": "AllowCreateAndPutCloudWatchLogs",
            "Effect": "Allow",
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF
}

# Compress Python code (app.py) into zip file
data "archive_file" "lambda_code" {
  type        = "zip"
  source_file = "../lambda/app.py"
  output_path = "../lambda/lambda_code.zip"
}

# Create a Lambda function with Python code
resource "aws_lambda_function" "backup_notification" {
  filename         = var.function_file
  source_code_hash = data.archive_file.lambda_code.output_base64sha256
  function_name    = var.function_name
  role             = aws_iam_role.backup_notification.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.9"

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.backup_notification.arn
    }
  }
}

# Allows S3 to trigger Lambda
resource "aws_lambda_permission" "backup_notification" {
  statement_id   = "AllowTriggerFromS3"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.backup_notification.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.backup_notification.arn
  source_account = var.account_id
}

# Store Lambda logs
resource "aws_cloudwatch_log_group" "backup_notification" {
  name              = "/aws/lambda/${aws_lambda_function.backup_notification.function_name}"
  retention_in_days = var.function_log_retention
}
