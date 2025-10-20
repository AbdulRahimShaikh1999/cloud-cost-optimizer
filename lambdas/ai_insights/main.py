import boto3, json, os, datetime

s3 = boto3.client("s3")
sns = boto3.client("sns")

S3_BUCKET = os.environ.get("S3_BUCKET")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
ENV = os.environ.get("ENV", "staging")

def lambda_handler(event, context):
    timestamp = datetime.datetime.utcnow().isoformat()
    summary = {
        "env": ENV,
        "timestamp": timestamp,
        "summary_text": f"[Placeholder] AI summary for {ENV} generated at {timestamp}"
    }

    s3.put_object(
        Bucket=S3_BUCKET,
        Key=f"{ENV}/ai_summaries/summary_{timestamp}.json",
        Body=json.dumps(summary, indent=2)
    )

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=summary["summary_text"],
        Subject=f"AI Summary ({ENV})"
    )

    return {"status": "mock summary published"}
