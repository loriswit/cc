# Cloud Computing Project

By [Boris Mottet](https://gitlab.com/Risbobo) and [Loris Witschard](https://gitlab.com/loriswit)

## info-v1 & image-v1

Start by building the images:
```sh
./build.sh
```

Then, connect `kubectl` to any cluster and deploy the services:
```sh
./deploy.sh
```

**Note**: this requires authorisation to push to the appropriate DockerHub repositories.

### Database access

Right now, the database address and credentials are hard-coded in `all.yml`. The default values refer to a Cloud SQL database that is available from everywhere. To connect to a different database, you have to manually edit lines 38-51.

This will be improved in a further version to allow easier (and more secure) configuration with environment variables.

## info-v2

### Prerequisite

The following CLI tools are required to set up the project:
- `aws`: manage AWS services (version 2)
- `python3`: run Python scripts
- `zip`: create Lambda deployment packages
- `jq`: parse JSON output from AWS CLI

### Environment variables

The following environment variables can be optionally defined.

| Variable | Description | Default |
| --- | --- | --- |
| `INFO_V2_TABLE_NAME` | the DynamoDB table name | watch-info-v2-watches |
| `INFO_V2_FUN_ROLE` | the IAM role name for the Lambda functions | watch-info-v2-fun-role |
| `INFO_V2_FUN_CREATE` | the Lambda function for the POST request | watch-info-v2-create |
| `INFO_V2_FUN_READ` | the Lambda function for the GET request | watch-info-v2-read |
| `INFO_V2_API_ROLE` | the IAM role name for the API Gateway | watch-info-v2-api-role |
| `INFO_V2_API_STAGE` | the API Gateway deployment stage name | v2 |

### Setup

Start by navigating to the *info-v2* directory and configure the AWS CLI (credentials and region):
```sh
cd info-v2
aws configure
```

Create a new DynamoDB table and import the items from *util/watches.json* by running:
```sh
pip install -r requirements.txt
./initialize-dynamodb.sh
```

Create both Lambda functions and upload the source code by running:
```sh
./create-lambdas.sh
```

Create the API Gateway, set up the methods integrations and deploy the API by running:
```sh
./create-api-gateway.sh
```

The base URL of the deployed API will be printed in the terminal output. Note that the endpoints might not be available for a **few minutes** until the **role policies are up to date**. Sending a request to an endpoint too early will return a **500 error**.

Once the API is deployed and everything is up to date, you can insert and fetch watches:
```sh
# insert a new watch
curl -X POST http://host/stage/watch \
    -d '{"sku":"1234","type":"watch","status":"current","gender":"woman","year": 2010}'

# fetch the new watch
curl -X GET http://host/stage/watch/1234
```

Note that navigating to a path of the API that does not match an existing endpoint will return a **403 error**.

#### Important note

It is possible that the `create-lambdas.sh` and `create-api-gateway.sh` scripts may fail to complete and print an error. This can happen when role policies take too long to become up to date. If this happens, simply run the same script again after a short time.

### Development

The code of the Lambda functions is defined in *server.py*. When you make change to the source code and the functions have already been created with *create-lambda.sh*, you can use *update-lambda.sh*:
```sh
# make changes
vim server.py

# deploy code
./update-lambdas.sh
```

If you want the functions to read from another DynamoDB table than the one specified originally, you can update the `INFO_V2_TABLE_NAME` variable and run *update-lambda.sh*:
```sh
# change table name
export INFO_V2_TABLE_NAME=my-new-table

# update environment variables
./update-lambdas.sh
```
