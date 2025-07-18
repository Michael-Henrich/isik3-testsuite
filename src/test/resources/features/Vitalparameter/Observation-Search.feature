@Vitalparameter
@Mandatory
@Observation-Search
Feature: Testen von Suchparametern gegen observation-read-blutdruck (@Observation-Search)

  @vorbedingung
  Scenario: Vorbedingung
    Given Testbeschreibung: "Das zu testende System MUSS die zuvor angelegte Ressource bei einer Suche anhand des Parameters finden und in den Suchergebnissen zurückgeben (SEARCH)."

    Given Mit den Vorbedingungen:
    """
    - Der Testfall Observation-Read-Blutdruck muss zuvor erfolgreich ausgeführt worden sein.
    """

  Scenario: Read und Validierung des CapabilityStatements
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And FHIR current response body evaluates the FHIRPaths:
    """
    rest.where(mode = "server").resource.where(type = "Observation" and interaction.where(code = "search-type").exists()).exists()
    """

  Scenario Outline: Validierung der Suchparameter-Definitionen im CapabilityStatement
    And FHIR current response body evaluates the FHIRPaths:
    """
      rest.where(mode = "server").resource.where(type = "Observation" and searchParam.where(name = "<searchParamValue>" and type = "<searchParamType>").exists()).exists()
    """

    Examples:
      | searchParamValue          | searchParamType |
      | _id                       | token           |
      | status                    | token           |
      | category                  | token           |
      | patient                   | reference       |
      | subject                   | reference       |
      | encounter                 | reference       |
      | combo-code                | token           |
      | combo-code-value-quantity | composite       |
      | component-code            | token           |

  Scenario: Suche der Observation anhand der ID
    Then Get FHIR resource at "http://fhirserver/Observation/?_id=${data.observation-read-blutdruck-id}" with content type "xml"
    And response bundle contains resource with ID "${data.observation-read-blutdruck-id}" with error message "Die gesuchte Observation ${data.observation-read-blutdruck-id} ist nicht im Responsebundle enthalten"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Observation" is valid isik3-vitalparameter resource and conforms to profile "https://gematik.de/fhir/isik/v3/VitalparameterUndKoerpermasze/StructureDefinition/ISiKBlutdruck"

  Scenario: Suche der Observation anhand des klinischen Status
    Then Get FHIR resource at "http://fhirserver/Observation/?status=final" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'final')" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche nach Observationen anhand der Kategorie
    Then Get FHIR resource at "http://fhirserver/Observation/?category=vital-signs" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(category.coding.where(code = 'vital-signs').exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche der Observation anhand des Datums
    Then Get FHIR resource at "http://fhirserver/Observation/?date=2022-01-01" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(effective.toString().contains('2022-01-01'))" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche der Observation anhand des Datums mit Modifier
    Then Get FHIR resource at "http://fhirserver/Observation/?date=le2050-01-01" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(effective.exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche nach Observationen anhand der Referenz zur PatientIn (Suchparameter patient)
    Then Get FHIR resource at "http://fhirserver/Observation/?patient=Patient/${data.observation-read-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.observation-read-patient-id}"

  Scenario: Suche nach Observationen anhand der Referenz zur PatientIn (Suchparameter subject)
    Then Get FHIR resource at "http://fhirserver/Observation/?subject=Patient/${data.observation-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.observation-read-patient-id}"

  Scenario Outline: Suche nach Observations anhand der Referenzen
    Then Get FHIR resource at "http://fhirserver/Observation/?<path>=<query><data>" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(<entrytype>.reference.replaceMatches('/_history/.+','').matches('\\b<data>$'))" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

    Examples:
      | entrytype | path      | query      | data                                  |
      | encounter | encounter | Encounter/ | ${data.observation-read-encounter-id} |
      | subject   | patient   | Patient/   | ${data.observation-read-patient-id}   |

  Scenario: Suche der Observation anhand des Codes der Observation oder Observation.component
    Then Get FHIR resource at "http://fhirserver/Observation/?combo-code=8462-4" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(code.coding.where(code = '8462-4' and system = 'http://loinc.org').exists() or component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org').exists()).exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche der Observation anhand des combo-code-value-quantity
    Then Get FHIR resource at "http://fhirserver/Observation/?combo-code-value-quantity=8480-6$107" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(code.coding.where(code = '8480-6' and system = 'http://loinc.org').exists() or component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org').exists()).exists() and (value.value ~'107' or component.where(value.value ~'107').exists()))" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche der Observation anhand des component-code
    Then Get FHIR resource at "http://fhirserver/Observation/?component-code=8480-6" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org').exists()).exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'
