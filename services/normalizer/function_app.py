import json                                          # read/write JSON text
import logging                                       # log lines -> counted later as the quarantine KPI
from datetime import datetime, timezone              # timestamp for when we quarantined
import azure.functions as func                       # Azure Functions Python library
from normalize import normalize, needs_action        # YOUR tested logic (copied in at deploy time)

app = func.FunctionApp()                             # the app that holds our function

@app.event_hub_message_trigger(                      # TRIGGER: run when an event arrives
    arg_name="event",                                # the event is passed in as "event"
    event_hub_name="machine-telemetry",              # which event hub to read
    connection="EH_CONN",                            # app setting holding the listen connection (secret, set later)
    consumer_group="cg-normalizer",                  # our own bookmark; other teams unaffected
    cardinality=func.Cardinality.ONE)                # one event per run (simple to read)
@app.cosmos_db_output(                               # OUTPUT 1: upsert into Cosmos
    arg_name="doc",                                  # we hand the document to "doc"
    database_name="helios",                          # Cosmos database
    container_name="machine_state",                  # container partitioned by /serial
    connection="COSMOS_CONN")                        # app setting holding Cosmos connection (secret)
@app.blob_output(                                    # OUTPUT 2: quarantine file in the lake
    arg_name="quarantine",                           # we hand the bad event to "quarantine"
    path="quarantine/{rand-guid}.json",              # container "quarantine", random unique file name
    connection="LAKE_CONN")                          # app setting holding storage connection (secret)
def normalize_telemetry(event: func.EventHubEvent,   # the incoming event
                        doc: func.Out[func.Document],     # where good results go
                        quarantine: func.Out[str]):       # where bad events go
    body = event.get_body().decode("utf-8")          # raw event text, exactly as received
    try:                                             # any adapter failure lands in except
        evt = normalize(json.loads(body))            # dialect -> canonical event
    except Exception as e:                           # ValueError, KeyError, bad JSON... all quarantined
        source = "unknown"                           # default if we can't even read the type
        try:
            source = json.loads(body).get("type", "unknown")  # best effort: which dialect sent it
        except Exception:
            pass                                     # body wasn't JSON at all; keep "unknown"
        quarantine.set(json.dumps({                  # STORE: write raw event + reason to the lake
            "raw": body,                             # untouched original, for replay later
            "source": source,                        # which dialect
            "error_type": type(e).__name__,          # e.g. KeyError
            "error": str(e),                         # e.g. 'sn'
            "quarantined_at": datetime.now(timezone.utc).isoformat()}))  # when (UTC)
        logging.warning(f"QUARANTINED source={source} error={type(e).__name__}")  # COUNT: one line per event
        return                                       # nothing goes to Cosmos
    doc.set(func.Document.from_dict(evt))            # upsert: id serial:metric, drawer /serial
    if needs_action(evt):                            # contextualize: threshold check
        logging.warning(f"ACTION serial={evt['serial']} metric={evt['metric']} value={evt['value']}")  # decision