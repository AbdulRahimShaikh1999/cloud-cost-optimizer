# MOCKED SCRIPT import boto3, json, os, datetime

# s3 = boto3.client("s3")
# sns = boto3.client("sns")

# S3_BUCKET = os.environ.get("S3_BUCKET")
# SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
# ENV = os.environ.get("ENV", "staging")
# MODEL_ID = os.environ.get("MODEL_ID", "amazon.titan-text-lite-v1")
# SUMMARY_TOP_N = int(os.environ.get("SUMMARY_TOP_N", "10"))
# SUMMARY_RECENCY_WINDOW = int(os.environ.get("SUMMARY_RECENCY_WINDOW", "7"))

# def lambda_handler(event, context):
#     timestamp = datetime.datetime.utcnow().isoformat()
#     summary = {
#         "env": ENV,
#         "timestamp": timestamp,
#         "summary_text": f"[Placeholder] AI summary for {ENV} generated at {timestamp}"
#     }

#     s3.put_object(
#         Bucket=S3_BUCKET,
#         Key=f"{ENV}/ai_summaries/summary_{timestamp}.json",
#         Body=json.dumps(summary, indent=2)
#     )

#     sns.publish(
#         TopicArn=SNS_TOPIC_ARN,
#         Message=summary["summary_text"],
#         Subject=f"AI Summary ({ENV})"
#     )

#     return {"status": "mock summary published"}



# ACTUAL SCRIPT:

import boto3, json, os, datetime

s3 = boto3.client("s3")
sns = boto3.client("sns")
bedrock = boto3.client("bedrock-runtime")

S3_BUCKET = os.environ.get("S3_BUCKET")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
ENV = os.environ.get("ENV", "staging")
MODEL_ID = os.environ.get("MODEL_ID", "amazon.titan-text-lite-v1")
SUMMARY_TOP_N = int(os.environ.get("SUMMARY_TOP_N", "10"))
SUMMARY_RECENCY_WINDOW = int(os.environ.get("SUMMARY_RECENCY_WINDOW", "7"))

def lambda_handler(event, context):
    timestamp = datetime.datetime.utcnow().isoformat()

    # Get latest reports from S3
    prefix = f"{ENV}/reports/"
    objects = s3.list_objects_v2(Bucket=S3_BUCKET, Prefix=prefix)
    if "Contents" not in objects:
        return {"status": "no reports found"}

    recent_keys = sorted([o["Key"] for o in objects["Contents"]])[-SUMMARY_TOP_N:]
    summaries = []
    for key in recent_keys:
        obj = s3.get_object(Bucket=S3_BUCKET, Key=key)
        summaries.append(obj["Body"].read().decode("utf-8"))

    # Build prompt
    prompt = (
        "You are a cloud cost optimization assistant.\n"
        "Summarize these recent scan results for executives.\n"
        "Focus on key idle resources, cost savings, and recommended next actions.\n\n"
        f"{summaries}\n"
        "Write the response in under 250 words, bullet-first."
    )

    # Call Bedrock model
    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        contentType="application/json",
        accept="application/json",
        body=json.dumps({"inputText": prompt})
    )

    result = json.loads(response["body"].read())
    summary_text = result.get("results", [{}])[0].get("outputText", "[No summary returned]")

    # Store to S3
    key = f"{ENV}/ai_summaries/summary_{timestamp}.json"
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=key,
        Body=json.dumps({"summary": summary_text}, indent=2)
    )

    # Publish to SNS
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=summary_text,
        Subject=f"AI Summary ({ENV})"
    )

    return {"status": "summary generated", "key": key}
