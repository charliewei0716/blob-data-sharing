import logging
import json
from datetime import datetime, timedelta, timezone
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, generate_blob_sas, BlobSasPermissions

source_blob_service_client = BlobServiceClient(  
    account_url="https://cmpadls.blob.core.windows.net/",  
    credential=DefaultAzureCredential()
)

destination_blob_service_client = BlobServiceClient.from_connection_string(
    ""
)

app = func.FunctionApp()

@app.function_name(name="blob_copy")
@app.event_grid_trigger(arg_name="event")
def main(event: func.EventGridEvent):
    result = json.dumps({
        'id': event.id,
        'data': event.get_json(),
        'topic': event.topic,
        'subject': event.subject,
        'event_type': event.event_type,
    })

    logging.info(f"Python EventGrid trigger processed an event: {result}")

    current_time = datetime.now(timezone.utc)

    blob_name = event.subject.split("/blobs/")[1]

    source_container_name = event.subject.split("/")[4]

    user_delegation_key = source_blob_service_client.get_user_delegation_key(  
        key_start_time=current_time,
        key_expiry_time=current_time + timedelta(hours=1)
    )

    sas_token = generate_blob_sas(
        account_name="cmpadls",
        container_name=source_container_name,
        blob_name=blob_name,
        user_delegation_key=user_delegation_key,
        permission=BlobSasPermissions(read=True),
        expiry=current_time + timedelta(hours=1)
    )

    destination_blob_client = destination_blob_service_client.get_blob_client(
        container='test2', blob=blob_name
    )

    copy_operation = destination_blob_client.start_copy_from_url(
        event.get_json()['url']+ "?" + sas_token
    )

    