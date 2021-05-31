set -e

export AWS_PAGER=""

echo "Generating deployment package..."
zip package.zip server.py > /dev/null

echo "Updating function 'watch-info-v2-create'..."
aws lambda update-function-code \
    --function-name watch-info-v2-create \
    --zip-file fileb://package.zip \
    > /dev/null

echo "Updating function 'watch-info-v2-read'..."
aws lambda update-function-code \
    --function-name watch-info-v2-read \
    --zip-file fileb://package.zip \
    > /dev/null

rm package.zip

echo "Success!"
