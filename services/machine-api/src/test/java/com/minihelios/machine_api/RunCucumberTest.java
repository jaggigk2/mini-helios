package com.minihelios.machine_api;                                           // same package; name ends in "Test" so Maven picks it up

import org.junit.platform.suite.api.ConfigurationParameter;                   // pass a setting to the Cucumber engine
import org.junit.platform.suite.api.IncludeEngines;                           // choose which test engine runs
import org.junit.platform.suite.api.SelectClasspathResource;                  // where the .feature files are
import org.junit.platform.suite.api.Suite;                                    // marks this class as a test suite

import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME; // the "where are the step methods" setting

@Suite                                                                         // JUnit: this class runs a group of tests
@IncludeEngines("cucumber")                                                    // use the Cucumber engine, not plain JUnit
@SelectClasspathResource("features")                                           // run everything in src/test/resources/features
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "com.minihelios.machine_api") // step methods live in this package
class RunCucumberTest {                                                        // empty: the annotations are the whole runner
}