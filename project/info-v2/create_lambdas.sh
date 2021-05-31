set -e

export AWS_PAGER=""

if [[ -z "${LAMBDA_ROLE}" ]]; then
  >&2 echo "Please define the environment variable LAMBDA_ROLE"
  exit 1
fi

echo "Generating deployment package..."
zip package.zip server.py > /dev/null

echo "Creating function 'watch-info-v2-create'..."
aws lambda create-function \
    --function-name watch-info-v2-create \
    --zip-file fileb://package.zip \
    --handler server.create \
    --runtime python3.8 \
    --role "$LAMBDA_ROLE" \
    > /dev/null

echo "Creating function 'watch-info-v2-read'..."
aws lambda create-function \
    --function-name watch-info-v2-read \
    --zip-file fileb://package.zip \
    --handler server.read \
    --runtime python3.8 \
    --role "$LAMBDA_ROLE" \
    > /dev/null

rm package.zip

echo "Success!"
