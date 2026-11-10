package com.minihelios.machine_api;                                          // same package as the steps (Cucumber looks here)

import io.cucumber.spring.CucumberContextConfiguration;                      // from cucumber-spring
import org.springframework.boot.test.context.SpringBootTest;                 // start the real app in memory
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc; // Boot 4 package, as in Lab 7.1

@CucumberContextConfiguration   // "use THIS Spring setup for every Cucumber scenario" (exactly one such class allowed)
@SpringBootTest                 // same as Lab 7.1: load controller + config
@AutoConfigureMockMvc           // create MockMvc so steps can @Autowired it
class CucumberSpringConfig {    // empty on purpose: the annotations do all the work
}