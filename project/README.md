# Cloud Computing Project

By [Boris Mottet](https://gitlab.com/Risbobo) and [Loris Witschard](https://gitlab.com/loriswit)

## Table of content

- [info-v1 & image-v1](#info-v1---image-v1)
  * [Prerequisite](#prerequisite)
  * [Building images](#building-images)
  * [Deploying to GKE](#deploying-to-gke)
- [info-v2](#info-v2)
  * [Prerequisite](#prerequisite-1)
  * [Environment variables](#environment-variables)
  * [Setup](#setup)
  * [Development](#development)

## info-v1 & image-v1

### Prerequisite

The following CLI tools are required to set up this part of the project:
- `gcloud`: manage GCP services
- `docker`: build and push container images
- `kubectl`: deploy to Kubernetes cluster
- `mysql`: (optional) import watches into database

### Building images

The images names can be defined in the following environment variables. These will also be used during the deployment, so make sure you are allowed to push these images to Docker Hub.

| Variable | Description | Default |
| --- | --- | --- |
| `INFO_V1_IMAGE` | the image name of info-v1 | loriswit/watches-info-v1 |
| `IMAGE_V1_IMAGE` | the image name of image-v1 | loriswit/watches-image-v1 |

Run the following command to build the images:
```sh
./build.sh
```

### Deploying to GKE

To deploy the services to Google Kubernetes Engine (GKE), start by defining the following environment variables. These don't have default values, so you cannot omit any of them.

| Variable | Description |
| --- | --- |
| `INFO_V1_HTTP_USER` | the basic-auth username |
| `INFO_V1_HTTP_PASS` | the basic-auth password |
| `INFO_V1_DB_HOST` | the database hostname |
| `INFO_V1_DB_PORT` | the database port |
| `INFO_V1_DB_DBNAME` | the database name |
| `INFO_V1_DB_USER` | the database user |
| `INFO_V1_DB_PASS` | the database user |

Make sure you have an existing MySQL database (e.g., Cloud SQL) that matches the values from these variables. You can import data from *info/watches.sql* into the database by running:
```sh
mysql -h $INFO_V1_DB_HOST -u $INFO_V1_DB_USER -p $INFO_V1_DB_DBNAME < info/watches.sql
```

Log in to your Docker Hub and Google Cloud accounts:
```sh
docker login
gcloud auth login
```

Create a GKE cluster and connect the gcloud CLI:
```sh
gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-name>
```

Deploy the services to GKE by running:
```sh
./deploy.sh
```

**Note**: when you make change to the code or to the GKE configuration, simply run `./deploy.sh` again to deploy the changes to GKE.

#### Important note

If the *info-v1* service gets disconnected from the database for some reason, it cannot connect to it again. To fix this, simply restart the deployment:
```sh
kubectl rollout restart deployment/info-v1
```

## info-v2

### Prerequisite

The following CLI tools are required to set up this part of the project:
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
