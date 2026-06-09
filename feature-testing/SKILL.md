---
version: 1.2.0
changelog: |
  1.0.0 — Initiale Version (Phasen, Gates, Zero-Fail-Zones, Basis-Patterns)
  1.1.0 — 10 Connector/Integration-Patterns ergänzt (HTTP-Client, File-Pipeline, Retry, OAuth, Pooling, Config, Shutdown)
  1.2.0 — Generisch für alle GitHub-Projekte optimiert: Änderungsanalyse, Auto-Fix-Loop, TypeScript-Gates,
           Queue-Integrität, Connector-Lifecycle, Definition.json Contract-Tests, Fehlerklassifizierung,
           API-Key-Auth-Anpassung, Projekt-Kontext-Protokoll
name: feature-testing
description: >
  Enterprise-Testautomatisierung für jedes neue Feature auf jedem Connector/Integration-Projekt.
  Diesen Skill verwenden wann immer ein neues Feature, ein Endpoint, eine Service-Komponente,
  eine Business-Logic-Änderung oder ein Bug-Fix implementiert wird — auf JEDEM GitHub-Repo.
  Der Skill führt den Coding-Agent durch Änderungsanalyse, Teststrategie, Implementierung,
  Auto-Fix-Loop, Quality Gates und Freigabe. Ziel: 1 Prompt → Feature analysiert → Tests generiert
  → Bugs erkannt → Bugs gefixt → Bugfrei ausgeliefert. Für JEDE Code-Änderung die Produktions-Pfade
  berührt verwenden — nicht nur für "große" Features. Erzwingt Zero-Bug-Delivery auf kritischen
  Systemen und risikobasierte Abdeckung überall sonst.
---

# Feature-Testing Skill — Enterprise Zero-Bug-Standard v1.2.0

## KERNPHILOSOPHIE

> **Coverage ist eine Eitelkeits-Metrik. Verhaltensnachweis ist das Ziel.**
> Ein Test der jede Zeile aufruft aber nichts assertiert ist schlimmer als kein Test — er erzeugt falsches Vertrauen.
> Jeder Test muss genau EIN konkretes Verhalten beweisen. Wenn er bestehen kann während das Feature kaputt ist — löschen.

**Du bist nicht fertig wenn Tests grün sind. Du bist fertig wenn Bugs sich nicht mehr verstecken können.**

---

## PROJEKT-KONTEXT PROTOKOLL (Vor Phase 1 — bei jedem neuen Repo)

Bevor der Skill auf einem neuen GitHub-Repository gestartet wird, diese Informationen ermitteln und dokumentieren. Ohne diesen Kontext sind alle nachfolgenden Phasen unvollständig.

```
PROJEKT-KONTEXT:
1. Projektname & Repo-URL:     [z.B. domoPDF Fluks Connector]
2. Third-Party-API(s):         [z.B. Stirling PDF API / Salesforce / Google Drive]
3. Auth-Modell:                [API-Key / OAuth2 / Lizenzkey / kombiniert]
4. Queue-Technologie:          [Agenda/MongoDB / Bull/Redis / direkt / keine]
5. Datenbank:                  [MongoDB / PostgreSQL / keine]
6. Actions/Features:           [Liste aller Actions oder Hauptfunktionen]
7. Besondere Risiken:          [z.B. "verarbeitet sensible Dokumente" / "sendet E-Mails"]
8. definition.json vorhanden:  [JA / NEIN]
9. Tech-Stack:                 [TypeScript/Node.js / Python / etc.]
```

Wenn Informationen fehlen: aus `package.json`, `definition.json`, `src/config.ts` und `README.md` extrahieren.

---

## PHASE 0 — ÄNDERUNGSANALYSE (Neu in v1.2.0 — vor Phase 1 ausführen)

> **Zweck:** Bevor ein einziger Test geschrieben wird, präzise verstehen was sich geändert hat und welche bestehenden Tests davon betroffen sind.

### 0.1 Geänderte Dateien identifizieren

```bash
# Alle geänderten Dateien seit letztem Commit / PR-Branch-Punkt
git diff --name-only HEAD~1
# oder für einen PR:
git diff --name-only origin/main...HEAD
```

### 0.2 Auswirkungsanalyse für jede geänderte Datei

Für jede geänderte Datei diese Fragen beantworten:

- **Direkte Aufrufer:** Welche anderen Dateien importieren diese Datei?
- **Indirekte Konsumenten:** Welche Flows laufen durch diese Datei?
- **Shared State:** Verändert diese Datei globalen Zustand, Cache, DB-Schema?
- **Externe Contracts:** Verändert diese Datei eine API-Schnittstelle die andere Systeme (Fluks, Third-Party) konsumieren?

### 0.3 Bestehende Tests auf Betroffenheit prüfen

```bash
# Alle Tests finden die die geänderten Module importieren
grep -r "from.*[geändertes-modul]" tests/
```

- Bestehende Tests die betroffen sind: **explizit auflisten**
- Bestehende Tests die fehlschlagen könnten: **vor dem Schreiben neuer Tests ausführen**
- Baseline etablieren: Welche Tests waren VOR der Änderung grün?

### 0.4 Regressions-Risiko einschätzen

| Risiko-Level | Situation | Konsequenz |
|--------------|-----------|------------|
| 🔴 HOCH | Shared Utility / Middleware / Auth geändert | Alle Tests ausführen, nicht nur neue |
| 🟡 MITTEL | Service oder Controller geändert | Tests aller abhängigen Flows ausführen |
| 🟢 NIEDRIG | Neue isolierte Action hinzugefügt | Nur neue Tests + Smoke-Test der Integration |

---

## PHASE 1 — FEATURE-ANALYSE (Vor dem ersten Test ausführen)

### 1.1 Das Feature vollständig verstehen

Vor dem Schreiben von Tests diese Fragen beantworten (Code, Spec oder Ticket lesen):

- Was ist der **primäre Happy Path**? (Das Eine was dieses Feature tun muss)
- Was sind die **Eingaben**? (Typen, Bereiche, Quellen — Benutzereingabe, DB, externe API, Event)
- Was sind die **Ausgaben**? (Rückgabewerte, DB-Schreibvorgänge, ausgelöste Events, Seiteneffekte)
- Welche **externen Abhängigkeiten** werden berührt? (DB, Cache, Queue, Third-Party-API, Auth-System)
- Welchen **geteilten Zustand** verändert es? (Tabellen, globale Config, Session, Cache)
- Welche **bestehenden Features** könnte es kaputt machen? (Alle Aufrufer und Konsumenten suchen)

> ⚠️ **FAIL-FAST-REGEL**: Wenn diese Fragen nicht aus Code + Spec beantwortet werden können — **STOP**.
> Keine Tests gegen unklare Specs schreiben. Unklare Spec = undefiniertes Verhalten = bedeutungslose Tests.
> Klärung anfordern. Unbekanntes dokumentieren. Feature blocken bis die Spec klar ist.

**SPEC-GAP-Konvention:** Wenn ein Verhalten gefordert aber NICHT in Spec/Ticket/Code definiert ist:
- Das erwartete Verhalten NICHT erfinden
- KEINEN Test mit angenommenem Verhalten schreiben
- Explizit markieren: `// SPEC GAP: [beschreiben was undefiniert ist]`
- Alle SPEC GAPs im abschließenden Test-Report auflisten
- Feature mit ungelösten SPEC GAPs in kritischen Pfaden → automatisches BLOCKIERT-Urteil

### 1.2 Feature klassifizieren (PFLICHT)

Ein **Risiko-Tier** zuweisen — dieser bestimmt die erforderliche Testtiefe:

| Tier | Gilt wenn | Testtiefe |
|------|-----------|-----------|
| **NO-FAIL** | Auth/API-Key-Validierung, Credential-Forwarding, Datenschutz, Verschlüsselung, Datenmigrationen | Erschöpfend: alle Pfade inkl. Missbrauch, Rollback, Nebenläufigkeit |
| **LOW-FAIL** | Kern-Business-Logik, Actions, Queue-Jobs, Schreibvorgänge, Integrationen, File-Pipeline | Risikobasiert: Happy Path + alle realistischen Fehlermodi |
| **BEST-EFFORT** | Rein lesende Endpoints, Health-Checks, unkritische Logging-Änderungen | Smoke-Test + Happy Path |

> 🚨 **NO-FAIL-Domänen sind nicht verhandelbar.** Siehe `./zero-fail-zones.md` für vollständige Prüflisten pro Domäne.

**Connector-spezifische Tier-Defaults:**

| Komponente | Default-Tier |
|------------|-------------|
| `middleware/auth.ts`, `licenseService.ts` | NO-FAIL |
| `utils/encryption.ts`, `credentialHelper.ts` | NO-FAIL |
| Datenbank-Migrationen | NO-FAIL |
| `src/actions/*.ts` (Action-Handler) | LOW-FAIL |
| `utils/httpClient.ts`, `retryDecider.ts` | LOW-FAIL |
| `services/oAuthService.ts` | LOW-FAIL |
| `queue/QueueRecovery.ts` | LOW-FAIL |
| `config.ts` (Startup-Validierung) | LOW-FAIL |
| `controllers/healthController.ts` | BEST-EFFORT |

### 1.3 Alle testbaren Verhaltensweisen identifizieren

Jedes Verhalten das das Feature zeigen muss auflisten. Format:
```
GEGEBEN  [Vorbedingung]
WENN     [Aktion]
DANN     [beobachtbares Ergebnis]
```

Diese Liste wird zu den Testfällen. Wenn kein GEGEBEN/WENN/DANN formuliert werden kann — kein testbares Requirement. Spec klären.

**Spec-Referenz-Tagging:** Wenn ein formales Spec-Dokument, Ticket oder Anforderungsdokument existiert, jeden Test mit seiner Quelle versehen:
```typescript
// SPEC: [Ticket-ID oder Spec-Abschnitt] — [einzeilige Zusammenfassung]
it("gibt 403 zurück wenn Lizenz abgelaufen ist", ...) // SPEC: TICKET-142

// INFERIERT: [Verhaltensannahme beschreiben — bei reinem Code-Kontext]
it("retried nicht bei 401", ...) // INFERIERT: 401 = ungültige Credentials, Retry macht es nicht besser
```

---

## PHASE 2 — TESTSTRATEGIE

Tests in dieser Reihenfolge schreiben. Schichten nicht überspringen um Zeit zu sparen.

### Schicht 1: Unit-Tests (immer erforderlich)

**Regel:** Jede Funktion/Methode die Logik enthält bekommt Unit-Tests. Reine I/O-Durchleitungsfunktionen sind ausgenommen.

Pflichtfälle pro Funktion:
1. Happy Path mit gültigen Eingaben
2. Alle Grenzwerte (min, max, leer, null/undefined, Strings maximaler Länge)
3. Alle expliziten Fehlerpfade (Exceptions, Fehler-Returns)
4. Jeder Bedingungszweig (jeder `if`-Zweig muss einen Test haben)

**Qualitätsregel:** Echte Assertions auf Ausgabewerte verwenden. `expect(ergebnis).toBe(42)` — nicht nur `expect(fn).not.toThrow()`.

### Schicht 2: Integrations-Tests (immer erforderlich wenn Feature DB/API/Queue berührt)

**Regel:** Feature End-to-End innerhalb der Service-Grenze testen (echte DB, gemockte externe APIs).

Pflichtfälle:
1. Vollständiger Happy Path durch alle Schichten (Controller → Service → Repository → DB)
2. DB-Constraint-Verletzungen (Unique, Foreign Key, Not-Null)
3. DB-Transaktions-Rollback bei Fehler (Schreibvorgang schlägt auf halbem Weg fehl — DB muss unverändert sein)
4. Nebenläufige Schreibsicherheit (zwei Requests ändern denselben Datensatz gleichzeitig)
5. Ausfall externer Abhängigkeit (was passiert wenn die externe API down/langsam/fehlerhafte Daten liefert)

**Isolationsregel:** Jeder Integrationstest muss von einem bekannten DB-Zustand starten. Transaktionen oder Truncate verwenden. Tests dürfen nicht von der Ausführungsreihenfolge abhängen.

### Schicht 3: Contract-Tests (erforderlich wenn Feature eine API exponiert oder konsumiert)

Wenn das Feature einen API-Endpoint **exponiert**:
- Jedes Feld im Request-Schema testen (fehlendes Pflichtfeld, falscher Typ, zusätzliches Feld)
- Jeden HTTP-Statuscode testen den der Endpoint zurückgeben kann
- Response-Schema testen — jeden Feldnamen, Typ, Nullability

Wenn das Feature eine externe API **konsumiert**:
- Testen was passiert wenn die externe API 4xx, 5xx, Timeout, fehlerhaftes JSON zurückgibt
- Contract-Test schreiben der verifiziert dass der Stub der echten API-Form entspricht

**Definition.json Contract-Tests (für Connector-Projekte mit `definition.json`):**
- Jede Action in `definition.json` hat einen korrespondierenden Handler in `handlerRegistry`
- Jeder Handler in `handlerRegistry` ist in `definition.json` deklariert
- Alle Enum/Choice-Werte in `definition.json` sind im Code implementiert
- Jedes Credential-Feld in `definition.json` wird im Code tatsächlich genutzt
- Vollständige Prüfliste: siehe `./test-patterns.md` → Abschnitt DEFINITION.JSON CONTRACT-TESTS

### Schicht 4: End-to-End-Tests (erforderlich für NO-FAIL; empfohlen für LOW-FAIL)

- Vollständige User Journey durch das System testen (echtes HTTP → echte DB)
- Minimum: ein vollständiger Happy Path, ein kritischer Fehlerpfad
- Für Connector-Projekte: vollständiger Webhook→Queue→Action→Reply Flow
- Für NO-FAIL-Features: alle adversarialen Pfade (siehe `./zero-fail-zones.md`)

### Schicht 5: Performance-Baseline (erforderlich für NO-FAIL; prüfen für LOW-FAIL)

Jedes Feature das eine neue DB-Abfrage oder einen externen Aufruf hinzufügt benötigt:
- Assertion auf Query-Ausführungszeit (akzeptable Schwelle basierend auf SLA definieren)
- Prüfung auf N+1-Query-Muster (Queries in Tests loggen, Query-Anzahl ≤ erwartet assertieren)
- Load-Test für hochfrequente Endpoints: p95-Antwortzeit unter erwarteter Concurrent-Last assertieren

### Test-Pyramid-Gesundheitscheck

Nach dem Schreiben der Tests die Verteilung prüfen:

| Schicht | Zielbereich | Warnsignal |
|---------|-------------|------------|
| Unit-Tests | 60–80% der Gesamttests | Unter 50%: zu viele Integrationstests, langsame CI, fragile Suite |
| Integrations-Tests | 15–30% | Über 40%: Integrationstests machen Unit-Test-Arbeit → aufteilen |
| E2E-Tests | 5–10% | Über 15%: E2E-Suite wird Wartungsalptraum |

> **Das ist eine Gesundheitsrichtlinie, keine harte Regel.** Connector-Projekte sind I/O-heavy — 50% Unit / 40% Integration / 10% E2E ist akzeptabel und muss im Report begründet werden. Eine invertierte Pyramide (mehr E2E als Unit) ist immer ein Red Flag.

**Dateistruktur:** Testdateien spiegeln die Source-Struktur:
```
src/
  actions/ConvertHTMLToPDF.ts
tests/
  unit/actions/ConvertHTMLToPDF.test.ts
  integration/actions/ConvertHTMLToPDF.flow.test.ts
  e2e/flows/htmlToPdf.e2e.test.ts
```
Eine Source-Datei = eine Unit-Testdatei. Integrations- und E2E-Dateien decken Flows ab, keine einzelnen Dateien.

---

## PHASE 3 — IMPLEMENTIERUNGSREGELN

Diese Regeln sind nicht verhandelbar. Ein Test der sie verletzt ist kein gültiger Test.

### 3.1 Test-Benennung

Jeder Testname muss ein vollständiger Satz sein der das erwartete Verhalten beschreibt:
```typescript
✅ "gibt 401 zurück wenn API-Key fehlt"
✅ "räumt Temp-Files auf wenn Stirling-API 500 zurückgibt"
✅ "retried nicht bei 401 (ungültige Credentials)"
❌ "auth testen"
❌ "sollte funktionieren"
❌ "test1"
```

### 3.2 Arrange-Act-Assert-Struktur

Jeder Test muss AAA strikt einhalten — keine Logik zwischen den Abschnitten:
```typescript
// ARRANGE — Zustand, Mocks, Eingaben vorbereiten
const mockMsg = buildActionMessage({ credentials: validCredentials });
jest.spyOn(licenseService, 'checkLicense').mockResolvedValue({ valid: true });

// ACT — genau eine Sache aufrufen
const result = await handleConvertHTMLToPDF(mockMsg);

// ASSERT — genau ein Ergebnis verifizieren
expect(result.type).toBe('ActionReply');
expect(result.payload.DownloadPermitToken).toBeDefined();
```

Ein Test = ein Verhalten. Tests aufteilen wenn zwei Assertions für zwei verschiedene Verhaltensweisen geschrieben werden.

### 3.3 Kein geteilter veränderlicher Zustand zwischen Tests

- Keine globalen Variablen die in Tests verändert werden
- Kein Test der davon abhängt dass ein anderer Test zuerst läuft
- Jeder Test setzt seine eigenen Vorbedingungen auf
- MongoDB: `beforeEach` mit `deleteMany({})` oder Transaktions-Rollback

### 3.4 Keine Flaky Tests — null Toleranz

Ein flaky Test (mal bestanden, mal fehlgeschlagen) ist **schlimmer als kein Test**. Er:
- Zerstört das Vertrauen in die Test-Suite
- Maskiert echte Fehler
- Trainiert Entwickler dazu, rote CI zu ignorieren

Bei einem flaky Test: **Grundursache beheben oder Test löschen**. Kein `retry(3)` hinzufügen.

Häufige Quellen von Flakiness die zu eliminieren sind:
- `setTimeout` / `sleep` in Tests (deterministische Zeit-Mocks verwenden)
- Race Conditions (korrektes async/await verwenden, kein fire-and-forget)
- Externe API-Aufrufe (alle externen Aufrufe mocken)
- Nicht-isolierter DB-Zustand (Transaktionen oder Cleanup-Hooks verwenden)
- Nicht-eindeutige Temp-Dir-Pfade (UUID-Prefix für jeden Test)

### 3.5 Testdaten-Regeln

- Niemals Produktionsdaten in Tests verwenden
- Niemals echte Lizenzkeys, API-Keys oder Tokens in Test-Fixtures
- Niemals IDs hardcoden — Factories/Builder verwenden die Testdaten generieren
- Testdaten offensichtlich fake machen: `email: "test-${uuid}@beispiel-test.invalid"`
- Für NO-FAIL-Domänen: adversariale Daten testen (SQL-Injection, XSS-Payloads, Unicode-Grenzfälle)

### 3.6 Mock-Strategie

| Abhängigkeitstyp | Mock-Strategie |
|-----------------|----------------|
| Fluks-API (externe Plattform) | Immer mocken — deterministischer Stub |
| Third-Party-API (Stirling, Salesforce, etc.) | Immer mocken — deterministischer Stub |
| MongoDB / Datenbank | Echte Test-DB (In-Memory mongodb-memory-server oder isolierter Container) |
| Agenda Queue | Echte Test-DB oder deterministischer Stub je nach Testschicht |
| Zeit / Datum | Immer mocken — niemals `new Date()` in Tests (`jest.useFakeTimers()`) |
| Filesystem / Temp-Files | Echtes Filesystem mit eindeutigem Temp-Dir pro Test |
| Zufall / UUID | Für deterministische Tests mocken |
| Encryption | Echte Implementierung — niemals mocken (sonst testet man den Mock) |
| Logger / Winston | SpyOn zum Assertieren — nie die eigentliche Log-Infrastruktur |

**Anti-Mock-Overuse-Regel:** Zu viel Mocking ist genauso gefährlich wie keine Tests.

- Wenn ein Unit-Test mehr als 3 Abhängigkeiten mockt: stoppen und fragen warum. Entweder hat der Code zu viele Abhängigkeiten (Design-Problem), oder es sollte ein Integrationstest geschrieben werden.
- Den zu testenden Code selbst niemals mocken
- Value Objects, DTOs oder reine Datenstrukturen niemals mocken
- Wenn ein Test nur assertiert dass ein Mock aufgerufen wurde: mindestens eine Assertion auf den tatsächlichen Output/Seiteneffekt hinzufügen

---

## PHASE 4 — TEST-QUALITY-GATES

Vor dem Abschließen der Tests alle diese Prüfungen durchführen:

### Gate 1: Verhaltens-Vollständigkeits-Check

Für jedes Verhalten aus der GEGEBEN/WENN/DANN-Liste aus Phase 1:
- [ ] Es gibt mindestens einen Test der **fehlschlagen** würde wenn dieses Verhalten kaputt ist
- [ ] Der Testname macht das Verhalten offensichtlich
- [ ] Die Assertion prüft den tatsächlichen beobachtbaren Output (nicht nur "keine Exception")

### Gate 2: Negativpfad-Abdeckung

Für jede Eingabe: existiert ein Test für jedes dieser Szenarien?
- [ ] Fehlendes Pflichtfeld
- [ ] Eingabe genau am Grenzwert (max-1, max, max+1)
- [ ] Eingabe falschen Typs
- [ ] Böswillige Eingabe (bei User-supplied): Injection, Overflow, Unicode, leerer String, nur Leerzeichen
- [ ] null und undefined explizit getestet (TypeScript schützt nicht zur Laufzeit bei Any-Casts)

### Gate 3: Fehlermodus-Abdeckung

Für jede externe Abhängigkeit:
- [ ] Abhängigkeit nicht verfügbar (Connection refused)
- [ ] Abhängigkeit antwortet nicht (Timeout)
- [ ] Abhängigkeit liefert unerwartete Daten (fehlerhaftes JSON, falsches Schema)

Für jeden Schreibvorgang:
- [ ] Was passiert wenn er auf halbem Weg scheitert? Ist das System in einem konsistenten Zustand?
- [ ] Sind Temp-Files auch bei Fehler aufgeräumt?

### Gate 4: Test-Unabhängigkeits-Verifikation

Tests in zufälliger Reihenfolge ausführen. Tests isoliert ausführen. Beide müssen identische Ergebnisse liefern.

```bash
# Jest mit zufälliger Reihenfolge
npx jest --randomize
```

### Gate 5: Regressions-Anker

Für jeden Bug-Fix: es muss einen Test geben der den Bug reproduziert (schlägt vor dem Fix fehl, besteht nach dem Fix).
Benennung: `"regression: [Bug-Beschreibung] (behebt #<issue-id>)"`.

### Gate 6: Redundanz-Check

Jeder Test muss ein **einzigartiges Risiko** abdecken. Vor dem Abschluss alle Tests scannen:

- Schlägt dieser Test aus einem anderen Grund fehl als jeder andere Test? Wenn zwei Tests gleichzeitig für denselben Bug fehlschlagen würden → einer ist redundant, löschen.
- Gibt es Tests die Copy-Paste-Variationen mit trivial anderen Eingaben sind aber keinen neuen Fehlermodus prüfen? Durch parametrisierte/tabellengesteuerte Tests ersetzen.
- Gibt es Tests die nur existieren um eine Coverage-Zahl zu erfüllen? Löschen.

> **Regel:** Jeder Test = ein einzigartiger Fehlermodus. Wenn das Löschen eines Tests das Vertrauen in kein konkretes Verhalten reduziert — löschen.

### Gate 7: Assertions-Qualitäts-Check

Für jede Assertion in der Test-Suite:
- [ ] Assertion ist spezifisch: `expect(result.status).toBe(403)` nicht `expect(result).toBeTruthy()`
- [ ] Fehlermeldungen werden validiert: `expect(err.message).toContain("Lizenz abgelaufen")` — nicht nur dass ein Fehler geworfen wurde
- [ ] Negative Assertions existieren für alle Fehlerpfade: `expect(tempDir).not.toExist()` nach Cleanup
- [ ] Keine Assertion prüft den Mock selbst als primären Beweis (Mock-Assertion = unterstützende Evidenz, nicht Hauptbeweis)
- [ ] **Mock-Only-Lösch-Gate:** Eine Assertion, die *nur* prüft, dass ein Mock aufgerufen wurde (z.B. `toHaveBeenCalled`-Familie), **ohne** danebenstehende Assertion auf echtes Verhalten (Rückgabewert / State / Datei / HTTP-Body / emittiertes Event-Payload) → **löschen**. Sie kann grün sein, während das Feature kaputt ist. Behalten nur, wenn echtes Verhalten zusätzlich geprüft wird, oder bei bewusster Negativ-Assertion (`not.toHaveBeenCalled()` + Beleg, dass das Feature trotzdem erfolgreich war). *Stack-agnostisch — `toHaveBeenCalled` ist das Jest-Beispiel; gilt sinngemäß für jedes Mock-Framework.*
- [ ] **Kein test-only-Code in Produktionsklassen** — Methoden, die nur Tests aufrufen (`reset/destroy/seed/clear/_forTest`), gehören in Test-Utilities, nicht in Produktionsklassen (Symbol-Referenz-Analyse, nicht String-Grep)

### Gate 8: TypeScript-Qualitäts-Check (Neu in v1.2.0)

Vor der Freigabe diese statischen Checks ausführen:

```bash
# TypeScript Typ-Fehler
npx tsc --noEmit

# ESLint
npx eslint src/ tests/ --max-warnings 0

# Auf floating Promises prüfen (häufige Fehlerquelle in Connector-Projekten)
# Regel: @typescript-eslint/no-floating-promises muss enabled sein
```

Pflicht-Checks:
- [ ] `tsc --noEmit` fehlerfrei — keine Typ-Fehler
- [ ] `eslint` fehlerfrei — keine Lint-Fehler, keine Warnings
- [ ] Alle Promise-Returns sind korrekt awaited (kein floating Promise)
- [ ] Alle `catch`-Blöcke fangen typisierte Fehler (`catch (err: unknown)` + Type-Guard)
- [ ] Kein `as any` in neuem Code ohne expliziten Kommentar warum
- [ ] `strict: true` in tsconfig.json aktiv — keine impliziten `any`

---

## PHASE 5 — AUTO-FIX-LOOP (Neu in v1.2.0)

> **Zweck:** Nicht bei roten Tests stoppen und dem Benutzer den Fehler zurückwerfen. Selbstständig fixen bis alle Tests grün sind.

### 5.1 Fix-Loop-Ablauf

```
SCHRITT 1: Alle Tests ausführen → Liste der fehlgeschlagenen Tests
SCHRITT 2: Für jeden fehlgeschlagenen Test:
           a) Fehlermeldung + Stack-Trace analysieren
           b) Root Cause identifizieren (nicht nur Symptom)
           c) Fix implementieren
           d) Betroffene Tests erneut ausführen
           e) Prüfen ob neue Tests fehlschlagen (Seiteneffekt des Fixes)
SCHRITT 3: Wenn alle Tests grün → Gate 1–8 durchlaufen
SCHRITT 4: TEST-REPORT ausgeben
```

### 5.2 Root-Cause-Kategorien (für schnelle Diagnose)

| Fehlermuster | Wahrscheinliche Ursache | Fix-Richtung |
|-------------|------------------------|--------------|
| `undefined is not a function` | Fehlende Mock-Initialisierung oder falsche Import-Reihenfolge | Mock-Setup in `beforeEach` prüfen |
| `Cannot read properties of undefined` | Fehlender null-Check im Code oder falsches Test-Fixture | Code: null-Guard hinzufügen |
| `Expected X received Y` (Statuscode) | Falscher Mock-Return oder fehlende Error-Weiterleitung | Mock-Response prüfen, Error-Handler prüfen |
| `Timeout exceeded` | Async-Promise nicht resolved oder fehlender `done()`-Call | `await` prüfen, Mock-Promise sicherstellen |
| MongoDB `duplicate key` | Test-Isolation fehlt, Zustand aus vorherigem Test | `beforeEach` Cleanup hinzufügen |
| `ENOENT: no such file or directory` | Temp-Dir nicht erstellt oder falscher Pfad | Temp-Dir-Setup in Test-Fixture prüfen |
| TypeScript `Type X is not assignable` | Interface-Mismatch nach Code-Änderung | Interface aktualisieren oder Cast begründen |

### 5.3 Abbruch-Bedingungen (wann der Loop stoppt)

Der Auto-Fix-Loop stoppt und eskaliert zum Benutzer wenn:
- Derselbe Test nach 3 Fix-Versuchen immer noch fehlschlägt
- Ein Fix einen anderen bisher grünen Test kaputt macht und dieser nicht in einer Iteration gefixt werden kann
- Ein SPEC GAP entdeckt wird der eine Design-Entscheidung erfordert
- Ein NO-FAIL-Test fehlschlägt aus einem Grund der einen Architektur-Eingriff erfordert

---

## PHASE 6 — FREIGABE-KRITERIEN

Ein Feature ist **bereit zum Ausliefern** nur wenn ALLE folgenden Punkte zutreffen:

### Für ALLE Features:
- [ ] Alle Tests bestehen in CI (nicht nur lokal)
- [ ] `tsc --noEmit` fehlerfrei
- [ ] `eslint` fehlerfrei (max-warnings 0)
- [ ] Keine neuen Flaky Tests eingeführt
- [ ] Alle bestehenden Tests bestehen noch (keine Regressionen)
- [ ] Testnamen beschreiben Verhalten, nicht Implementierung
- [ ] Jede Assertion prüft tatsächliche Ausgabewerte

### Für LOW-FAIL-Features (zusätzlich):
- [ ] Alle kritischen Fehlermodi haben Tests
- [ ] Integrationstest deckt den vollständigen Datenpfad ab
- [ ] Contract-Test existiert wenn API-Oberfläche geändert wurde
- [ ] Temp-File-Cleanup bei Fehler getestet

### Für NO-FAIL-Features (zusätzlich):
- [ ] Vollständige Prüfliste aus `./zero-fail-zones.md` abgeschlossen
- [ ] Adversariale Eingabe-Tests bestehen
- [ ] Nebenläufigkeits-Zugriffstest besteht
- [ ] Rollback-/Recovery-Test besteht
- [ ] Performance-Baseline-Test besteht
- [ ] Sicherheitsrelevanter Code Zeile für Zeile reviewed
- [ ] Keine Secrets in Logs (verifiziert durch Log-Output-Assertion in Tests)

### Abschluss-Output: TEST-REPORT

Nach Abschluss aller Tests eine Zusammenfassung ausgeben:

```
═══════════════════════════════════════════════════════
FEATURE TEST REPORT v1.2.0
═══════════════════════════════════════════════════════
Feature:         [Name]
Projekt:         [Repo-Name]
Risiko-Tier:     NO-FAIL / LOW-FAIL / BEST-EFFORT

ÄNDERUNGSANALYSE
  Geänderte Dateien:     [n] Dateien
  Betroffene Tests:      [n] bestehende Tests geprüft
  Regressions-Risiko:    HOCH / MITTEL / NIEDRIG

PYRAMID-GESUNDHEIT
  Unit:          [n] Tests ([x]%)   Ziel: 60–80%
  Integration:   [n] Tests ([x]%)   Ziel: 15–30%
  Contract:      [n] Tests ([x]%)
  E2E:           [n] Tests ([x]%)   Ziel: 5–10%
  Gesamt:        [n] Tests
  Alle bestanden: JA / NEIN

TYPESCRIPT-CHECKS
  tsc --noEmit:  BESTANDEN / FEHLGESCHLAGEN
  eslint:        BESTANDEN / FEHLGESCHLAGEN ([Anzahl] Warnings/Errors)
  Floating Promises gefunden: KEINE / [Liste]

SPEC-ABDECKUNGS-KARTE
  [✓] SPEC: [Anforderung 1] → abgedeckt von [Testdatei:Testname]
  [✓] SPEC: [Anforderung 2] → abgedeckt von [Testdatei:Testname]
  [✗] SPEC: [Anforderung 3] → NICHT ABGEDECKT — Grund: [...]

SPEC GAPS (undefinierte Verhaltensweisen gefunden)
  [!] SPEC GAP: [undefiniertes Verhalten beschreiben] — Status: BLOCKIERT / AKZEPTIERTES RISIKO
  (leer = keine Gaps gefunden)

RISIKO-ABDECKUNG
  Abgedeckte Verhaltensweisen:
    [✓] [Verhalten 1 — GEGEBEN/WENN/DANN]
    [✓] [Verhalten 2 — GEGEBEN/WENN/DANN]
  Bekannte nicht abgedeckte Risiken (akzeptiert):
    [beschreiben was nicht getestet wird und expliziter Grund]

AUTO-FIX-LOOP
  Fix-Iterationen benötigt: [n]
  Gefixte Bugs: [Liste der Bugs die der Loop automatisch behoben hat]
  Eskalationen: KEINE / [Liste was manuellen Eingriff erforderte]

QUALITÄTS-CHECKS
  Neue Flaky Tests:           KEINE / [Liste]
  Entfernte redundante Tests: [n] (Grund: [x])
  Mock-Overuse-Verletzungen:  KEINE / [Liste]
  Assertions-Qualität:        BESTANDEN / FEHLGESCHLAGEN ([schwache Assertions auflisten])
  Bestehende Tests gebrochen: KEINE / [Liste der eingeführten Regressionen]

NO-FAIL-PRÜFLISTE
  Auth/API-Key:   VOLLSTÄNDIG / NICHT ZUTREFFEND / BLOCKIERT ([Grund])
  Credentials:    VOLLSTÄNDIG / NICHT ZUTREFFEND / BLOCKIERT ([Grund])
  Datenschutz:    VOLLSTÄNDIG / NICHT ZUTREFFEND / BLOCKIERT ([Grund])
  Verschlüsselung:VOLLSTÄNDIG / NICHT ZUTREFFEND / BLOCKIERT ([Grund])
  Migrationen:    VOLLSTÄNDIG / NICHT ZUTREFFEND / BLOCKIERT ([Grund])

═══════════════════════════════════════════════════════
URTEIL: AUSLIEFERN / BLOCKIERT
Grund (bei BLOCKIERT): [konkreter, handlungsrelevanter Grund]
═══════════════════════════════════════════════════════
```

> **BLOCKIERT = nichts wird ausgeliefert.** Ein BLOCKIERT-Urteil ist keine Empfehlung. Es bedeutet dass das Feature den Branch nicht verlässt bis der Grund behoben ist.

---

## REFERENZ-DATEIEN

Bei Bedarf laden:

- **`./zero-fail-zones.md`** — Pflicht-Prüflisten für Auth/API-Key, Credentials, Datenschutz, Verschlüsselung und Datenmigrationen. Laden wenn Risiko-Tier = NO-FAIL.
- **`./test-patterns.md`** — Konkrete Testmuster für 24 Szenarien in drei Kategorien:
  - **Allgemein (10):** Pagination, Soft-Delete, Background-Jobs, Webhooks, Datei-Upload, Suche/Filterung, Multi-Tenancy, Event-Sourcing, Rate-Limiting, Caching.
  - **Connector/Integration (10):** HTTP-Client/API-Consumer, File-Pipeline, Credential-Forwarding, Action-Completion, Retry-Logic, Resource-Cleanup, OAuth-Token-Lifecycle, Connection-Pooling, Config/Environment-Validierung, Graceful-Shutdown/Health-Check.
  - **Neu in v1.2.0 (4):** Queue-Integrität, Connector-Lifecycle, Definition.json Contract-Tests, Fehlerklassifizierung.