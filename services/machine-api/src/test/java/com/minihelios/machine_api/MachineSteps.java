package com.minihelios.machine_api;                                   // same package as the glue (GLUE_PROPERTY_NAME)

import io.cucumber.java.en.Given;                                     // the English @Given annotation
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;                            // to say "the body is JSON"
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public class MachineSteps {

    @Autowired MockMvc mvc;                                            // provided by CucumberSpringConfig

    @Given("no machine with serial {string} exists")
    public void noMachineExists(String serial) throws Exception {
        mvc.perform(get("/v1/machines/" + serial))
           .andExpect(status().isNotFound());                               // HINT: what does GET return for an unknown serial?
    }

    @When("the team registers machine {string} model {string} at site {string}")
    public void registerMachine(String serial, String model, String site) throws Exception {
        String json = """
            {"serial":"%s","model":"%s","site":"%s"}
            """.formatted(serial, model, site);                       // build the request body from the sentence's values
        mvc.perform(put("/v1/machines/" + serial)                      // idempotent upsert (M3)
               .contentType(MediaType.APPLICATION_JSON)
               .content(json))
           .andExpect(status().isOk());                               // HINT: what does your PUT return on success?
    }

    @Then("reading machine {string} returns site {string}")
    public void readingReturnsSite(String serial, String site) throws Exception {
        mvc.perform(get("/v1/machines/" + serial))
           .andExpect(status().isOk())
           .andExpect(jsonPath("$.site").value(site));                 // HINT: which JSON field, and which parameter holds the expected value?
    }
}