import os
import json
import logging
from datetime import datetime, timedelta, timezone
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, generate_blob_sas, BlobSasPermissions

source_account_name = os.getenv("SOURCE_STORAGE_ACCOUNT_NAME")
source_blob_service_client = BlobServiceClient(  
    account_url=f'https://{source_account_name}.blob.core.windows.net/',
    credential=DefaultAzureCredential()
)

target_account_name = os.getenv("TARGET_STORAGE_ACCOUNT_NAME")
target_blob_service_client = BlobServiceClient(
    account_url=f'https://{target_account_name}.blob.core.windows.net/',
    credential=DefaultAzureCredential()
)

app = func.FunctionApp()

@app.function_name(name='blob_sharing')
@app.event_grid_trigger(arg_name='event')
def main(event: func.EventGridEvent):
    result = json.dumps({
        'id': event.id,
        'data': event.get_json(),
        'topic': event.topic,
        'subject': event.subject,
        'event_type': event.event_type,
    })

    logging.info(f'Python EventGrid trigger processed an event: {result}')

    current_time = datetime.now(timezone.utc)

    blob_name = event.subject.split("/blobs/")[1]

    user_delegation_key = source_blob_service_client.get_user_delegation_key(  
        key_start_time=current_time,
        key_expiry_time=current_time + timedelta(hours=1)
    )

    sas_token = generate_blob_sas(
        account_name=source_account_name,
        container_name='source',
        blob_name=blob_name,
        user_delegation_key=user_delegation_key,
        permission=BlobSasPermissions(read=True),
        expiry=current_time + timedelta(hours=1)
    )

    target_blob_client = target_blob_service_client.get_blob_client(container='target', blob=blob_name)

    target_blob_client.start_copy_from_url(
        source_url = event.get_json()['url']+ "?" + sas_token,
        requires_sync=False
    )