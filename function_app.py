import logging
import json
import azure.functions as func

app = func.FunctionApp()

@app.function_name(name="eventGridTrigger")
@app.event_grid_trigger(arg_name="event")
def eventGridTest(event: func.EventGridEvent):
    result = json.dumps({
        'id': event.id,
        'data': event.get_json(),
        'topic': event.topic,
        'subject': event.subject,
        'event_type': event.event_type,
    })

    print(123)

    logging.info('Python EventGrid trigger processed an event: %s', result)