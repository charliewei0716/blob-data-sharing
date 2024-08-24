#!/bin/sh

echo "Loading azd .env file from current environment"

while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

if [ $? -ne 0 ]; then
    echo "Failed to load environment variables from azd environment"
    exit $?
fi

echo "Check Event Subscription status"

list_evensub=$(az eventgrid system-topic event-subscription list \
    --resource-group $RESOURCE_GROUP_NAME \
    --system-topic-name $SYSTEM_TOPIC_NAME \
    --odata-query "name eq 'StorageBlobCreated'")

if echo "$list_evensub" | jq -e 'length == 0' > /dev/null; then
    echo "Create Event Subscription"

    code=$(\
        az functionapp keys list \
            --resource-group $RESOURCE_GROUP_NAME \
            --name $FUNCTION_APP_NAME \
            --query "systemKeys.eventgrid_extension" \
            --output tsv\
    )

    az eventgrid system-topic event-subscription create \
        --name StorageBlobCreated \
        --resource-group $RESOURCE_GROUP_NAME \
        --system-topic-name $SYSTEM_TOPIC_NAME \
        --endpoint "https://$FUNCTION_APP_NAME.azurewebsites.net/runtime/webhooks/EventGrid?functionName=blob_sharing&code=$code" \
        --subject-begins-with "/blobServices/default/containers/source" \
        --included-event-types "Microsoft.Storage.BlobCreated"
fi