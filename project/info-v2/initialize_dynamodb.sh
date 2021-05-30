set -e

export AWS_PAGER=""

# default table name: 'watches'
TABLE_NAME="${TABLE_NAME:-watches}"

# check if table already exists
TABLE_EXISTS=$(aws dynamodb list-tables | grep -c "$TABLE_NAME" | cat )
if (( TABLE_EXISTS )); then
    echo "Table '$TABLE_NAME' already exists. Skipping table creation."
else
    echo "Creating new table '$TABLE_NAME'..."
    aws dynamodb create-table \
        --table-name watches \
        --attribute-definitions AttributeName=sku,AttributeType=S \
        --key-schema AttributeName=sku,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        > /dev/null
fi

# fill table with items from watches.json
echo "Importing items from 'watches.json' into table '$TABLE_NAME'"
python put-items.py watches.json "$TABLE_NAME"
echo Success!
