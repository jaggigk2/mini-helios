Feature: Machine registry for product teams
  # Business language: a PO can read this, Cucumber can run it

  Scenario: A product team registers a machine and reads it back
    Given no machine with serial "EX-101" exists
    When the team registers machine "EX-101" model "320" at site "Chennai"
    Then reading machine "EX-101" returns site "Chennai"