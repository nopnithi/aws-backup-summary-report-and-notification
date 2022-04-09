# Create a backup report plan
resource "aws_backup_report_plan" "backup_notification" {
  name = var.report_name

  report_delivery_channel {
    formats        = ["CSV"]
    s3_bucket_name = aws_s3_bucket.backup_notification.id
  }

  report_setting {
    report_template = "BACKUP_JOB_REPORT"
  }
}
