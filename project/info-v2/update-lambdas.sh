set -e
source ./util/vars.sh

export AWS_PAGER=""

echo "Generating deployment package..."
zip package.zip server.py > /dev/null

echo "Updating function '$INFO_V2_FUN_CREATE'..."

# update code
aws lambda update-function-code \
    --function-name "$INFO_V2_FUN_CREATE" \
    --zip-file fileb://package.zip \
    > /dev/null

# update environment variables
aws lambda update-function-configuration \
    --function-name "$INFO_V2_FUN_CREATE" \
    --environment "Variables={TABLE_NAME=$INFO_V2_TABLE_NAME}" \
    > /dev/null

echo "Updating function '$INFO_V2_FUN_READ'..."

# update code
aws lambda update-function-code \
    --function-name "$INFO_V2_FUN_READ" \
    --zip-file fileb://package.zip \
    > /dev/null

# update environment variables
aws lambda update-function-configuration \
    --function-name "$INFO_V2_FUN_READ" \
    --environment "Variables={TABLE_NAME=$INFO_V2_TABLE_NAME}" \
    > /dev/null

rm package.zip

echo "Success!"
