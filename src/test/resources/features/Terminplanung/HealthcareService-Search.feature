@Terminplanung
@Mandatory
@HealthcareService-Search
Feature: Testen von Suchparametern gegen die HealthcareService Ressource (@HealthcareService-Search)

  @vorbedingung
  Scenario: Vorbedingung
    Given Testbeschreibung: "Das zu testende System MUSS die angelegte Ressource bei einem HTTP GET auf deren URL korrekt und vollständig zurückgeben (READ)."
    Given Mit den Vorbedingungen:
    """
      - Der Testfall HealthcareService-Read muss zuvor erfolgreich ausgeführt worden sein.
    """

  Scenario: Read und Validierung des CapabilityStatements
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And FHIR current response body evaluates the FHIRPaths:
    """
      rest.where(mode = "server").resource.where(type = "HealthcareService" and interaction.where(code = "search-type").exists()).exists()
    """

  Scenario Outline: Validierung der Suchparameter-Definitionen im CapabilityStatement
    And FHIR current response body evaluates the FHIRPaths:
    """
      rest.where(mode = "server").resource.where(type = "HealthcareService" and searchParam.where(name = "<searchParamValue>" and type = "<searchParamType>").exists()).exists()
    """

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | active           | token           |
      | service-type     | token           |
      | specialty        | token           |
      | name             | string          |

  Scenario: Suche nach dem HealthcareService anhand der ID
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?_id=${data.healthcareservice-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.healthcareservice-read-id}" with error message "Der gesuchte HealthcareService ${data.healthcareservice-read-id} ist nicht im Responsebundle enthalten"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "HealthcareService" is valid isik3-terminplanung resource and conforms to profile "https://gematik.de/fhir/isik/v3/Terminplanung/StructureDefinition/ISiKMedizinischeBehandlungseinheit"

  Scenario: Suche nach der Nachricht anhand des Status
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?active=true" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(HealthcareService).count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(HealthcareService).all(active = 'true')" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario Outline: Suche nach der Nachricht anhand des Behandlungstyps
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?<searchParameter>=<searchValue>" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(HealthcareService).count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(HealthcareService).all(<coding>.coding.where(code='<searchValue>').exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

    Examples:
      | searchParameter | coding    | searchValue |
      | service-type    | type      | ${data.healthcareservice-read-servicetype-code} |

  Scenario: Suche nach der Nachricht anhand der Fachrichtung
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?specialty=urn%3Aoid%3A1.2.276.0.76.5.114%7C142%2Chttp%3A%2F%2Fihe-d.de%2FCodeSystems%2FAerztlicheFachrichtungen%7CNEUR" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(HealthcareService).count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(HealthcareService).all(specialty.coding.where((code = '142' and system ='urn:oid:1.2.276.0.76.5.114') or (code = 'NEUR' and system ='http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen' )).exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  Scenario: Suche nach der Nachricht anhand des Namens
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?name=Allgemeine%20Beratungsstelle%20der%20Fachabteilung%20Neurologie" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(HealthcareService).count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(HealthcareService).all(name.contains('Allgemeine Beratungsstelle der Fachabteilung Neurologie'))" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'
