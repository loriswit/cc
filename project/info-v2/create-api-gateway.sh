set -e
source ./util/vars.sh

# check if role already exists
if aws iam list-roles | jq -e ".Roles[]|select(.RoleName==\"$INFO_V2_API_ROLE\")" > /dev/null; then
    echo "Role '$INFO_V2_API_ROLE' already exists. Fetching existing role...."
    ROLE_JSON=$(aws iam get-role --role-name "$INFO_V2_API_ROLE")
else
    echo "Creating new role '$INFO_V2_API_ROLE'..."
    ROLE_JSON=$(aws iam create-role \
        --role-name "$INFO_V2_API_ROLE" \
        --assume-role-policy-document file://util/api-role-policy.json)

    # wait for role to be created
    aws iam wait role-exists --role-name "$INFO_V2_API_ROLE" > /dev/null
fi

# extract role ARN
ROLE_ARN=$(echo "$ROLE_JSON" | jq -r .Role.Arn)

echo "Attaching role policies to '$INFO_V2_API_ROLE'..."

# allow API to call Lambda functions
aws iam attach-role-policy \
    --role-name "$INFO_V2_API_ROLE" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaRole

# wait some time for the role to be up to date
sleep 10

echo "Creating new API from 'info-v2-openapi.yaml'..."
API_JSON=$(aws apigateway import-rest-api \
    --body file://util/info-v2-openapi.yaml \
    --cli-binary-format raw-in-base64-out)

# extract API ID
API_ID=$(echo "$API_JSON" | jq -r .id)

echo "Fetching resources from API '$API_ID'..."
RESOURCES=$(aws apigateway get-resources --rest-api-id "$API_ID")
CREATE_ID=$(echo "$RESOURCES" | jq -r ".items[] | select(.resourceMethods.POST).id")
READ_ID=$(echo "$RESOURCES" | jq -r ".items[] | select(.resourceMethods.GET).id")

echo "Fetching Lambda functions..."
CREATE_ARN=$(aws lambda get-function --function-name "$INFO_V2_FUN_CREATE" | jq -r .Configuration.FunctionArn)
READ_ARN=$(aws lambda get-function --function-name "$INFO_V2_FUN_READ" | jq -r .Configuration.FunctionArn)

echo "Setting up methods integrations..."
REGION=$(aws configure get region)
CREATE_URI="arn:aws:apigateway:$REGION:lambda:path//2015-03-31/functions/$CREATE_ARN/invocations"
READ_URI="arn:aws:apigateway:$REGION:lambda:path//2015-03-31/functions/$READ_ARN/invocations"

aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$CREATE_ID" \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "$CREATE_URI" \
    --credentials "$ROLE_ARN" \
    > /dev/null

aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$READ_ID" \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "$READ_URI" \
    --credentials "$ROLE_ARN" \
    > /dev/null

echo "Deploying API..."
aws apigateway create-deployment --rest-api-id "$API_ID" --stage-name "$INFO_V2_API_STAGE" > /dev/null

echo "Success! API available at https://$API_ID.execute-api.$REGION.amazonaws.com/$INFO_V2_API_STAGE"
