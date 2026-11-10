package com.minihelios.machine_api;                       // same package as the controller (underscore, from Lab 3.1)

import org.junit.jupiter.api.Test;                        // JUnit 5 @Test
import org.springframework.beans.factory.annotation.Autowired;             // lets Spring inject MockMvc
import org.springframework.boot.test.context.SpringBootTest;               // starts the whole app inside the test
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc; // Boot 4 package (the one we just added)
import org.springframework.test.web.servlet.MockMvc;                       // fake HTTP client, no server, no network

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;       // builds a GET request
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;   // checks a field in the JSON body
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;     // checks the HTTP status

@SpringBootTest                // load the real app (controller, Problem Details config)
@AutoConfigureMockMvc          // Boot 4: must be explicit, or MockMvc is not created
class MachineControllerTest {

    @Autowired MockMvc mvc;    // Spring hands us a ready MockMvc

    @Test
    void unknownSerialReturns404ProblemDetails() throws Exception {
        mvc.perform(get("/v1/machines/NOPE"))                                   // call GET for a serial that doesn't exist
           .andExpect(status().isNotFound())                                   // must be 404, not 500 (your M3 boss fight)
           .andExpect(jsonPath("$.detail").value("Machine NOPE not found"));   // must be the standard Problem Details body
    }
}