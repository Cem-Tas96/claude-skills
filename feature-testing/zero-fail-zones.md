# Zero-Fail-Zonen Prüflisten — v1.2.0

Diese Domänen haben **null Toleranz für fehlende Tests**. Die vollständige Prüfliste für jedes Feature ausführen das diese Bereiche berührt.

Neu in v1.2.0: Abschnitt "API-KEY / LIZENZ-AUTHENTIFIZIERUNG" für Connector-Projekte ohne klassisches Login-System.

---

## API-KEY / LIZENZ-AUTHENTIFIZIERUNG (Connector-spezifisch — Neu in v1.2.0)

> Ziel: Beweisen dass nur Requests mit gültigen, nicht abgelaufenen, nicht manipulierten API-Keys und Lizenzschlüsseln verarbeitet werden. Kein eigenes Login-System — aber API-Key-Validierung ist funktional äquivalent zu Auth-Token-Validierung.

### Pflicht-Tests

**API-Key-Validierung (Eingehende Requests)**
- [ ] Gültiger API-Key → Request verarbeitet, korrekte Antwort
- [ ] Fehlender API-Key (kein Header) → 401, kein Hinweis auf erwartetes Format oder Key-Wert
- [ ] Falscher API-Key → 401, gleiche Antwortzeit wie bei fehlendem Key (Timing-Attack-Prevention)
- [ ] API-Key mit falscher Formatierung (zu kurz, falsche Zeichen) → 401
- [ ] API-Key in Query-Parameter statt Header → abgelehnt (Keys nur in Headern erlaubt)
- [ ] API-Key wird nicht in Logs ausgegeben — assertieren mit Log-Spy in Tests
- [ ] Admin-API-Key auf normalem Endpoint → 403 (kein versehentlicher Cross-Access)
- [ ] Normaler API-Key auf Admin-Endpoint → 403

**Lizenzschlüssel-Validierung (Job-Verarbeitung)**
- [ ] Gültiger, aktiver Lizenzschlüssel → Job wird gestartet
- [ ] Abgelaufener Lizenzschlüssel → 403 mit klarer Fehlermeldung, Job wird NICHT gestartet, kein Ressourcenverbrauch
- [ ] Gesperrter/gekündigter Lizenzschlüssel → 403, Job wird NICHT gestartet
- [ ] Ungültiger/unbekannter Lizenzschlüssel → 401 oder 403 (dokumentiertes Verhalten), nicht 500
- [ ] Lizenzschlüssel für falschen Connector-Typ → abgelehnt
- [ ] Lizenz-Service nicht erreichbar → definiertes Verhalten: Fail-Open (riskant, dokumentieren) oder Fail-Closed (sicher, empfohlen)
- [ ] Lizenz-Service antwortet mit Timeout → gleich wie "nicht erreichbar"
- [ ] Lizenzschlüssel wird nicht in Logs ausgegeben — assertieren mit Log-Spy

**Replay- und Manipulations-Schutz**
- [ ] Webhook-Signatur vorhanden und korrekt → verarbeitet
- [ ] Webhook-Signatur fehlt → 401, kein Payload verarbeitet
- [ ] Webhook-Signatur falsch (manipulierter Payload) → 401
- [ ] Replay-Angriff: alter Webhook mit gültiger Signatur aber abgelaufenem Timestamp → abgelehnt
- [ ] Doppelanfrage mit identischem Payload (doppelter Webhook) → genau einmal verarbeitet (Idempotenz)

**Transport-Sicherheit**
- [ ] Sensitive Keys nicht in URL-Query-Parametern (nur in Headern)
- [ ] API-Keys werden nicht in Response-Bodys zurückgegeben
- [ ] Fehler-Responses enthalten keine Hinweise auf gültige Key-Formate

---

## AUTHENTIFIZIERUNG (Klassisch — für Projekte mit Login-System)

> Ziel: Beweisen dass nur legitime, nicht abgelaufene, nicht manipulierte Zugangsdaten Zugang gewähren.

### Pflicht-Tests

**Token- / Session-Lebenszyklus**
- [ ] Gültige Zugangsdaten → Zugang gewährt, korrekter Token/Session ausgestellt
- [ ] Falsches Passwort → 401, kein Token ausgestellt, kein Hinweis welches Feld falsch ist
- [ ] Nicht existierender Benutzer → 401 (gleiche Antwortzeit und Nachricht wie falsches Passwort — User-Enumeration verhindern)
- [ ] Abgelaufener Token → 401, kein stilles Refresh
- [ ] Fehlerhafter Token (abgeschnitten, Datenmüll, falsche Kodierung) → 401
- [ ] Token mit falschem Schlüssel signiert → 401
- [ ] Token mit manipuliertem Payload (Benutzer-ID oder Rolle geändert) → 401
- [ ] Einmalig verwendbarer Token wiederverwendet (Passwort-Reset, Magic Link) → 401 beim zweiten Einsatz
- [ ] Gleichzeitige Sessions: erwartetes Verhalten definieren und explizit testen
- [ ] Konto gesperrt nach N fehlgeschlagenen Versuchen → nachfolgende korrekte Anmeldung während Sperrzeit ebenfalls blockiert
- [ ] Sperrzeit läuft nach konfigurierter Dauer korrekt ab

**Zugangsdaten-Behandlung**
- [ ] Passwörter werden gehasht gespeichert (niemals als Klartext gespeichert oder zurückgegeben)
- [ ] Auth-Logs enthalten KEINE Klartextpasswörter, Tokens oder Secrets
- [ ] Passwort-Reset-Token läuft nach konfigurierter Dauer ab
- [ ] Passwort-Reset-Token wird nach Verwendung ungültig

**Transport-Sicherheit**
- [ ] Auth-Endpoints nur über HTTPS in der Produktionskonfiguration erreichbar
- [ ] Sensitive Tokens nicht in URL-Query-Parametern (nur in Headern oder Body)

---

## AUTORISIERUNG (Berechtigungen & Zugriffskontrolle)

> Ziel: Beweisen dass authentifizierte Benutzer/Systeme nur auf Ressourcen zugreifen können die ihnen gehören oder für die sie explizit berechtigt sind.

### Pflicht-Tests

**Horizontale Zugriffskontrolle (Eigene Ressourcen)**
- [ ] Benutzer/Tenant A kann auf seine eigene Ressource zugreifen
- [ ] Benutzer/Tenant A kann **nicht** auf die Ressource von Benutzer/Tenant B zugreifen (gibt 403 oder 404 zurück, niemals 200 mit falschen Daten)
- [ ] Änderung der Ressourcen-ID in der Anfrage auf die ID eines anderen Benutzers → Zugang verweigert
- [ ] Massenoperationen (Auflisten, Batch-Update) werden auf eigene Ressourcen gefiltert

**Vertikale Zugriffskontrolle (Rollenbasiert)**
- [ ] Jede Rolle kann genau die Aktionen ausführen die sie darf
- [ ] Niedrigere Berechtigungsstufe kann **keine** höhere Berechtigungsaktion ausführen
- [ ] Privilege-Escalation-Versuch: Benutzer setzt eigene Rolle via API auf Admin → abgelehnt
- [ ] Gelöschter/deaktivierter Benutzer kann auf keine Ressource zugreifen

**Admin- / Interne Endpoints**
- [ ] Nur-Admin-Endpoints geben 403 für normale Benutzer zurück (nicht 404)
- [ ] Interne/Service-Endpoints sind vom öffentlichen Netzwerk nicht erreichbar

**Multi-Tenancy (falls zutreffend)**
- [ ] Mandant A kann durch keine ID-Manipulation auf Daten von Mandant B zugreifen
- [ ] Mandantenübergreifende Operationen im Admin-Panel erfordern expliziten Mandantenbereich

---

## ZAHLUNGEN & GELD

> Ziel: Beweisen dass Geld nur korrekt, niemals stillschweigend, niemals doppelt und niemals verloren bewegt wird.

### Pflicht-Tests

**Happy Path**
- [ ] Erfolgreiche Zahlung erstellt korrekte Datensätze in allen Systemen (Bestellung, Transaktion, Hauptbuch)
- [ ] Zahlungsbetrag entspricht dem serverseitig berechneten Betrag (nicht dem clientseitig übermittelten)
- [ ] Währung wird serverseitig validiert — Client kann Währung nicht ändern

**Fehlerpfade**
- [ ] Zahlungsanbieter gibt Ablehnung zurück → Bestellung NICHT erfüllt, Benutzer informiert
- [ ] Zahlungsanbieter gibt 500 zurück → Bestellung NICHT erfüllt, kein doppelter Belastungsversuch, Wiederholung ist sicher
- [ ] Netzwerk-Timeout während Zahlung → System behandelt idempotent (keine Doppelbelastung)
- [ ] Zahlungs-Webhook kommt zweimal an (Duplikat) → genau einmal verarbeitet (Idempotenz-Schlüssel)
- [ ] Zahlungs-Webhook kommt in falscher Reihenfolge an → System behandelt korrekt

**Betrugs-/Missbrauchs-Prävention**
- [ ] Clientseitige Preismanipulation (Betrag im Request-Body ändern) → Server lehnt ab
- [ ] Denselben Rabattcode zweimal anwenden → nach erster Verwendung abgelehnt
- [ ] Negativer Betrag in Zahlungsanfrage → abgelehnt
- [ ] Währungsabweichung zwischen Bestellung und Zahlung → abgelehnt

**Rückerstattungen**
- [ ] Vollständige Rückerstattung → korrekter Betrag zurückgegeben, Bestellstatus aktualisiert
- [ ] Teilrückerstattung → korrekter Teilbetrag, verbleibender Saldo korrekt
- [ ] Rückerstattung für bereits erstattete Zahlung → abgelehnt
- [ ] Rückerstattungsbetrag > ursprüngliche Zahlung → abgelehnt

**Hauptbuch-Integrität**
- [ ] Alle Geldbewegungen werden mit Zeitstempel, Akteur, Betrag und Grund protokolliert
- [ ] Hauptbuch ist append-only (keine Updates, keine Löschungen)

---

## DATENSCHUTZ & SICHERHEIT

> Ziel: Beweisen dass personenbezogene Daten und sensitive Inhalte nur für berechtigte Systeme zugänglich sind und Angriffsvektoren geschlossen sind.

### Pflicht-Tests

**Datenzugriff**
- [ ] Personenbezogene Daten (PII) werden nicht in Responses zurückgegeben wo sie nicht benötigt werden
- [ ] PII-Felder werden nicht geloggt (Log-Output in Tests prüfen mit Log-Spy)
- [ ] Gelöschte Benutzerdaten werden gemäß Datenschutzrichtlinie tatsächlich gelöscht oder anonymisiert
- [ ] Temp-Files mit sensitiven Inhalten werden nach Verarbeitung sicher gelöscht (kein Plaintext auf Disk)

**Eingabe-Validierung & Injection**
- [ ] SQL-Injection-Payload in jedem benutzerseitig eingegebenen String-Feld → kein DB-Fehler, kein Datenleck
- [ ] NoSQL-Injection (MongoDB-Operator-Injection, z.B. `{ "$gt": "" }`) → abgelehnt oder harmlos behandelt
- [ ] XSS-Payload in String-Feldern die in DB gespeichert werden → sicher gespeichert, escaped ausgegeben
- [ ] XSS in HTML-Input (Puppeteer rendert HTML!) → sanitized BEVOR Rendering, kein Script-Execution
- [ ] Pfad-Traversal in Dateinamen-/Pfad-Eingaben (`../../etc/passwd`) → abgelehnt
- [ ] Command-Injection in Feldern die in Shell-Kommandos verwendet werden → abgelehnt
- [ ] XXE in XML/HTML-Eingaben → abgelehnt
- [ ] Überdimensionierte Eingaben (10-MB-String, 100-MB-Datei) → mit 400/413 abgelehnt, kein Absturz

**Kryptografie**
- [ ] Sensible Felder die verschlüsselt gespeichert werden verwenden aktuelle Algorithmen (AES-256-GCM, nicht DES/RC4/MD5)
- [ ] Keine hardcodierten Secrets, API-Schlüssel oder Passwörter im Code (Secret-Scanner ausführen)
- [ ] Encryption-Key-Rotation: wenn Key geändert wird, können alte Daten noch entschlüsselt werden (oder Migrationsplan vorhanden)
- [ ] Verschlüsselte Daten in DB sind als Ciphertext gespeichert — nie als Plaintext (assertieren durch direkte DB-Abfrage im Test)

**Rate-Limiting**
- [ ] Auth-Endpoints (API-Key-Validierung, Lizenz-Check) haben Rate-Limiting
- [ ] Teure Operationen (PDF-Konvertierung, Datei-Upload) haben Rate-Limiting
- [ ] Rate-Limit-Bypass-Versuche (IP-Rotation, Header-Manipulation) → bleiben effektiv

---

## BERECHTIGUNGSSYSTEME

> Ziel: Beweisen dass Berechtigungsprüfungen durch keinen Pfad im Code umgangen werden können.

### Pflicht-Tests

**Berechtigungs-Durchsetzungspunkte**
- [ ] Berechtigung wird serverseitig geprüft, nicht nur clientseitig
- [ ] Berechtigungsprüfung erfolgt für jeden Einstiegspunkt zur Ressource (REST-Endpoint, GraphQL-Resolver, Background-Job, Webhook-Handler, Admin-Panel)
- [ ] Umgehung der UI (direkter API-Aufruf) erzwingt trotzdem Berechtigungen

**Berechtigungsänderungen**
- [ ] Entzug einer Berechtigung wird sofort wirksam (oder Eventual-Consistency-Fenster dokumentieren)
- [ ] Berechtigungsänderung wird auditiert (wer hat was für wen wann geändert)

**Standard-Verweigerung**
- [ ] Neue Ressource ist standardmäßig privat/nicht zugänglich
- [ ] Neuer Benutzer hat standardmäßig minimale erforderliche Berechtigungen (nicht Admin)
- [ ] Neuer Endpoint hinzugefügt: Standard ist kein Zugang (muss explizit gewährt werden)

---

## DATENMIGRATIONEN

> Ziel: Beweisen dass die Migration Daten korrekt transformiert und sicher rückgängig gemacht werden kann.

### Pflicht-Tests

**Korrektheit**
- [ ] Alle bestehenden Dokumente/Zeilen werden korrekt transformiert (Stichprobe + Anzahl)
- [ ] Null-/Grenzfall-Werte in Quellfeldern werden explizit behandelt
- [ ] Keine Daten gehen verloren (Anzahl vorher = nachher, oder Differenz ist dokumentiert)
- [ ] Neu hinzugefügte Felder haben korrekte Standardwerte für bestehende Dokumente

**Sicherheit**
- [ ] Migration läuft fehlerfrei auf einer Kopie des Produktionsdaten-Volumens (Performance-Test)
- [ ] Migration ist idempotent (zweimalige Ausführung korrumpiert keine Daten)
- [ ] Rollback-Migration (down) stellt Daten auf Vor-Migrations-Zustand zurück
- [ ] Alte Anwendungsversion + neues Schema = kein Absturz (Zero-Downtime-Deploy-Kompatibilität)
- [ ] Neue Anwendungsversion + altes Schema = kein Absturz (Rückwärtskompatibilitätsfenster)

**Locks (MongoDB-spezifisch)**
- [ ] Migration hält keine Collection-Level-Locks die den Produktionsbetrieb für > [SLA-Schwelle]ms blockieren
- [ ] Index-Erstellung läuft im Hintergrund (`background: true` oder `createIndex` async)
- [ ] Migration auf großen Collections läuft in Batches (kein Single-Query über Millionen Dokumente)