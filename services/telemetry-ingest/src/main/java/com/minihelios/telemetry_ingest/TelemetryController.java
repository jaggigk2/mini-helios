package com.minihelios.telemetry_ingest;                         // MUST match the package line in TelemetryIngestApplication.java

import org.springframework.http.ResponseEntity;                  // lets us return an HTTP status
import org.springframework.kafka.core.KafkaTemplate;             // Spring's Kafka sender
import org.springframework.web.bind.annotation.PathVariable;     // reads {serial} from the URL
import org.springframework.web.bind.annotation.PostMapping;      // maps HTTP POST to a method
import org.springframework.web.bind.annotation.RequestBody;      // reads the request body
import org.springframework.web.bind.annotation.RequestMapping;   // sets the base URL path
import org.springframework.web.bind.annotation.RestController;   // marks this class as a REST controller

@RestController                                                  // this class answers HTTP requests
@RequestMapping("/v1/telemetry")                                 // all URLs start with /v1/telemetry (versioned, like M3)
public class TelemetryController {

    private final KafkaTemplate<String, String> kafka;          // sender: key = String (serial), value = String (JSON payload)

    public TelemetryController(KafkaTemplate<String, String> kafka) {  // Spring builds the sender from our properties and passes it in
        this.kafka = kafka;                                      // keep it for use below
    }

    @PostMapping("/{serial}")                                    // POST /v1/telemetry/CAT-001
    public ResponseEntity<Void> publish(@PathVariable String serial,   // the machine serial from the URL
                                        @RequestBody String payload) { // the reading as raw JSON text
        kafka.send("machine-telemetry", serial, payload);        // put the event on the stream; KEY = serial -> same partition -> in order
        return ResponseEntity.accepted().build();                // 202 Accepted: received, published in the background
    }
}