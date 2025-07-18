@Basis
@Mandatory
@Encounter-Read-In-Progress
Feature: Lesen der Ressource Encounter (@Encounter-Read-In-Progress)

  @vorbedingung
  Scenario: Vorbedingung
    Given Testbeschreibung: "Das zu testende System MUSS die angelegte Ressource bei einem HTTP GET auf deren URL korrekt und vollständig zurückgeben (READ)."
    Given Mit den Vorbedingungen:
    """
      - Der Testfall Patient-Read muss zuvor erfolgreich ausgeführt worden sein.
      - der Testdatensatz muss im zu testenden System gemäß der Vorgaben (manuell) erfasst worden sein.
      - die ID der korrespondierenden FHIR-Ressource zu diesem Testdatensatz sowie die zugewiesene einrichtungsinterne Aufnahmenummer muss in der Konfigurationsvariable 'encounter-read-in-progress-id' hinterlegt sein.

      Testdatensatz (Name: Wert)
      Legen Sie den folgenden Kontakt in Ihrem System an (Bitte fügen Sie die optionalen Werte hinzu, wenn Sie die optionalen Such Tests für Encounter bestehen möchten):
      Aufnahmenummer: Valide Aufnahmenummer vergeben durch das zu testende System
      Status: In Durchführung
      Typ: Normalstationär
      Patient: Der Patient aus Testfall Patient-Read
      Aufnahmeanlass: Einweisung durch einen Arzt.
      Fachabteilung: Allgemeine Chirurgie
      Beginn des Kontaktes: 2021-02-12
      Leistungsanbieter (Identifier): 1234567890
      Leistungsanbieter (Display): Krankenhaus
      Optional - Leistungsanbieter (Referenz): Beliebig
      Optional - Ort: Beliebig
    """

  Scenario: Read und Validierung des CapabilityStatements
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Encounter"

  Scenario: Read eines Encounter anhand der ID
    Then Get FHIR resource at "http://fhirserver/Encounter/${data.encounter-read-in-progress-id}" with content type "xml"
    And resource has ID "${data.encounter-read-in-progress-id}"
    And FHIR current response body is a valid isik3-basismodul resource and conforms to profile "https://gematik.de/fhir/isik/v3/Basismodul/StructureDefinition/ISiKKontaktGesundheitseinrichtung"
    And TGR current response with attribute "$..status.value" matches "in-progress"
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = '${data.encounter-read-in-progress-identifier-system}' and value='${data.encounter-read-in-progress-identifier-value}').exists()" with error message 'Der Kontakt enthält nicht die korrekte Aufnahmenummer'
    And FHIR current response body evaluates the FHIRPath "class.where(code = 'IMP' and system = 'http://terminology.hl7.org/CodeSystem/v3-ActCode').exists()" with error message 'Der Kontakt enthält nicht die korrekte Art'
    And FHIR current response body evaluates the FHIRPath "type.coding.where(code = 'normalstationaer' and system = 'http://fhir.de/CodeSystem/kontaktart-de').exists()" with error message 'Der Kontakt enthält nicht den korrekten Typ'
    And FHIR current response body evaluates the FHIRPath "serviceType.coding.where(code = '1500' and system = 'http://fhir.de/CodeSystem/dkgev/Fachabteilungsschluessel').exists()" with error message 'Der Kontakt enthält nicht den korrekten Fachabteilungsschlüssel'
    # And element "subject" references resource with ID "${data.patient-read-id}$" with error message "Referenzierter Patient entspricht nicht dem Erwartungswert"
    And element "subject" references resource with ID "${data.patient-read-id}" with error message "Referenzierter Patient entspricht nicht dem Erwartungswert"
    And FHIR current response body evaluates the FHIRPath "period.start.toString().contains('2021-02-12')" with error message 'Der Beginn des Kontakts entspricht nicht dem Erwartungswert'
    And FHIR current response body evaluates the FHIRPath "hospitalization.admitSource.coding.where(code = 'E' and system = 'http://fhir.de/CodeSystem/dgkev/Aufnahmeanlass').exists()" with error message 'Der Kontakt enthält nicht den korrekten Aufnahmeanlass'
