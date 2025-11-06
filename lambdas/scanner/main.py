import boto3, json, datetime, os
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")
ec2 = boto3.client("ec2")
cloudwatch = boto3.client("cloudwatch")
NAMESPACE = os.environ.get("METRICS_NAMESPACE", "CloudCostOptimizer")

DDB_TABLE = os.environ.get("DDB_TABLE")
S3_BUCKET = os.environ.get("S3_BUCKET")
ENV = os.environ.get("ENV", "staging")

def get_idle_instances():
    instances = ec2.describe_instances(
        Filters=[{"Name": "instance-state-name", "Values": ["running"]}]
    )
    idle = []
    for reservation in instances["Reservations"]:
        for instance in reservation["Instances"]:
            instance_id = instance["InstanceId"]
            metric = cloudwatch.get_metric_statistics(
                Namespace="AWS/EC2",
                MetricName="CPUUtilization",
                Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
                StartTime=datetime.datetime.utcnow() - datetime.timedelta(days=7),
                EndTime=datetime.datetime.utcnow(),
                Period=86400,
                Statistics=["Average"]
            )
            avg = sum(p["Average"] for p in metric["Datapoints"]) / len(metric["Datapoints"]) if metric["Datapoints"] else 0
            if avg < 5:
                idle.append({"resource_id": instance_id, "type": "EC2", "cpu": Decimal(str(avg))})
    return idle

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    table = dynamodb.Table(DDB_TABLE)
    timestamp = datetime.datetime.utcnow().isoformat()
    idle_resources = get_idle_instances()
    report = {
        "env": ENV,
        "timestamp": timestamp,
        "idle_resources": idle_resources,
    }

    # Publish custom metric: number of idle EC2 instances detected this run
    idle_ec2_count = sum(1 for r in idle_resources if r.get("type") == "EC2")
    cloudwatch.put_metric_data(
    Namespace=NAMESPACE,
    MetricData=[
        {
            "MetricName": "IdleEC2Count",
            "Dimensions": [
                {"Name": "Environment", "Value": ENV}
            ],
            "Timestamp": datetime.datetime.utcnow(),
            "Value": idle_ec2_count,
            "Unit": "Count"
        }
      ]  
   )


    # Publish custom metric: number of idle EC2 instances detected this run



    # Save to DynamoDB
    for item in idle_resources:
        item.update({"timestamp": timestamp, "env": ENV})
        table.put_item(Item=item)

    # Save to S3
    key = f"{ENV}/reports/scan_{timestamp}.json"
    s3.put_object(Bucket=S3_BUCKET, Key=key, Body=json.dumps(report, indent=2, cls=DecimalEncoder))

    

    return {"status": "success", "count": len(idle_resources)}
