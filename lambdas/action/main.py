import boto3, json, os, datetime

dynamodb = boto3.resource("dynamodb")
ec2 = boto3.client("ec2")
s3 = boto3.client("s3")

DDB_TABLE = os.environ.get("DDB_TABLE")
S3_BUCKET = os.environ.get("S3_BUCKET")
ENV = os.environ.get("ENV", "staging")

def lambda_handler(event, context):
    table = dynamodb.Table(DDB_TABLE)
    timestamp = datetime.datetime.utcnow().isoformat()

    # Fetch idle resources from DynamoDB (latest)
    response = table.scan()
    idle = [item for item in response["Items"] if item.get("type") == "EC2"]

    actions = []
    for r in idle:
        rid = r["resource_id"]
        ec2.stop_instances(InstanceIds=[rid])
        ec2.create_tags(Resources=[rid], Tags=[{"Key": "CostOpt", "Value": "Stopped"}])
        actions.append({"resource_id": rid, "action": "stopped"})

    report = {"env": ENV, "timestamp": timestamp, "actions": actions}
    s3.put_object(Bucket=S3_BUCKET, Key=f"{ENV}/reports/actions_{timestamp}.json",
                  Body=json.dumps(report, indent=2))

    return {"status": "done", "actions": len(actions)}
