import decimal
import http
import json
import numbers

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("watches")


# POST /watch: add a new watch to the store
def create(event, context):
    # parse JSON from body
    try:
        body = json.loads(event["body"])
    except Exception as e:
        return {
            "statusCode": http.HTTPStatus.BAD_REQUEST,
            "body": json.dumps({"error": "malformed request: " + str(e)})
        }

    # check required fields
    required = ["sku", "type", "status", "gender", "year"]
    missing = set(required) - set(body.keys())
    if missing:
        return {
            "statusCode": http.HTTPStatus.BAD_REQUEST,
            "body": json.dumps({"error": "missing required fields", "missing": list(missing)})
        }

    # only keep the following fields
    allowed_fields = ["bracelet_material", "case_form", "case_material", "dial_color",
                      "dial_material", "gender", "movement", "sku", "status", "type", "year"]

    filtered = {k: v for k, v in body.items() if k in allowed_fields}

    # check types
    for k, v in filtered.items():
        t = numbers.Number if k == "year" else str
        if not isinstance(v, t):
            return {
                "statusCode": http.HTTPStatus.BAD_REQUEST,
                "body": json.dumps({"error": f"field '{k}' must be of type {t.__name__}"})
            }

    # check enum values
    allowed_values = {
        "type": ["watch", "chrono"],
        "status": ["old", "current", "outlet"],
        "gender": ["man", "woman"]
    }
    for k, v in allowed_values.items():
        if k in filtered.keys() and filtered[k] not in allowed_values[k]:
            return {
                "statusCode": http.HTTPStatus.BAD_REQUEST,
                "body": json.dumps({
                    "error": f"field '{k}' must be one of the enumerated values",
                    "enum": allowed_values[k]
                })
            }

    # insert item into database
    table.put_item(Item=filtered)
    return {"statusCode": http.HTTPStatus.OK}


# GET /watch/{sku}: return watch data
def read(event, context):
    response = table.get_item(Key={"sku": event["pathParameters"]["sku"]})
    if "Item" not in response:
        return {"statusCode": http.HTTPStatus.NOT_FOUND}

    # convert decimals to ints to prevent JSON serialization errors
    watch = {k: int(v) if isinstance(v, decimal.Decimal) else v for k, v in response["Item"].items()}
    return {
        "body": json.dumps(watch),
        "statusCode": http.HTTPStatus.OK
    }
