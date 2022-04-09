account_id = "111111111111"
region     = "ap-southeast-1"

bucket_name = "nopnithi-aws-backup-reports"

report_name      = "backup_jobs_report"
report_retention = 1

function_name          = "nopnithi-aws-backup-notification"
function_file          = "../lambda/lambda_code.zip"
function_log_retention = 14

topic_name = "nopnithi-aws-backup-notification"
subscription_emails = [
  "user1@nopnithi.demo",
  "user2@nopnithi.demo",
  "user3@nopnithi.demo"
]
