set -e

export AWS_PAGER=""

# default table name: 'watches'
TABLE_NAME="${TABLE_NAME:-watches}"

# check if table already exists
if aws dynamodb list-tables | grep -q "$TABLE_NAME"; then
    echo "Table '$TABLE_NAME' already exists. Skipping table creation."
else
    echo "Creating new table '$TABLE_NAME'..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=sku,AttributeType=S \
        --key-schema AttributeName=sku,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        > /dev/null

    # wait for table to be created
    aws dynamodb wait table-exists --table-name "$TABLE_NAME" > /dev/null
fi

# fill table with items from watches.json
echo "Importing items from 'watches.json' into table '$TABLE_NAME'"
python put-items.py watches.json "$TABLE_NAME"
echo Success!
