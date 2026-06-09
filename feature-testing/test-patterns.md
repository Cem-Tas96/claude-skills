# Testmuster für häufige Feature-Typen — v1.2.0

Diese Datei laden wenn Tests für die aufgeführten Feature-Muster implementiert werden.
Patterns 1–10: Allgemein | Patterns 11–20: Connector/Integration | Patterns 21–24: Neu in v1.2.0

---

## PAGINATION

Pflicht-Tests:
- [ ] Erste Seite gibt korrekte Einträge in korrekter Reihenfolge zurück
- [ ] Letzte Seite gibt verbleibende Einträge zurück (kein Überlauf)
- [ ] Seite ohne Ergebnisse gibt leeres Array zurück (nicht null, nicht 404)
- [ ] `total_count` oder `has_next_page` ist korrekt
- [ ] Ungültige `page`/`limit`-Werte → 400 mit klarer Nachricht
- [ ] Extrem großer `limit`-Wert → auf Server-Maximum begrenzt, kein Out-of-Memory
- [ ] Stabile Sortierung: Einträge springen nicht zwischen Seitenanfragen (konsistenter Sortierschlüssel)
- [ ] Cursor-basiert: Cursor von Seite N gibt immer Seite N+1 zurück, auch wenn neue Datensätze hinzugefügt wurden

---

## SOFT DELETE

Pflicht-Tests:
- [ ] Soft-gelöschter Datensatz wird aus allen Listen-/Suchanfragen ausgeschlossen
- [ ] Soft-gelöschter Datensatz gibt 404 bei direktem Abruf zurück (nicht 200 mit `deleted: true`)
- [ ] Soft-gelöschter Datensatz wird NICHT aus Admin-/Audit-Ansichten ausgeschlossen (falls zutreffend)
- [ ] Ressource mit gleichem eindeutigen Bezeichner neu erstellen: Verhalten ist definiert und getestet
- [ ] Hard Delete (falls vorhanden): Datensatz + verknüpfte Datensätze werden bereinigt
- [ ] `deleted_at`-Zeitstempel wird beim Löschen korrekt gesetzt
- [ ] `deleted_by` wird geloggt wenn sicherheitsrelevant

---

## BACKGROUND JOBS / ASYNCHRONE VERARBEITUNG

Pflicht-Tests:
- [ ] Job wird mit korrektem Payload in die Warteschlange gestellt wenn Trigger-Event ausgelöst wird
- [ ] Job wird erfolgreich ausgeführt und produziert erwartetes Ergebnis
- [ ] Job ist idempotent: zweimalige Ausführung mit gleichem Input = gleiches Ergebnis, keine doppelten Seiteneffekte
- [ ] Job schlägt fehlertolerant fehl: bei Fehler, wird er wiederholt? Wie oft? Was ist der Endzustand?
- [ ] Dead-Letter-Queue: nach maximalen Wiederholungen landet Job in DLQ mit Fehlerkontext
- [ ] Job verarbeitet keinen Datensatz den ein anderer Worker bereits verarbeitet (Nebenläufigkeitssicherheit)
- [ ] Job behandelt veraltete Daten: was passiert wenn der Datensatz zwischen Einreihen und Ausführung gelöscht wurde?

---

## WEBHOOKS (Eingehend)

Pflicht-Tests:
- [ ] Gültiger Webhook mit korrekter Signatur → korrekt verarbeitet
- [ ] Ungültige/fehlende Signatur → mit 401 abgelehnt, NICHT verarbeitet
- [ ] Duplikat-Webhook (gleiche Event-ID) → genau einmal verarbeitet (Idempotenz)
- [ ] Webhook mit unbekanntem Event-Typ → bestätigt (200) aber nicht verarbeitet, kein Absturz
- [ ] Webhook mit fehlerhaftem Payload → 400 geloggt, kein Absturz
- [ ] Fehler bei der Webhook-Verarbeitung → gibt Nicht-2xx zurück damit Anbieter wiederholt (falls Wiederholung gewünscht)

---

## DATEI-UPLOAD

Pflicht-Tests:
- [ ] Gültige Datei innerhalb des Größenlimits → hochgeladen und abrufbar
- [ ] Datei genau am Größenlimit → akzeptiert
- [ ] Datei 1 Byte über dem Größenlimit → mit 413 abgelehnt
- [ ] Null-Byte-Datei → Verhalten definiert (ablehnen oder akzeptieren — beides testen je nach Spezifikation)
- [ ] Nicht erlaubter MIME-Typ → abgelehnt (validiert aus Dateiinhalt, nicht nur Erweiterung)
- [ ] Dateiname mit Pfad-Traversal (`../../etc/passwd`) → bereinigt/abgelehnt
- [ ] Gleichzeitige Uploads derselben Datei → keine Race Condition, korrekter Endzustand
- [ ] Upload-Fehler auf halbem Weg → keine Teildatei gespeichert, Speicher ist sauber
- [ ] Datei-URL ist nicht öffentlich erratbar (keine sequenziellen, nicht vorhersehbaren IDs)

---

## SUCHE / FILTERUNG

Pflicht-Tests:
- [ ] Suche mit exakter Übereinstimmung gibt korrekte Ergebnisse zurück
- [ ] Suche ohne Ergebnisse gibt leeres Array zurück (kein Fehler)
- [ ] Suche ist auf eigene Daten des Benutzers begrenzt (kein benutzerübergreifendes Datenleck)
- [ ] SQL-/NoSQL-Injection im Suchbegriff → kein Datenleck, kein Absturz
- [ ] Sehr langer Suchstring → korrekt behandelt (abgeschnitten oder abgelehnt, kein Absturz)
- [ ] Sonderzeichen in der Suche (`%`, `_`, `*`, `"`) → korrekt behandelt
- [ ] Filter-Kombinationen: AND/OR/NICHT-Logik ergibt korrekte Ergebnismengen
- [ ] Sortierreihenfolge ist stabil und konsistent

---

## MULTI-TENANCY

Pflicht-Tests:
- [ ] Alle Abfragen sind nach `tenant_id` begrenzt (in Tests assertieren dass keine mandantenübergreifende Abfrage möglich ist)
- [ ] ID von Mandant A in Session von Mandant B → 403 oder 404
- [ ] Geteilte Ressourcen (globale Config, Systemdaten) für alle Mandanten korrekt zugänglich
- [ ] Mandantenspezifische Limits/Quoten werden pro Mandant durchgesetzt (nicht global)
- [ ] Admin der im Auftrag von Mandant A handelt kann nicht versehentlich Mandant B beeinflussen

---

## EVENT SOURCING / AUDIT-LOG

Pflicht-Tests:
- [ ] Jede zustandsändernde Aktion hängt ein Event an (keine stillen Änderungen)
- [ ] Event enthält: wer (Akteur), was (Aktion), an was (Ressourcen-ID), wann (Zeitstempel)
- [ ] Wiedergabe der Events vom leeren Zustand produziert korrekten aktuellen Zustand
- [ ] Events sind append-only (keine Updates/Löschungen vergangener Events)
- [ ] Gleichzeitige Events: Reihenfolge ist deterministisch oder wird durch optimistische Sperre behandelt

---

## RATE LIMITING

Pflicht-Tests:
- [ ] Anfragen unter dem Limit → alle erfolgreich
- [ ] Anfrage genau am Limit → erfolgreich
- [ ] Anfrage über dem Limit → 429 mit `Retry-After`-Header
- [ ] Rate-Limit setzt nach Ablauf des Zeitfensters zurück
- [ ] Rate-Limit gilt pro Benutzer/API-Key, nicht nur pro IP
- [ ] Limit kann nicht durch Änderung von Headern, IPs oder Request-Struktur umgangen werden

---

## CACHING

Pflicht-Tests:
- [ ] Erste Anfrage → Daten aus Quelle abgerufen (Cache-Miss)
- [ ] Zweite Anfrage → Daten aus Cache geliefert (Cache-Hit, mit Mock/Spy verifizieren)
- [ ] Cache wird invalidiert wenn zugrunde liegende Daten sich ändern (keine veralteten Daten nach Update)
- [ ] Cache-Miss-Behandlung: Quelle nicht verfügbar → korrekter Fallback oder Fehler, kein Absturz
- [ ] Gecachte Daten von Benutzer/Credential A werden nicht für B zurückgegeben (kein Cache-Poisoning)
- [ ] TTL: Cache läuft nach konfigurierter Dauer ab

---

## HTTP-CLIENT / API-CONSUMER

> Für jede Komponente die externe HTTP-APIs aufruft (REST, SOAP, GraphQL). Kern-Pattern für alle Connector-Projekte.

**Erfolgs-Pfade**
- [ ] Erfolgreiche Anfrage (2xx) → Response korrekt geparst und zurückgegeben
- [ ] Response mit unerwarteten Extra-Feldern → keine Exception, bekannte Felder korrekt extrahiert
- [ ] Leere Response (204 No Content) → definiertes Verhalten, kein Crash
- [ ] Große Response → Max-Size respektiert, kein Out-of-Memory
- [ ] Binäre Response (Buffer/Stream) → korrekt als Buffer/Stream zurückgegeben, nicht als String

**Fehler-Pfade**
- [ ] Client-Fehler (4xx außer 408/429) → NICHT retried, sofortiger konkreter Fehler
- [ ] Server-Fehler (5xx) → retried nach konfiguriertem Delay-Schema
- [ ] Timeout → retried, nach Max-Retries finaler Fehler mit Timeout-Kontext
- [ ] DNS-Fehler / Connection Refused → klarer Fehler, nicht als Timeout maskiert
- [ ] Rate-Limit (429) → `Retry-After` Header respektiert, dann erneut versucht
- [ ] Alle Retries erschöpft → letzter konkreter Fehler geworfen (nicht generischer "Request failed")
- [ ] Response-Format unerwartet (HTML statt JSON) → klarer Parse-Fehler, kein Absturz

**Daten-Integrität**
- [ ] Request-Body korrekt serialisiert (JSON, FormData, Multipart, URL-encoded)
- [ ] Response-Encoding korrekt behandelt (UTF-8, gzip, deflate)

**Sicherheit**
- [ ] SSL/TLS-Fehler → dokumentiertes Verhalten (Abbruch, kein stilles Ignorieren)
- [ ] Sensitive Header (API-Keys, Tokens) erscheinen NICHT in Fehler-Logs (assertieren!)
- [ ] Redirect-Ketten → definiertes Maximum, kein Endlos-Redirect

---

## FILE-PIPELINE (Download → Verarbeitung → Upload)

> Für Features die Dateien von einer Quelle herunterladen, lokal verarbeiten und das Ergebnis hochladen.

**Download-Phase**
- [ ] Download mit gültigem Token/Credential → Datei korrekt auf Disk gespeichert
- [ ] Download mit ungültigem/abgelaufenem Token → klarer Fehler, kein leeres File auf Disk
- [ ] Download-Timeout (große Datei / langsame Quelle) → Timeout gehandelt, Temp-File aufgeräumt
- [ ] Verschiedene Input-Formate (Token, Base64, downloadPermitToken) → alle korrekt erkannt und verarbeitet
- [ ] Content-Disposition Header → Dateiname korrekt extrahiert (inkl. UTF-8 Encoding)
- [ ] Stream-Modus → Streaming funktioniert; bei Stream-Fehler → Memory-Fallback greift

**Verarbeitungs-Phase**
- [ ] Gültige Eingabedatei → erwartetes Ergebnis produziert
- [ ] Beschädigte/korrupte Eingabedatei → klarer Fehler, keine halben Ergebnisse
- [ ] Leere Datei (0 Bytes) → definiertes Verhalten (ablehnen oder verarbeiten)
- [ ] Überdimensionierte Datei → Limit geprüft VOR Verarbeitung, nicht erst bei Out-of-Memory
- [ ] Falscher Dateityp (z.B. JPEG statt PDF) → erkannt und abgelehnt vor Verarbeitung

**Upload-Phase**
- [ ] Ergebnis erfolgreich hochgeladen → korrekter Token/ID zurückgegeben
- [ ] Upload fehlgeschlagen → Fehler gemeldet, Temp-Files trotzdem aufgeräumt
- [ ] Upload-Response validiert (downloadPermitToken und binaryId vorhanden)

**Cleanup (KRITISCH)**
- [ ] Nach Erfolg: ALLE Temp-Files und Temp-Verzeichnisse gelöscht
- [ ] Nach Fehler: ALLE Temp-Files und Temp-Verzeichnisse gelöscht
- [ ] Parallele Jobs: kein Temp-Dir-Konflikt (eindeutige UUID-Prefixe verwenden)
- [ ] Cleanup-Fehler (File locked, Permission denied) → Warning geloggt, kein Crash
- [ ] Temp-Dir-Root konfigurierbar (z.B. Docker-Volume statt OS-Default)

---

## CREDENTIAL-FORWARDING (Third-Party-Credentials validieren)

> Für Konnektoren die Credentials von einer Plattform erhalten und gegen Third-Party-Services validieren.

**Validierungs-Pfade**
- [ ] Gültige Credentials (alle Pflichtfelder korrekt) → Action wird ausgeführt
- [ ] Ungültige Credentials → sofortiger Fehler VOR jeder Verarbeitung (kein Ressourcenverbrauch)
- [ ] Fehlende Credentials (null, undefined, leeres Objekt) → 400 mit klarer Nachricht, nicht 500
- [ ] Fehlende Pflichtfelder (z.B. Passwort vorhanden aber Username fehlt) → spezifischer Feldfehler
- [ ] Abgelaufene/gekündigte Lizenz → 403, nicht 401 oder 404
- [ ] Lizenz-Service nicht erreichbar → unterscheidbarer Fehler von "ungültige Credentials" (Service-Fehler vs. Auth-Fehler)

**Verschlüsselung**
- [ ] Verschlüsselte Credentials → korrekt entschlüsselt vor Validierung
- [ ] Entschlüsselung schlägt fehl (falsches Format, falscher Key) → klarer Fehler, kein Klartext-Fallback
- [ ] Nicht-verschlüsselte Credentials im Klartext → werden direkt verwendet (keine doppelte Entschlüsselung)

**Sicherheit**
- [ ] Credentials erscheinen NICHT in Logs oder Fehlermeldungen (assertieren mit Log-Spy!)
- [ ] Timing-Angriff-Schutz: Antwortzeit bei gültigen vs. ungültigen Credentials nicht signifikant unterschiedlich

---

## ACTION-COMPLETION (Connector-Job abschließen)

> Für den Abschluss-Flow eines Connector-Jobs: Ergebnis melden, Message bestätigen, Ressourcen freigeben.

**Erfolgs-Pfad**
- [ ] Erfolgreiche Verarbeitung → Success-Reply mit korrektem Payload gesendet (alle Pflichtfelder befüllt)
- [ ] Reply enthält korrekte Referenzen (conversationId, tenantId, action)
- [ ] Message wird nach Reply acknowledged
- [ ] Acknowledge passiert NACH dem Reply (Reihenfolge ist wichtig)

**Fehler-Pfad**
- [ ] Fehlerhafte Verarbeitung → Failure-Reply mit lesbarer Fehlermeldung gesendet
- [ ] Technischer vs. Business-Fehler → korrekt klassifiziert (isTechnicalError-Flag)
- [ ] Auch bei Fehler: Message acknowledged (kein "verlorenes" Message das endlos in der Queue liegt)
- [ ] Auch bei Fehler: Alle Ressourcen aufgeräumt (Temp-Files, Streams, Connections)

**Edge Cases**
- [ ] Reply-Senden schlägt fehl (Upstream-API down) → Job als fehlgeschlagen markiert, NICHT endlos retried
- [ ] Doppelter Acknowledge → idempotent, kein Fehler
- [ ] Acknowledge schlägt fehl → geloggt, Job wird nicht als erfolgreich gewertet
- [ ] Partielle Ausführung (Reply gesendet, Acknowledge schlägt fehl) → System-Zustand ist konsistent

---

## RETRY-LOGIC

> Für jede Komponente die automatische Wiederholungsversuche implementiert.

**Grundverhalten**
- [ ] Erster Versuch erfolgreich → kein Retry, kein Delay
- [ ] Retryable-Fehler (Timeout, 5xx, Connection Error) → retried nach konfiguriertem Delay
- [ ] Non-Retryable-Fehler (4xx außer 429, Validierungsfehler, Lizenzfehler) → NICHT retried, sofort fehlgeschlagen
- [ ] Unbekannter Fehler → Safety-Retry mit reduziertem Maximum (maximal 1–2 Versuche)

**Delay-Strategie**
- [ ] Exponentieller Backoff → Delay wächst korrekt (`base × 2^attempt`)
- [ ] Jitter → Delays sind nicht exakt gleich bei parallelen Retries (Thundering-Herd-Prevention)
- [ ] Max-Delay → Delay wird nach oben begrenzt (kein 30-Minuten-Delay nach 15 Retries)

**Abbruch-Bedingungen**
- [ ] Max-Retries erreicht → finaler Fehler geworfen mit Kontext aller Versuche
- [ ] Retry-Entscheidung wird korrekt geloggt (Versuch N von M, nächster Delay, Fehler-Grund)
- [ ] Nach Max-Retries: Job landet in Dead-Letter-Queue (falls vorhanden)

---

## RESOURCE-CLEANUP (Temp-Files, Connections, Prozesse)

> Für jedes Feature das temporäre Ressourcen erstellt.

**Temp-Files**
- [ ] Normale Beendigung → alle Temp-Dateien und -Verzeichnisse gelöscht
- [ ] Fehler-Beendigung (Exception, Reject) → alle Temp-Dateien und -Verzeichnisse gelöscht
- [ ] `withDir` / `withFile` Pattern → Cleanup passiert im `finally`-Block, nicht nur im `then`-Block
- [ ] Parallele Jobs → eindeutige Temp-Pfade (UUID-Prefix), kein gegenseitiges Überschreiben
- [ ] Langzeitbetrieb → kein unkontrolliertes Temp-Dir-Wachstum
- [ ] Partielle Cleanup (ein File kann nicht gelöscht werden) → Warning geloggt, kein Crash, restliche Cleanup weitergeführt

**Connections und Prozesse**
- [ ] Offene Streams → geschlossen nach Nutzung (auch bei Fehler)
- [ ] Browser/Child-Prozesse → terminiert und freigegeben nach Nutzung
- [ ] Verwaiste Prozesse (Orphan Chromium, Zombie Child) → Erkennungs- und Kill-Mechanismus getestet
- [ ] DB-Connections → nach Query zurück in den Pool oder geschlossen

**Graceful Shutdown**
- [ ] SIGTERM → Cleanup-Hooks werden ausgeführt, laufende Jobs beenden sich sauber
- [ ] SIGINT → gleich wie SIGTERM
- [ ] Keine neuen Jobs werden nach Shutdown-Signal angenommen
- [ ] Alle Pool-Ressourcen (Browser, DB-Connections) werden freigegeben

---

## OAUTH-TOKEN-LIFECYCLE

> Für Konnektoren die OAuth2-Tokens für Third-Party-APIs verwalten.

**Token-Beschaffung**
- [ ] Gültige Credentials → Token wird erfolgreich angefordert und gespeichert
- [ ] Ungültige Credentials → 401, kein Token gespeichert, kein Cache-Eintrag
- [ ] Token-Endpoint nicht erreichbar → klarer Fehler, kein leerer Token gecacht

**Caching**
- [ ] Gültiger Token im Cache → wird aus Cache geliefert, kein API-Call (mit Spy assertieren)
- [ ] Gültiger Token in DB aber nicht im Cache → wird aus DB geladen und in Cache gestellt
- [ ] Kein Token vorhanden → neuer Token angefordert, in DB UND Cache gespeichert
- [ ] Token abgelaufen im Cache → aus Cache entfernt, neuer Token angefordert

**Token-Refresh**
- [ ] Refresh-Token vorhanden und gültig → Token wird ohne Username/Password erneuert
- [ ] Refresh-Token abgelaufen → Fallback auf neuen Token-Request mit Credentials
- [ ] Token-Expiry aus JWT extrahiert → korrekte Ablaufzeit berechnet
- [ ] Proaktive Erneuerung → Token wird VOR Ablauf erneuert (konfigurierter Puffer, z.B. 2 Minuten)

**Sicherheit**
- [ ] Tokens werden verschlüsselt in der DB gespeichert (assertieren dass Klartext nicht in DB)
- [ ] Tokens erscheinen NICHT in Logs (Log-Spy verwenden)
- [ ] Cache ist per-Credential isoliert (Credential A bekommt nicht Token von Credential B)

---

## CONNECTION / RESOURCE POOLING

> Für Features die einen Pool von teuren Ressourcen verwalten (Browser-Instanzen, DB-Connections).

**Pool-Grundfunktionen**
- [ ] Acquire → Ressource wird bereitgestellt (neu erstellt oder aus Pool wiederverwendet)
- [ ] Release → Ressource wird in Pool zurückgegeben (nicht zerstört)
- [ ] Pool-Maximum erreicht → neue Anfragen warten oder werden mit Timeout abgelehnt (kein Hang)
- [ ] Ressource validiert vor Ausgabe → kaputte Ressource wird nicht ausgegeben

**Lifecycle**
- [ ] Idle-Timeout → ungenutzte Ressourcen werden nach Ablauf zerstört
- [ ] Min/Max-Pool-Size → werden respektiert
- [ ] Pool-Drain → keine neuen Ressourcen, bestehende werden nach Rückgabe zerstört

**Fehlerbehandlung**
- [ ] Ressourcen-Erstellung schlägt fehl (z.B. Chromium kann nicht starten) → klarer Fehler, Pool bleibt funktionsfähig
- [ ] Fallback-Mechanismus (z.B. Sandbox → No-Sandbox) → funktioniert und wird geloggt
- [ ] Ressource die zwischen Acquire und Use stirbt → Fehler wird sauber behandelt, Pool-Counter korrekt

---

## KONFIGURATION / ENVIRONMENT-VALIDIERUNG

> Für die Startup-Phase der Anwendung.

**Pflicht-Werte**
- [ ] Alle Pflicht-Environment-Variablen gesetzt → Anwendung startet korrekt
- [ ] Pflicht-Variable fehlt → sofortiger, klarer Fehler beim Start (nicht erst bei Runtime)
- [ ] Pflicht-Variable ist leerer String → wird wie fehlend behandelt

**Fallback-Ketten**
- [ ] Primäre Variable gesetzt → wird verwendet
- [ ] Primäre fehlt, Fallback gesetzt → Fallback wird verwendet
- [ ] Beide fehlen → Default-Wert wird verwendet (wenn definiert) oder Fehler (wenn kein Default)

**Typ-Validierung**
- [ ] Numerische Config mit nicht-numerischem Wert → Fehler oder dokumentierter Default
- [ ] Boolean-Config (`'true'`/`'false'` als String) → korrekt geparst
- [ ] URL ohne Protokoll → automatisch korrigiert oder Fehler (dokumentiertes Verhalten)

**Sicherheit**
- [ ] Keine Secrets in der Default-Konfiguration (leerer String, nicht `'default-secret'`)
- [ ] Keine Secrets in Startup-Logs (assertieren mit Log-Spy)
- [ ] Encryption-Secret fehlt → Verschlüsselungsfunktionen werfen sofort Fehler beim Start

---

## GRACEFUL SHUTDOWN / HEALTH-CHECK

> Für die saubere Beendigung der Anwendung und Betriebsbereitschaft.

**Health-Check**
- [ ] Alle Abhängigkeiten erreichbar → Health-Endpoint gibt 200 + Status pro Abhängigkeit zurück
- [ ] Eine Abhängigkeit nicht erreichbar (z.B. MongoDB, externe API) → Health-Endpoint gibt degraded/unhealthy zurück
- [ ] Health-Check hat eigenes Timeout (hängt nicht an langsamer Abhängigkeit fest)
- [ ] Health-Endpoint gibt Schema-Version und Connector-Version zurück (Debugging-Aid)

**Graceful Shutdown**
- [ ] SIGTERM empfangen → keine neuen Requests/Jobs akzeptiert
- [ ] Laufende Requests/Jobs → werden sauber zu Ende geführt
- [ ] Pool-Ressourcen (Browser, DB) → werden nach Drain freigegeben
- [ ] Shutdown-Timeout → wenn Jobs nicht innerhalb von X Sekunden beenden → Force-Kill
- [ ] Verwaiste Child-Prozesse → werden bei Shutdown mit SIGKILL bereinigt

**Startup**
- [ ] Abhängigkeiten nicht verfügbar beim Start → definiertes Verhalten (Retry, Crash, degraded)
- [ ] BrowserPool wird beim Start vorinstanziiert (nicht erst beim ersten Request)
- [ ] Doppelter Start (Port bereits belegt) → klarer Fehler, kein stiller Fail

---

## QUEUE-INTEGRITÄT (Neu in v1.2.0)

> Für Agenda/MongoDB-basierte Queues. Das häufigste Produktionsrisiko in Connector-Projekten: ein Job der halbfertig ausgeführt wurde und beim Retry einen inkonsistenten Zustand verursacht.

**Job-Payload-Integrität**
- [ ] Job-Payload bleibt zwischen Einreihen und Ausführung unverändert (kein stiller Datenverlust durch Serialisierung/Deserialisierung)
- [ ] Job mit großem Payload (> MongoDB-Dokumentlimit) → klarer Fehler beim Einreihen, kein stiller Fail
- [ ] Job-Payload enthält keine Circular-References (würde Serialisierung kaputt machen)

**Locking und Nebenläufigkeit**
- [ ] Zwei Worker nehmen nicht denselben Job (Mongo-Lock ist aktiv — testen mit zwei parallelen Worker-Instanzen)
- [ ] Job wird nach erfolgreichem Acknowledge aus der Queue entfernt (kein Phantom-Job bleibt)
- [ ] Job bleibt in der Queue wenn Acknowledge fehlschlägt (kein verlorener Job)
- [ ] Job-Priorität wird respektiert wenn mehrere Jobs gleichzeitig bereitstehen

**Idempotenz**
- [ ] Derselbe Job zweimal ausgeführt (durch doppelten Webhook oder manuellen Retry) → Ergebnis ist korrekt, kein doppelter Upload, kein doppelter Reply
- [ ] Idempotenz-Schlüssel: wenn vorhanden, zweite Ausführung wird erkannt und übersprungen

**Stale Jobs und Recovery**
- [ ] QueueRecovery findet steckengebliebene Jobs (Job länger als X Minuten "in-progress") → wird als stale markiert
- [ ] Stale Job wird erneut gestartet (Recovery-Mechanismus aktiv)
- [ ] Recovery ist selbst idempotent: mehrfache Recovery-Läufe korrumpieren keine Daten
- [ ] Recovery unterscheidet zwischen "stale wegen Server-Crash" und "stale wegen Bug" (Max-Recovery-Versuche)

**Queue-Hygiene**
- [ ] Queue wächst nicht unkontrolliert: QueueCleanup entfernt abgeschlossene Jobs nach konfigurierter TTL
- [ ] Failed Jobs nach Max-Retries: landen in Dead-Letter-Queue oder werden als permanent-fehlgeschlagen markiert
- [ ] Queue-Monitoring: Queue-Tiefe und Lag sind observierbar (Health-Check enthält Queue-Stats)

---

## CONNECTOR-LIFECYCLE (Neu in v1.2.0)

> Für den vollständigen Lebenszyklus eines Connectors: Startup, Betrieb, Deployment, Shutdown.

**Startup-Validierung**
- [ ] Alle Pflicht-Services erreichbar (MongoDB, Queue) → Connector meldet sich als "ready"
- [ ] MongoDB nicht erreichbar beim Start → Connector startet NICHT (kein stiller Fail, klarer Exit-Code)
- [ ] `definition.json` fehlt oder ist ungültig (kein valides JSON) → Connector startet NICHT
- [ ] BrowserPool-Initialisierung schlägt fehl (kein Chromium verfügbar) → definiertes Verhalten (Crash oder degraded je nach Konfiguration)
- [ ] Encryption-Secret fehlt → Connector startet NICHT (Verschlüsselung ist Pflicht)

**Deployment-Sicherheit (Coolify / Docker)**
- [ ] SIGTERM beim Deployment → laufende Jobs werden sauber zu Ende geführt, dann Exit
- [ ] Neues Docker-Image deployen während Jobs aktiv sind → Jobs der alten Instanz werden nicht abgebrochen
- [ ] Rollback: alte Connector-Version gegen neue MongoDB-Schemas → kein Absturz (Vorwärts-Kompatibilität)
- [ ] Zero-Downtime-Deploy: neue Instanz ist "ready" bevor alte Instanz SIGTERM empfängt

**Versionierung**
- [ ] Health-Endpoint gibt Connector-Version zurück (aus `package.json`)
- [ ] Connector-Version wird beim Start geloggt
- [ ] `definition.json`-Version und Code-Version sind synchron (Test schlägt fehl wenn sie auseinanderlaufen)

---

## DEFINITION.JSON CONTRACT-TESTS (Neu in v1.2.0)

> Für alle Connector-Projekte mit einer `definition.json`. Das Manifest des Connectors — eine Änderung hier kann die gesamte Plattform-Integration brechen.

**Handler-Registry-Konsistenz**
- [ ] Jede Action in `definition.json` hat einen korrespondierenden Handler in `handlerRegistry` (kein toter Eintrag in der Definition)
- [ ] Jeder Handler in `handlerRegistry` ist in `definition.json` deklariert (kein undokumentierter Handler)
- [ ] Mapping-Test: `handlerRegistry.getHandler(actionName)` gibt für jeden deklarierten Action-Namen einen validen Handler zurück
- [ ] Mapping-Test: `handlerRegistry.getHandler("nicht-existierender-name")` gibt `null`/`undefined` zurück und crasht nicht

**Schema-Integrität**
- [ ] Jedes Credential-Feld das in `definition.json` deklariert ist, wird im Code tatsächlich gelesen
- [ ] Jedes Input-Feld das in `definition.json` als `required: true` markiert ist, wird im Code validiert
- [ ] Jedes Enum/Choice-Feld in `definition.json` hat für jeden deklarierten Wert eine Code-Implementierung

**Breaking-Change-Detection**
- [ ] Snapshot-Test der `definition.json`: wenn sich das Schema ändert, schlägt der Test fehl und erzwingt bewusste Bestätigung
- [ ] Neues Pflichtfeld in Action-Schema → bestehende Payloads ohne dieses Feld → klarer Validierungsfehler
- [ ] Umbenannte Action → alter Name gibt 404 oder sprechenden Fehler zurück (keine stille Fehlverarbeitung)

**Payload-Validierung**
- [ ] Eingehender Webhook-Payload wird gegen das Action-Schema validiert BEVOR der Handler aufgerufen wird
- [ ] Unbekannte Felder im Payload → ignoriert (kein Crash), bekannte Felder korrekt verarbeitet
- [ ] Payload-Validierungsfehler → klarer 400-Fehler mit Feld-spezifischer Fehlermeldung

---

## FEHLERKLASSIFIZIERUNG (Neu in v1.2.0)

> Systemübergreifende Konsistenz der Fehlerbehandlung. Fehler müssen korrekt klassifiziert und sicher kommuniziert werden.

**ErrorReply-Struktur**
- [ ] Jede Action sendet bei Fehler einen strukturierten ErrorReply (kein leerer Body, kein roher Stack-Trace)
- [ ] ErrorReply enthält: Fehler-Typ, lesbare Fehlermeldung, keine Secrets
- [ ] Unterscheidung USER_ERROR (ungültige Eingabe → kein Retry sinnvoll) vs. SYSTEM_ERROR (externer Fehler → Retry möglich)
- [ ] `isTechnicalError: true` bei SYSTEM_ERROR → Fluks-Plattform kann retry-Logik anwenden
- [ ] `isTechnicalError: false` bei USER_ERROR → kein automatischer Retry

**Keine Secrets in Fehlern**
- [ ] Fehler-Payload enthält KEINE API-Keys, Tokens, Lizenzschlüssel oder Passwörter (assertieren mit Log-Spy und Response-Inspektion)
- [ ] Stack-Traces werden in Produktions-Logs unterdrückt oder sanitized
- [ ] MongoDB-Fehlermeldungen werden vor Weitergabe an den Client sanitized (kein Leak von DB-Struktur)

**Logging-Konsistenz**
- [ ] Winston-Logs enthalten bei jedem Fehler: Action-Name, TenantId (gehashed oder truncated), Fehler-Typ, Fehler-Message
- [ ] Winston-Logs enthalten bei keinem Fehler: API-Keys, Tokens, Passwörter, volle Credential-Objekte
- [ ] Unerwartete Exceptions (nicht abgefangene Promises) → landen in globalem `unhandledRejection`-Handler, kein Process-Crash
- [ ] Globaler Error-Handler loggt den Fehler und sendet einen generischen ErrorReply

**Fehler-Propagation**
- [ ] Fehler aus httpClient → korrekt in Action-Fehler gewrappt (kein roher Axios-Error nach außen)
- [ ] Fehler aus Stirling-API → enthalten HTTP-Status und Body in der Fehlermeldung (für Debugging)
- [ ] Fehler aus MongoDB → enthalten Fehler-Code aber keine DB-Struktur oder Query-Details