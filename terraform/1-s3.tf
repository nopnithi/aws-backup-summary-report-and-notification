locals {
  bucket_name = "${var.bucket_name}-${var.account_id}"
}

# Bucket for AWS Backup report
resource "aws_s3_bucket" "backup_notification" {
  bucket = local.bucket_name
}
resource "aws_s3_bucket_acl" "backup_notification" {
  bucket = aws_s3_bucket.backup_notification.id
  acl    = "private"
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "backup_notification" {
  bucket = aws_s3_bucket.backup_notification.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowWriteFromAWSBackupReportRole",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.account_id}:role/aws-service-role/reports.backup.amazonaws.com/AWSServiceRoleForBackupReports"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.backup_notification.arn}/*"
        },
        {
            "Sid": "AllowReadFromLambda",
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "${aws_s3_bucket.backup_notification.arn}/*"
        }
    ]
}
EOF
}

# S3 Event Notifications
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.backup_notification.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.backup_notification.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.backup_notification]
}

# Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "backup_notification" {
  bucket = aws_s3_bucket.backup_notification.id

  rule {
    id = "DeleteReportFiles"
    expiration {
      days = var.report_retention
    }

    filter {}

    status = "Enabled"
  }
}
