set -e
source ./util/vars.sh

# check if table already exists
if aws dynamodb list-tables | jq -e ".TableNames[]|select(.==\"$INFO_V2_TABLE_NAME\")" > /dev/null; then
    echo "Table '$INFO_V2_TABLE_NAME' already exists. Skipping table creation."
else
    echo "Creating new table '$INFO_V2_TABLE_NAME'..."
    aws dynamodb create-table \
        --table-name "$INFO_V2_TABLE_NAME" \
        --attribute-definitions AttributeName=sku,AttributeType=S \
        --key-schema AttributeName=sku,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        > /dev/null

    # wait for table to be created
    aws dynamodb wait table-exists --table-name "$INFO_V2_TABLE_NAME" > /dev/null
fi

# fill table with items from watches.json
echo "Importing items from 'watches.json' into table '$INFO_V2_TABLE_NAME'"
python3 ./util/put-items.py ./util/watches.json "$INFO_V2_TABLE_NAME"
echo Success!
