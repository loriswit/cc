set -e
source ./util/vars.sh

# check if role already exists
if aws iam list-roles | jq -e ".Roles[]|select(.RoleName==\"$INFO_V2_FUN_ROLE\")" > /dev/null; then
    echo "Role '$INFO_V2_FUN_ROLE' already exists. Fetching existing role...."
    ROLE_JSON=$(aws iam get-role --role-name "$INFO_V2_FUN_ROLE")
else
    echo "Creating new role '$INFO_V2_FUN_ROLE'..."
    ROLE_JSON=$(aws iam create-role \
        --role-name "$INFO_V2_FUN_ROLE" \
        --assume-role-policy-document file://util/fun-role-policy.json)

    # wait for role to be created
    aws iam wait role-exists --role-name "$INFO_V2_FUN_ROLE" > /dev/null
fi

# extract role ARN
ROLE_ARN=$(echo "$ROLE_JSON" | jq -r .Role.Arn)

echo "Attaching role policies to '$INFO_V2_FUN_ROLE'..."

# give full access to database
aws iam attach-role-policy \
    --role-name "$INFO_V2_FUN_ROLE" \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

# give access to CloudWatch Logs
aws iam attach-role-policy \
    --role-name "$INFO_V2_FUN_ROLE" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# wait some time for the role to be up to date
sleep 10

echo "Generating deployment package..."
zip package.zip server.py > /dev/null

echo "Creating function '$INFO_V2_FUN_CREATE'..."
aws lambda create-function \
    --function-name "$INFO_V2_FUN_CREATE" \
    --zip-file fileb://package.zip \
    --handler server.create \
    --runtime python3.8 \
    --role "$ROLE_ARN" \
    --environment "Variables={TABLE_NAME=$INFO_V2_TABLE_NAME}" \
    > /dev/null

echo "Creating function '$INFO_V2_FUN_READ'..."
aws lambda create-function \
    --function-name "$INFO_V2_FUN_READ" \
    --zip-file fileb://package.zip \
    --handler server.read \
    --runtime python3.8 \
    --role "$ROLE_ARN" \
    --environment "Variables={TABLE_NAME=$INFO_V2_TABLE_NAME}" \
    > /dev/null

rm package.zip

echo "Success!"
