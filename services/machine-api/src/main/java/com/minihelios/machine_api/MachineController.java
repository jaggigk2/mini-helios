package com.minihelios.machine_api;                       // must match YOUR folder (underscore)

import jakarta.validation.Valid;                           // turns on the @NotBlank checks for a request body
import jakarta.validation.constraints.NotBlank;            // "this field must not be empty"
import org.springframework.http.*;                         // ResponseEntity, HttpStatus, ProblemDetail
import org.springframework.web.bind.annotation.*;          // @RestController, @GetMapping, @PutMapping...
import java.util.*;                                        // Map, List
import java.util.concurrent.ConcurrentHashMap;             // a Map that's safe when many requests arrive at once

// A record = an immutable data class; Spring turns it into JSON and back automatically
record Machine(@NotBlank String serial, @NotBlank String model, @NotBlank String site) {}

@RestController                                            // this class answers HTTP requests with JSON
@RequestMapping("/v1/machines")                            // version in the path: /v1 never breaks
class MachineController {

    // In-memory store for the lab (lost on restart); Module 5 moves this to a real database
    private final Map<String, Machine> store = new ConcurrentHashMap<>();

    @PutMapping("/{serial}")                               // PUT /v1/machines/ABC123
    ResponseEntity<Machine> upsert(@PathVariable String serial, @Valid @RequestBody Machine m) {
        store.put(serial, m);                              // same serial twice = same result (idempotent)
        return ResponseEntity.ok(m);                       // 200 + the machine as JSON
    }

    @GetMapping("/{serial}")                               // GET /v1/machines/ABC123
    ResponseEntity<Machine> get(@PathVariable String serial) {
        Machine m = store.get(serial);                     // look it up
        if (m == null) {                                   // unknown serial?
            // Problem Details (RFC 7807): the standard error shape every caller can parse
            ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, "Machine " + serial + " not found");
            return ResponseEntity.of(pd).build();          // 404 + Problem Details body, NOT a 500
        }
        return ResponseEntity.ok(m);                       // 200 + the machine
    }

    @GetMapping                                            // GET /v1/machines?page=0&size=20
    List<Machine> list(@RequestParam(defaultValue = "0") int page,   // which page (starts at 0)
                       @RequestParam(defaultValue = "20") int size) { // how many per page
        return store.values().stream()                     // all machines...
                .skip((long) page * size)                  // ...skip earlier pages...
                .limit(size)                               // ...take one page
                .toList();                                 // pagination from day one
    }
}