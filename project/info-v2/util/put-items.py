#!/usr/bin/env python3

import json
import sys

import boto3

if len(sys.argv) < 3:
    print("usage: put-items.py <file> <table>")
    exit(1)

file_name = sys.argv[1]
table_name = sys.argv[2]

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(table_name)

with table.batch_writer() as batch:
    with open(file_name) as file:
        items = json.load(file)
        count = 0
        for item in items:
            count += 1
            print(count, "/", len(items), end="\r")
            batch.put_item(item)

print()
