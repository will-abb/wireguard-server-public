import boto3
import json

ec2 = boto3.client("ec2")
instance_name = "personal-wireguard-server"
"""test with
{
  "httpMethod": "GET",
  "queryStringParameters": {}
}
"""


def lambda_handler(event, context):
    try:
        action = event["httpMethod"]

        instance_id = get_instance_id_by_name(instance_name)
        if not instance_id:
            return {
                "statusCode": 404,
                "body": json.dumps(
                    {"message": f"No instance found with name {instance_name}"}
                ),
            }

        if action == "GET":
            return get_instance_status(instance_id)
        elif action == "POST":
            return start_instance(instance_id)
        elif action == "PUT":
            return stop_instance(instance_id)
        elif action == "DELETE":
            return terminate_instance(instance_id)
        else:
            return {
                "statusCode": 400,
                "body": json.dumps({"message": "Unsupported HTTP method"}),
            }
    except KeyError as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"message": f"KeyError: {str(e)}"}),
        }


def get_instance_id_by_name(instance_name):
    response = ec2.describe_instances(
        Filters=[{"Name": "tag:Name", "Values": [instance_name]}]
    )
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            return instance["InstanceId"]
    return None


def get_instance_status(instance_id):
    response = ec2.describe_instance_status(InstanceIds=[instance_id])
    if not response["InstanceStatuses"]:
        status = "stopped"
    else:
        status = response["InstanceStatuses"][0]["InstanceState"]["Name"]
    return {
        "statusCode": 200,
        "body": json.dumps({"instance_id": instance_id, "status": status}),
    }


def start_instance(instance_id):
    ec2.start_instances(InstanceIds=[instance_id])
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Instance started", "instance_id": instance_id}),
    }


def stop_instance(instance_id):
    ec2.stop_instances(InstanceIds=[instance_id])
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Instance stopped", "instance_id": instance_id}),
    }


def terminate_instance(instance_id):
    ec2.terminate_instances(InstanceIds=[instance_id])
    return {
        "statusCode": 200,
        "body": json.dumps(
            {"message": "Instance terminated", "instance_id": instance_id}
        ),
    }
