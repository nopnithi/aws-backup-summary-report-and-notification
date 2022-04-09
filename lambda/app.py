import os
import csv
import json
import urllib.parse
import boto3


s3 = boto3.client('s3')


def lambda_handler(event, context):
    region = event['Records'][0]['awsRegion']
    bucket = event['Records'][0]['s3']['bucket']['name']
    object_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'],encoding='utf-8')
    report_url = f'https://s3.console.aws.amazon.com/s3/object/{bucket}?region={region}&prefix={object_key}'
    try:
        response = s3.get_object(Bucket=bucket, Key=object_key)
        content = response['Body'].read().decode('utf-8').splitlines(True)
        jobs = get_jobs(content)
        message = summarize(jobs, report_url)
        send_email(
            subject='AWS Backup Notification',
            message=message
        )
    except Exception as e:
        print(e)
        print(f'Error getting object {object_key} from bucket {bucket}.')
        raise e


def get_jobs(content):
    jobs = {}
    reader = csv.reader(content, delimiter=',')
    line_count = 0
    for row in reader:
        line_count += 1
        if line_count > 1:
            job = {
                "job_id": row[4],
                "status": row[5],
                "message": row[6],
                "resource_type": row[7],
                "resource": get_resource_name(row[8])
            }
            if job['resource_type'] not in jobs:
                jobs[job['resource_type']] = {
                    "aborted": 0,
                    "acceptable_failed": 0,
                    "completed": 0,
                    "failed": 0,
                    "expired": 0,
                    "running": 0,
                    "pending": 0
                }
            jobs[job['resource_type']][job_classifier(job)] += 1
    return jobs


def get_resource_name(resource_arn):
    return resource_arn.split(':')[-1]


def job_classifier(job):
    exclude_messages = [
        'Cannot start backup job, RDS DB Instance is currently not in AVAILABLE state.'
    ]
    if job['status'] != 'FAILED':
        return job['status'].lower()
    else:
        for message in exclude_messages:
            if message in job['message']:
                return "acceptable_failed"
        return "failed"


def summarize(jobs, report_url):
    total = 0
    message = ''
    for data in jobs.values():
        total += data['failed']
    message += f'Total Failed Job: {total}\n\n'
    message += json.dumps(jobs, indent=4, sort_keys=True)
    message += f'\n\nSee the report file from S3:\n{report_url}'
    return message


def send_email(subject, message):
    sns = boto3.client('sns')
    response = sns.publish(
        TargetArn = os.environ.get('SNS_TOPIC_ARN'),
        Subject = subject,
        Message = json.dumps({'default': message}),
        MessageStructure = 'json'
    )
    return {
        'statusCode': 200,
        'body': json.dumps(response)
    }
