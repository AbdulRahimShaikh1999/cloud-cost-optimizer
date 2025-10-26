# from moto import mock_aws
# from main import lambda_handler

# @mock_aws
# def test():
#     # Create fake SNS topic and S3 bucket in mocked AWS
#     import boto3
#     sns = boto3.client("sns", region_name="us-east-1")
#     s3 = boto3.client("s3", region_name="us-east-1")
#     topic = sns.create_topic(Name="ai-summaries-staging")
#     s3.create_bucket(Bucket="levelup-reports-staging")

#     import os
#     os.environ["SNS_TOPIC_ARN"] = topic["TopicArn"]
#     os.environ["S3_BUCKET"] = "levelup-reports-staging"
#     os.environ["ENV"] = "staging"

#     print(lambda_handler({}, {}))

# test()

from unittest.mock import MagicMock
bedrock = MagicMock()
bedrock.invoke_model.return_value = {
    "body": MagicMock(read=lambda: json.dumps({"results": [{"outputText": "Mock summary"}]}).encode())
}
