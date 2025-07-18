@Basis
@Mandatory
@Procedure-Search
Feature: Testen von Suchparametern gegen procedure-read (@Procedure-Search)

  @vorbedingung
  Scenario: Vorbedingung
    Given Testbeschreibung: "Das zu testende System MUSS die zuvor angelegte Ressource bei einer Suche anhand des Parameters finden und in den Suchergebnissen zurückgeben (SEARCH)."
    Given Mit den Vorbedingungen:
    """
      - Der Testfall Procedure-Read muss zuvor erfolgreich ausgeführt worden sein.
    """

  Scenario: Read und Validierung des CapabilityStatements
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And FHIR current response body evaluates the FHIRPaths:
    """
      rest.where(mode = "server").resource.where(type = "Procedure" and interaction.where(code = "search-type").exists()).exists()
    """

  Scenario Outline: Validierung der Suchparameter-Definitionen im CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Procedure"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | status           | token           |
      | category         | token           |
      | code             | token           |
      | subject          | reference       |
      | patient          | reference       |
      | encounter        | reference       |
      | date             | date            |

  Scenario: Kann die Prozedur anhand der ID gefunden werden?
    Then Get FHIR resource at "http://fhirserver/Procedure/?_id=${data.procedure-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.procedure-read-id}" with error message "Die gesuchte Prozedur ${data.procedure-read-id} ist nicht im Responsebundle enthalten"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Procedure" is valid isik3-basismodul resource and conforms to profile "https://gematik.de/fhir/isik/v3/Basismodul/StructureDefinition/ISiKProzedur"

  Scenario: Suche nach Prozeduren anhand des Status
    Then Get FHIR resource at "http://fhirserver/Procedure/?status=completed" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((status = 'completed').exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche nach Prozeduren anhand der Kategorie
    Then Get FHIR resource at "http://fhirserver/Procedure/?category=http://snomed.info/sct%7C387713003" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((category.where(coding.code = '387713003' and coding.system = 'http://snomed.info/sct')).exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche nach Prozeduren anhand des Codes (OPS)
    Then Get FHIR resource at "http://fhirserver/Procedure/?code=http://fhir.de/CodeSystem/bfarm/ops%7C5-470.11" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((code.coding.where(code = '5-470.11' and system = 'http://fhir.de/CodeSystem/bfarm/ops')).exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche nach Prozeduren anhand des Durchführungsdatums
    Then Get FHIR resource at "http://fhirserver/Procedure/?date=le2050-01-01" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(performedDateTime.exists().not() or performedDateTime <= @2050-01-01T23:59:59+01:00)" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(performedPeriod.start.exists().not() or performedPeriod.start <= @2050-01-01T23:59:59+01:00)" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche nach Prozeduren anhand der Referenz zur PatientIn mit patient
    Then Get FHIR resource at "http://fhirserver/Procedure/?patient=Patient/${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And element "subject" in all bundle resources references resource with ID "${data.patient-read-id}"

  Scenario: Suche nach Prozeduren anhand der Referenz zur PatientIn mit subject
    Then Get FHIR resource at "http://fhirserver/Procedure/?subject=Patient/${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And element "subject" in all bundle resources references resource with ID "${data.patient-read-id}"

  Scenario Outline: Suche nach Prozeduren anhand der Referenzen
    Then Get FHIR resource at "http://fhirserver/Procedure/?<path>=<query><data>" with content type "<contentType>"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(<entrytype>.reference.replaceMatches("/_history/.+","").matches("\\b<data>$"))' with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

    Examples:
      | contentType | entrytype | path      | query      | data                                  |
      | xml         | encounter | encounter | Encounter/ | ${data.encounter-read-in-progress-id} |
      | json        | subject   | patient   | Patient/   | ${data.patient-read-id}               |

  Scenario: Negative Suche nach der Prozedur anhand der ID und des Status
    Then Get FHIR resource at "http://fhirserver/Procedure/?_id:not=${data.procedure-read-id}&status:not=completed" with content type "xml"
    And bundle does not contain resource "Procedure" with ID "${data.procedure-read-id}" with error message "Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien."
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Procedure).all(status.exists() and (status = 'completed').not())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'
