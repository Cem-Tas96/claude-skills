---
name: feature-delivery
description: >
  Enterprise-Implementierungs-Disziplin für JEDE nicht-triviale Code-Änderung auf JEDEM Projekt.
  Diesen Skill verwenden BEVOR und WÄHREND Code geschrieben wird — wann immer ein Feature, ein Fix,
  ein Refactor oder eine Verhaltensänderung umgesetzt wird, besonders bei State-/Rollen-/Payment-/
  Auth-/Async-/SSR-/Cross-Layer-Änderungen. Der Skill zwingt den Agent ZUERST den vollständigen
  Blast-Radius zu kartieren (alle Aufrufer, Konsumenten, Reverse-Pfade, duplizierte Configs, generierte
  Artefakte), den Zustandsraum zu modellieren (State-Table, Invarianten, Falsy-Fälle, Contracts) und erst
  DANN — vollständig und symmetrisch — zu implementieren. Ziel: 1 Prompt → vollständig & korrekt
  eingebautes Feature, ohne vergessene Stellen, ohne Folgekommit-Ketten. Orchestriert /feature-testing
  (Test-Beweis), /verify (Real-Runtime-Beweis) und /security-review (Diff-Security). Führt bei jedem Aufruf
  einmal täglich einen Threat-Intel-Refresh aus (neueste CVEs/Angriffe → Exposure-Check gegen unseren Code) und
  härtet auf Enterprise-Security-Niveau inkl. Paywall-/Abuse-Schutz (VPN/IP/Geo, Coupon-Abuse). Ergänzt
  /performance-boost. Denkt wie IT-Architekt + Security-Engineer.
---

# Feature-Delivery Skill — Enterprise Zero-Regression Implementation

## KERNPHILOSOPHIE

> **Die meisten Bugs sind keine falschen Zeilen — es sind fehlende Zeilen.**
> Der Bug ist die Aufruf-Stelle die du nicht angefasst hast, der Reverse-Pfad den du nicht geschrieben hast, die State-Zelle die du nicht gefüllt hast, der Falsy-Wert den du nicht behandelt hast. Code-Skill verhindert das nicht. **Vollständige Kartierung VOR dem ersten Edit** verhindert das.

> **Code zuerst kartieren, dann mutieren.**
> Wer editiert bevor er den vollständigen Blast-Radius kennt, schreibt den ersten von vier Commits. Wer zuerst jede betroffene Stelle auflistet, schreibt einen.

> **Symmetrie ist kein Stil — es ist Korrektheit.**
> Jedes `grant` ohne sein `revoke`, jedes `open` ohne `close`, jedes `subscribe` ohne `unsubscribe`, jede Migration `up` ohne `down` ist ein halb gebautes Feature, das in Production die andere Hälfte nachfordert.

> **Grün in der falschen Schicht ist rot in Production.**
> Ein Test der im jsdom besteht aber den Browser-Race nicht reproduziert, ist kein Beweis — es ist eine Beruhigungspille.

> **Der Client ist feindlich; die neueste Lücke ist noch nicht in deinem Wissen.**
> Geld, Zugang und Berechtigung entscheidet der Server aus der Quelle der Wahrheit — nie aus IP, Geo, VPN-Erkennung oder einem Client-Flag. Und weil täglich neue Angriffe erscheinen, prüfst du bei jedem Lauf einmal die frischeste Bedrohungslage, statt dich auf Gestern zu verlassen. „Unhackbar" verspricht niemand — aber jede bekannte Klasse ist bewusst gedeckt und kein kritischer Pfad geht ungeprüft live.

**Du bist nicht fertig wenn der Happy-Path läuft. Du bist fertig wenn jede betroffene Stelle nachweislich angefasst, jede Transition abgedeckt, jeder Reverse-Pfad symmetrisch gebaut und das Ergebnis in der richtigen Test-Schicht bewiesen ist.**

Dieser Skill ist die destillierte, projekt-unabhängige Lehre aus ~150 Bug-Folgekommits. Er existiert um genau eine Sache zu erreichen: **1 Prompt → vollständig & korrekt eingebautes Feature.** Nicht "läuft bei mir", sondern "kann nicht mehr kaputt sein, weil die Lücke wo der Bug sonst säße, ist geschlossen und belegt."

---

## BETRIEBS-MODUS: Ein-Prompt-Autonomie

Der Boss gibt oft **einen knappen Prompt** ("Bau X", "Fix Y") und erwartet ein fertiges, bugfreies Feature — nicht eine Rückfrage-Kaskade und nicht vier Folgekommits.

**So verhältst du dich:**

1. **Niemals sofort coden.** Erst Phase 0–2 (Contract → Blast-Radius → Modellierung) durchlaufen. Das ist autonome Vorarbeit, dafür musst du nicht fragen.
2. **Nur EINMAL fragen — und nur bei einer konsequenten Gabel** die du nicht aus dem Code beantworten kannst (z.B. zwei legitime Produktverhalten, Datenverlust-Risiko, irreversible Migration). Dann gebündelt via einer einzigen Rückfrage. Alles was aus Code, Spec, Git-History oder Konvention ableitbar ist: **selbst entscheiden und im Report notieren** — nicht fragen.
3. **Unvollständigkeit IMMER VOR dem Commit melden.** Wenn du während der Implementierung merkst dass die State-Table oder das Coverage-Ledger eine Lücke hatte: sag es, erweitere das Ledger, baue nach — **bevor** du committest. Niemals als Folgekommit. (Das ist die #1-Ursache der historischen 4-Commit-Ketten.)
4. **Liefere mit Beweis, nicht mit Behauptung.** Der Delivery-Report (Phase 6) ist Pflicht. "Done" ohne abgehaktes Coverage-Ledger ist verboten.

> Tempo entsteht nicht durch früheres Coden — sondern dadurch dass du nicht viermal zurück musst.

---

## ZUSAMMENSPIEL MIT DEN TEST-/SECURITY-/PERF-SKILLS

Dieser Skill ist der **äußere Loop** (vollständig & korrekt bauen). `/feature-testing` ist der **Test-Modul darin** (Verhalten beweisen). Doppelung wird bewusst vermieden — Test-Strategie, Test-Quality-Gates und Auto-Fix-Loop gehören `/feature-testing`, nicht hierher.

```
   /feature-delivery — der äußere Loop:

   PRE-FLIGHT  Threat-Intel-Refresh (1×/Tag: neueste CVEs/Angriffe → Exposure-Check)
        ↓
   P0  Auftrags-Contract
   P1  Blast-Radius → Coverage-Ledger
       (Agenten-Fächer nach Tier · Anti-Halluzinations-Gate · NO-FAIL: kalte Zweit-Ableitung)
   P2  Modellierung (State-Table · Invarianten · Falsy · Security-Pass)
   P3  Tier-Floor-Gate (deterministisch) · Risiko-Tier · Test-Tier · Rollout-Strategie
        ↓
   P4  Implementierung (alle Ledger-Stellen, symmetrisch)
        ↓
   P5  Verifikation:
         • Independent-Verifier   (NO-FAIL: Red-Team-Agent Ledger↔Diff — fehlt/erfunden?)
         • invoke /feature-testing   (Test-Beweis: Mocks/jsdom)
         • invoke /verify            (Real-Runtime: echte App)
         • invoke /security-review   (Diff-Security gegen heutige Threat-Intel)
         • optional /performance-boost (Hot-Path)
        ↓
   P6  DoD + Delivery-Report  →  SHIP / BLOCKIERT
        ↓
   P7  Rollout (rückwärtskompatibel · Flag/Kill-Switch · Rollback · Observability)
       + Wirksamkeits-Signal (fing der Aufwand etwas? → Feedback-Loop)
```

**Reihenfolge ist nicht verhandelbar:** zuerst (1×/Tag) der Threat-Intel-Refresh, dann Blast-Radius & Modell, dann Code, dann `/feature-testing` → `/verify` → `/security-review`. Wer `/feature-testing` vor vollständiger Implementierung laufen lässt, beweist eine halbe Implementierung.

Wenn `/feature-testing` im Projekt nicht verfügbar ist: Phase 5 trotzdem durchführen, dabei die Test-Disziplin aus `references/verification.md` inline anwenden.

---

## PRE-FLIGHT — TÄGLICHER THREAT-INTEL-REFRESH (läuft bei JEDEM Aufruf zuerst)

> **Zweck:** einmal pro Kalendertag die frischeste Bedrohungslage aus dem Netz ziehen und prüfen ob WIR exponiert sind — schließt die Lücke zwischen Modell-Wissensstand und *heute*. Voll-Protokoll: `references/threat-intel.md`.

1. **Heutiges Datum** bestimmen (`date +%F` bzw. System-Datum, `YYYY-MM-DD`).
2. **Stamp lesen:** `~/.claude/.cache/feature-delivery/$(pwd | sed 's#^/##; s#/#-#g').json`. Fehlt die Datei → wie "noch nie geprüft".
3. **`stamp.lastCheck == heute`** → KEINE Online-Suche. Gespeicherte `findings` laden, in P2.5/P5 anwenden, weiter mit P0.
4. **Sonst** (anderer Tag / kein Stamp) → Online-Refresh (`references/threat-intel.md` §2–§4):
   - Stack erkennen (package.json/Deps/Dockerfile — Frameworks, Auth, Payment, DB).
   - `WebSearch`/`WebFetch` (bei Bedarf via ToolSearch laden) auf neueste CVEs der Deps + OWASP + GitHub Security Advisories + aktuelle Auth-/Payment-/Paywall-Abuse-Techniken, Zeitfilter „neueste".
   - Pro Fund: **prüfen ob unser Code exponiert ist** (grep/Read) → `safe` / `exposed` / `needs-review`.
   - **Stamp schreiben** (`lastCheck = heute`, `stack`, `findings[]`).
   - `exposed` auf NO-FAIL-Pfad → sofort BLOCKER ins Coverage-Ledger (P1).

> Läuft IMMER zuerst, auch bei winzigen Changes. Schon heute geprüft → nicht nochmal online, einfach weiter. Das ist die *frische* Hälfte der Security; die *statische* Hälfte (komplette Angriffs-Taxonomie + Paywall-Härtung) ist `references/security-hardening.md`.

---

## PHASE 0 — AUFTRAGS-CONTRACT (vor allem anderen)

Den knappen Prompt in einen präzisen Contract übersetzen. Schriftlich, kurz:

```
WAS (1 Satz)     : [Was soll nach der Änderung beobachtbar anders sein?]
WARUM (1 Satz)   : [Business-/Symptom-Grund. Unbekannt? → "Symptom: …", später klären.]
INVARIANTE       : [Welche Eigenschaft MUSS danach gelten? z.B. "Cancel-State == Fresh-Registration-State"]
NICHT-ZIEL       : [Was ausdrücklich NICHT Teil dieser Änderung ist — gegen Scope-Creep]
AKZEPTANZ        : [1–3 × GEGEBEN/WENN/DANN — der konkrete Beweis dass es fertig ist]
```

> ⚠️ **FAIL-FAST-REGEL:** Lässt sich INVARIANTE oder AKZEPTANZ nicht aus Prompt + Code + Spec formulieren — **STOP**. Unklare Anforderung = undefiniertes Verhalten = garantierter Folgekommit. Genau hier (nicht später) die eine gebündelte Rückfrage stellen. Annahmen die du selbst triffst: explizit als `ANNAHME: …` notieren und im Report listen.

---

## PHASE 1 — RECON & BLAST-RADIUS  ★ Kernstück gegen "vergisst Stellen"

> **Zweck:** Bevor eine Zeile geändert wird, JEDE Stelle finden die mitgeändert werden muss. Das Artefakt dieser Phase ist das **Coverage-Ledger** — und nichts wird ausgeliefert solange darin eine Zeile `offen` steht.

### 1.1 Anker-Symbole bestimmen
Welche Symbole stehen im Zentrum der Änderung? (Funktion, Methode, Klasse, Route, Env-Var, DB-Spalte, Event-Name, Config-Key, DTO-Feld.) Diese Symbole sind die Suchanker.

### 1.2 Vollständige Referenz-Suche (statisch)
Für **jedes** Anker-Symbol — keine Stichprobe, alle Treffer:
- Alle **Aufrufer / Importeure** (`grep`/Symbol-Suche auf Symbolname, nicht nur Datei)
- Alle **Konsumenten des Outputs** (wer liest den Rückgabewert, das DB-Feld, das Event, die Response?)
- Alle **Definitionen desselben Konzepts an anderer Stelle** (duplizierte Konstante, parallele Implementierung, Copy-Paste-Zwilling)
- **Typen / DTOs / Schemas / Interfaces** die das Symbol beschreiben
- **Generierte Artefakte** (OpenAPI-Clients, GraphQL-Codegen, Prisma-Client, Protobuf) — Quelle UND Generat
- **Tests, Fixtures, Mocks, Seeds** die das Symbol referenzieren
- **Docs / READMEs / Config-Beispiele / `.env.example`** die es erwähnen

### 1.3 Cross-Layer-Kopplung aufdecken
Die teuersten vergessenen Stellen sind die **nicht aus einer Datei sichtbaren**. Aktiv suchen nach (Katalog + Rezepte: `references/blast-radius.md`):
- **Duplizierte Config-Familien** (z.B. `STRIPE_*` vs `STRIPE_*_DOMOAI`, prod/staging-Key-Paare, zwei Zahlungs-/Auth-Provider) — ein Pfad gefixt, der andere vergessen ist ein klassischer Bug.
- **Shared Lib → N Consumer** (eine Bibliothek/ein Element, das von mehreren Apps konsumiert wird — z.B. cookie-consent in texter + embed + Keycloak-Theme). Änderung rippelt.
- **Asset-/Theme-Kopien** (Datei wird gebaut und in mehrere Zielordner kopiert).
- **Env / Bootstrap / Realm-Init** (Werte die zur Laufzeit/Boot-Zeit injiziert werden, nicht im Code stehen).
- **Projekt-Doku der unsichtbaren Kopplungen:** Existiert eine `CLAUDE.md`/`AGENTS.md`/`CONTRIBUTING.md` mit einer Sektion wie "Important behaviors that aren't visible from a single file" → **greppen** ob ein geändertes Symbol dort vorkommt. Wenn ja: alle dort genannten Konsumenten ins Ledger.

### 1.4 Symmetrie-Inventar
Für jede Aktion die du hinzufügst/änderst, den **Partner-Pfad** lokalisieren und ins Ledger aufnehmen:

| Du baust … | Dann existiert / brauchst du auch … |
|---|---|
| grant / add / assign | revoke / remove / unassign |
| create / open / start / mount | delete / close / stop / unmount |
| subscribe / addEventListener / lock | unsubscribe / removeEventListener / unlock |
| increment / acquire / push | decrement / release / pop |
| serialize / encode / encrypt | deserialize / decode / decrypt |
| set flag true (enable) | set flag false (disable / reset / expire) |
| cache write | cache invalidate |
| migration up | migration down (Rollback) |
| feature-flag on | feature-flag off (sauberer Aus-Zustand) |

> Asymmetrie ist die historische Hauptursache der Folgekommit-Ketten. Wenn ein Partner-Pfad bewusst entfällt: als `N/A — Grund: …` ins Ledger, nicht stillschweigend weglassen.

### 1.5 Breiten-Recon via Sub-Agenten (Kopfzahl nach Tier — Anti-Halluzination Pflicht)
Bei nicht-trivialem Blast-Radius **`Explore`-Sub-Agenten parallel fächern** (alle in EINER Nachricht → nebenläufig) — je Agent ein **disjunkter** Suchauftrag (Streams A–G: Aufrufer · Konsumenten · Config-Duplikate · parallele Implementierungen · Tests · generierte Artefakte · Docs). Jeder liefert `file:line` **+ wörtlich zitierte Zeile**. Volles Orchestrierungs-Protokoll inkl. Prompt-Vorlagen: `references/multi-agent.md`.

> **Kopfzahl skaliert mit Risiko, nicht „immer maximal":** mehr Agenten kaufen **Recall** (mehr Stellen gefunden), **nicht Präzision** — jeder Agent halluziniert unabhängig dazu. Darum:
> - **BEST-EFFORT / trivial:** 0 Agenten, direktes `grep`.
> - **LOW-FAIL / mittel:** Streams A–G einfach gefächert.
> - **NO-FAIL (Auth/Payment/Rollen/PII/Migration):** Fächer **+ kalte Zweit-Ableitung** (zweiter Agenten-Satz leitet den Blast-Radius unabhängig neu ab, ohne Satz 1 zu sehen → Konsens) **+ Independent-Verifier in P5**.
>
> **Kreuzaudit-Schicht ist an die Blast-Radius-*Form* gebunden, nicht ans Tier** (siehe §5.0 & `references/multi-agent.md` §1/§4): der Ledger↔Diff-Abgleich läuft **immer** (außer trivial) — als billiger **Selbst-Audit** beim schmalen LOW-FAIL, als **unabhängiger Verifier-Agent** sobald ein **Risiko-Signal** vorliegt (>8 Ledger-Zeilen · Symmetrie-Paar berührt · Cross-Layer-Kopplung · überhaupt Sub-Agenten gefächert) und immer bei NO-FAIL.

> 🚨 **ANTI-HALLUZINATIONS-GATE (jeder Agenten-Befund muss hindurch, bevor er Ledger-Wahrheit wird):**
> 1. **Citation-or-void** — Befund ohne `file:line` + wörtliches Zitat → verworfen, nicht „nachrecherchiert".
> 2. **Source-Abgleich (HART)** — jede zitierte Stelle selbst mit `Read` öffnen und prüfen, dass Zeile + Symbol + Kontext der Behauptung entsprechen. Erst dann `behauptet` → `verifiziert`. Existiert die Zeile nicht → Halluzination, verwerfen.
> 3. **Konsens (nur NO-FAIL)** — Funde aus Satz 1 ⋃ Zweit-Ableitung; „nur in einem"-Funde nicht droppen und nicht blind glauben → Gate 2 entscheidet am Source.
>
> „Der Agent sagte" ist kein Beleg. „Ich habe die Zeile gesehen" ist einer. (Deckt sich mit Memory `feedback_verify_agent_reports` — nicht verhandelbar.)

### 1.6 Das COVERAGE-LEDGER (Pflicht-Artefakt)
Ergebnis von Phase 1 ist diese Tabelle. Sie lebt bis zum Ship:

```
COVERAGE-LEDGER — [Feature]
ID  | Stelle (file:line / Symbol)        | Art            | Was muss passieren            | Status
----|------------------------------------|----------------|-------------------------------|--------
C1  | payment.service.ts:142 grantSeeker | Caller         | seeker bei 29€/39€ granten    | offen
C2  | subscription.service.ts cancel()   | Reverse-Pfad   | seeker revoken (Symmetrie C1)  | offen
C3  | env.ts STRIPE_*_DOMOAI             | Config-Duplikat| zweiten Account-Pfad anfassen  | offen
C4  | libs/api-client (generiert)        | Generat        | nach API-Change neu generieren | offen
C5  | role.guard.spec.ts                 | Test           | neue Transition abdecken       | offen
...
```

**Regeln:**
- **Art** ∈ {Caller, Consumer, Reverse-Pfad, Config-Duplikat, Type/DTO, Generat, Test, Doc, Migration}.
- **Status** ∈ {offen, ✓, N/A (+Grund)}.
- **Kein SHIP solange eine Zeile `offen` ist.**
- **Jede während Phase 4 NEU entdeckte Stelle wird als Ledger-Zeile ergänzt** — niemals "fällt mir später ein" und niemals stillschweigend ausgelassen.

---

## PHASE 2 — MODELLIERUNG (denke wie ein Architekt)

Erst modellieren, dann coden. Details + Templates: `references/modeling.md`.

### 2.1 STATE-TABLE (Pflicht bei State/Rollen/Lifecycle/Subscription/Async-UI)
Tabelliere **jede** `(Start-Zustand × Trigger → End-Zustand)`-Zelle. Lücken in der Tabelle = die Bugs die sonst in Folgekommits landen.

> Faustregel aus der Praxis: Eine vollständige Transition-Matrix VOR dem Code hätte ~80% der historischen Folgekommits gespart. Wenn mehrere Endzustände identisch sein MÜSSEN (z.B. "Cancel", "Refund", "Dispute", "Freeze-Ende" landen alle in `{user}`) — das ist eine **Invariante**, explizit prüfen dass alle Zellen sie erfüllen.

### 2.2 INVARIANTEN
Liste die Eigenschaften die nach JEDER Operation gelten müssen (z.B. "kein User hat `seeker` ohne aktives bezahltes Abo", "Summe der Splits == Gesamtbetrag"). Diese werden später zu Assertions.

### 2.3 FALSY-/EDGE-ENUMERATION (Pflicht bei jeder Validierung/Verzweigung)
Für **jeden** geprüften Wert explizit durchgehen — niemals `!== null` ohne diese Aufzählung:

| Wert | `null` | `undefined` | `''` | `0` | `false` | `NaN` | `[]` | `{}` | Whitespace-only |
|---|---|---|---|---|---|---|---|---|---|

Pro Spalte entscheiden: erlaubt / abgelehnt / normalisiert. Nicht zutreffende Spalten streichen. (Historischer Bug: Guard prüfte `priceId !== null`, brach bei `priceId === ''`.)

### 2.4 CONTRACTS & NEBENLÄUFIGKEIT
- **Datenquelle-Frische:** Liest du aus einem Token/Cache/JWT der **stale** sein kann? (Historisch: Guard vertraute dem JWT, der war veraltet → frisch lesen.) Quelle der Wahrheit festnageln.
- **API-/Event-/DB-Contract:** Request/Response-Shape, Nullability, neue Pflichtfelder rückwärtskompatibel?
- **Idempotenz & Reihenfolge:** Was passiert bei doppeltem Event / Retry / Out-of-Order?
- **Nebenläufigkeit:** Zwei parallele Operationen auf demselben Datensatz — Lost Update? Lock nötig?
- **Partial-Failure:** Schreibvorgang scheitert auf halbem Weg — bleibt das System konsistent (Transaktion/Rollback)?

### 2.5 SECURITY-PASS (denke wie ein Security-Engineer)
Sicherheits-Durchgang über jede neue/geänderte Stelle (Schnell-Checkliste: `references/security-pass.md`; Enterprise-Tiefe + komplette Angriffs-Taxonomie: `references/security-hardening.md`):
- **Heutige Threat-Intel anwenden** — die Pre-flight-`findings` (neue CVEs/Angriffe) gegen die berührten Stellen abgleichen. `exposed` → ins Ledger.
- **Authz auf JEDEM neuen Pfad** — neue Route/Methode ohne Berechtigungsprüfung? IDOR/BOLA (fremde ID einsetzbar)? Funktions-Level (darf diese Rolle das überhaupt)?
- **Input-Validierung & Injection** — SQL/NoSQL/Command/Template-Injection, XSS, Pfad-Traversal, SSRF, Open-Redirect, Mass-Assignment bei user-gelieferten Werten.
- **Secrets** — keine Keys/Tokens in Logs, Client-Bundles, Fehlermeldungen, Test-Fixtures.
- **Falsy-as-Auth-Bypass** — die §2.3-Lücken sind oft Security-Bugs (leerer String umgeht Owner-Check).
- **Paywall/Entitlement & Abuse** (bei Payment/Zugang/Coupon berührt) — Zugang server-seitig aus der Quelle der Wahrheit, **nie** aus IP/Geo/VPN-Erkennung oder Client-Flag. Coupon/Trial: Redemption-Race (atomar), Caps pro Account, Enumeration/Replay, negativer Endpreis; Webhook-Signatur verifizieren. Voll: `references/security-hardening.md` §3.

> 🚨 Berührt die Änderung **Auth, Autorisierung, Geld/Payment, personenbezogene Daten, Berechtigungssysteme oder Datenmigrationen** → das ist eine **NO-FAIL-Domäne**. Risiko-Tier ist automatisch NO-FAIL (Phase 3); `references/security-hardening.md` (komplette Taxonomie §1) + `references/security-pass.md` + die `zero-fail-zones.md` von /feature-testing sind Pflicht.

---

## PHASE 3 — PLAN, RISIKO-TIER, TEST-TIER & CONFIRM-GATE

### 3.0 TIER-FLOOR-GATE (deterministisch, vor jeder Ermessens-Einstufung) ★ schützt die Selbsteinstufung
Die ganze risiko-proportionale Maschinerie (Verifier, Konsens, zero-fail-zones) greift nur, wenn das Tier korrekt ist — und nichts prüft eine zu *niedrige* Einstufung gegen. Darum zuerst ein **mechanischer, ermessensfreier Boden**, bevor du irgendein Tier per Urteil wählst:

```
BERÜHRT der Diff/Plan irgendeines von:
  { Authentifizierung · Autorisierung/Rollen · Geld/Payment/Billing ·
    personenbezogene Daten (PII) · Berechtigungs-/Entitlement-Logik · DB-Migration/Schema }
  → dann ist das Tier ZWINGEND NO-FAIL. Kein „fühlt sich harmlos an" hebt das auf.
```

Mechanische Prüfung (nicht „aus dem Bauch"): die Ledger-Stellen (P1) gegen diese Begriffe greppen — Symbole wie `role|grant|seeker|price|stripe|payment|coupon|entitlement|migration|password|token|email|@PrismaModel`. Trifft eines zu → NO-FAIL ist gesetzt, *dann erst* §3.1.

> Dies ist der einzige Punkt, an dem Einstufung **nicht** Ermessen sein darf. Eine als „LOW-FAIL" fehlklassifizierte Payment-Änderung deaktiviert still alle NO-FAIL-Schutzschichten — der teuerste Fehler des ganzen Skills. Der Floor macht ihn unmöglich.

### 3.1 Risiko-Tier zuweisen (steuert Tiefe von Verifikation & Tests)

| Tier | Gilt wenn | Konsequenz |
|---|---|---|
| **NO-FAIL** | Auth, Autorisierung, Geld/Payment, personenbezogene Daten, Berechtigungen, Datenmigrationen | Erschöpfend: alle Pfade, Missbrauch, Nebenläufigkeit, Rollback. Security-Pass + zero-fail-zones Pflicht. Confirm-Gate Pflicht. |
| **LOW-FAIL** | Kern-Business-Logik, Schreibvorgänge, State-Transitions, Integrationen | Risikobasiert: Happy-Path + alle realistischen Fehlermodi + Reverse-Pfade. |
| **BEST-EFFORT** | Rein lesende UI-Anzeige, kosmetisch, unkritische Analytics | Smoke + Happy-Path. |

> 🚨 **Security forciert das Tier:** ein `exposed` Threat-Intel-Fund (Pre-flight) oder ein offenes Security-Pass-/`/security-review`-Finding hebt die Änderung **automatisch auf NO-FAIL** — egal wie harmlos die Fachlogik wirkt.

### 3.2 TEST-TIER explizit wählen (vor dem Code, mit Begründung)
Falsche Tier-Wahl = Tests grün, Bug live. Wähle bewusst (Entscheidungsbaum: `references/verification.md`):

| Tier | Wählen wenn | Warnung |
|---|---|---|
| **Unit** | reine Logik, Pure Functions, Reducer, Validatoren | deckt KEINE Timing-/DOM-/SSR-Races ab |
| **Integration** | DB/Service/Queue-Grenze, mehrere Layer | externe APIs gemockt |
| **Real-Browser** (via `/verify`; E2E als Dauer-Anker) | **jede** UI-Timing-/Effekt-/Hydration-/Race-Änderung | jsdom reproduziert diese Races NICHT — Pflicht statt Unit |
| **Real-Stack-Smoke** | `.env`/Docker/Auth-Realm/Bootstrap/Infra berührt | from clean state hochfahren + 1 echter Request — Unit-Tests beweisen hier nichts |

### 3.3 Confirm-Gate
- **NO-FAIL ODER großer Blast-Radius (>~8 Ledger-Zeilen) ODER irreversibel:** Coverage-Ledger + State-Table + Plan dem Boss zeigen **bevor** mutiert wird. Kurz, kein Roman.
- **Klein & eindeutig & reversibel:** ohne Rückfrage durchziehen (Betriebs-Modus). Der Report am Ende ist der Beleg.

### 3.4 ROLLOUT-STRATEGIE & RÜCKWÄRTSKOMPATIBILITÄT (jetzt entscheiden — nicht nachrüsten)
Bei jedem Change der **Prod mit aktiven Kunden** trifft (alles außer rein lokalem Tooling): die Liefer-Strategie gehört in den Plan, weil sie das Datenmodell und den Code-Pfad **vorab** formt (Expand-Contract kann man nicht nachträglich aufkleben). Voll-Protokoll: `references/rollout.md`. Kurz hier festlegen:
- **Rückwärtskompatibel?** Überlebt die laufende Vorgänger-Version den Change (additiv, nullable-first, Feld optional)? Wenn nein → in Expand- und Contract-Schritt teilen (Contract = späterer Release).
- **Phasenweise / Flag?** Riskant oder NO-FAIL → hinter Feature-Flag dark shippen + rampen; **Kill-Switch ohne Redeploy** ist bei NO-FAIL Pflicht.
- **Rollback-Plan?** Wie macht man's in Sekunden rückgängig? `migration down` getestet, von der neuen Version geschriebene Daten von der alten lesbar.
- **Observability?** Welches Log/Metrik/Alert beweist nach dem Ship dass der neue Pfad in Prod lebt (P7)?

> Deckt Memory `feedback_zero_customer_impact_merges`: zahlende Kunden auf Main → jeder Merge phasenweise & rückwärtskompatibel. Ausführung & Checkliste in Phase 7.

---

## PHASE 4 — IMPLEMENTIERUNG (Ledger abarbeiten)

### 4.1 Das Ledger ist die Arbeitsliste
Stelle für Stelle abarbeiten, jede auf ✓ setzen. **Symmetrische Paare im selben Change** (grant + revoke zusammen — nie "revoke kommt im nächsten Commit").

### 4.2 Vollständig in einem kohärenten Change
- Alle Ledger-Stellen in **einem** zusammenhängenden Change-Set — nicht "Hälfte jetzt, Rest später".
- **Generate nach Source:** Generierte Artefakte (API-Client etc.) nach Source-Änderung neu erzeugen, nicht von Hand editieren.
- **Reuse vor Neubau:** Vor jeder neuen Helper-Funktion suchen ob es sie schon gibt. Jeder Fix der einen neuen Quasi-Duplikat-Helper hinstellt vergrößert den nächsten Blast-Radius. (Wenn `/simplify` o.ä. verfügbar: am Ende laufen lassen.)
- **Kein "while-I'm-here"-Refactor** außerhalb des NICHT-Ziels.

### 4.3 Neue Stelle entdeckt? → Ledger erweitern, sofort
Fällt während des Codens eine Stelle auf die nicht im Ledger war: **Zeile ergänzen, Status `offen`, dann abarbeiten.** Wenn sie die State-Table oder Invariante verändert: das **vor** dem Commit melden (Betriebs-Modus Punkt 3) — nicht durchschmuggeln.

---

## PHASE 5 — VERIFIKATION (richtige Schicht, echter Beweis)

### 5.0 Ledger ↔ Diff kreuz-auditieren (immer außer trivial; unabhängiger Agent ab Risiko-Signal)
Bevor Tests laufen, gegen **Diff + Coverage-Ledger** die *entgegengesetzte* Frage zur Recon stellen: nicht „was muss rein", sondern „was fehlt oder ist erfunden". **Wer prüft, skaliert mit der Blast-Radius-Form** (`references/multi-agent.md` §1/§4):
- **NO-FAIL oder LOW-FAIL-mit-Risiko-Signal** (>8 Ledger-Zeilen · Symmetrie-Paar · Cross-Layer-Kopplung · Sub-Agenten gefächert) → **frischer `Explore`-Agent** (Independent-Verifier; nicht einer der Recon-Streams — der bestätigt nur sich selbst).
- **LOW-FAIL schmal (kein Signal)** → **Orchestrator-Selbst-Audit** (dieselben vier Checks, in-process, kein neuer Agent).
- **BEST-EFFORT / trivial** → entfällt.

Gesucht wird gezielt (Prompt-Vorlage: `references/multi-agent.md` §4):
- **(a) gemeldet-erledigt-aber-nicht** — Ledger-Zeile ✓, Stelle im Diff aber unangetastet.
- **(b) geändert-aber-nicht-erfasst** — Diff berührt ein Symbol/eine Stelle, die in keiner Ledger-Zeile steht (Blast-Radius war unvollständig).
- **(c) erfunden** — Ledger-Zeile zeigt auf Symbol/Datei, die im Repo nicht existiert (halluzinierte Recon-Stelle).
- **(d) Asymmetrie** — Vorwärts-Aktion im Diff ohne ihren Reverse-Pfad.

> Output durchläuft **dasselbe** Anti-Halluzinations-Gate (§1.5) — auch ein Verifier-Agent halluziniert. Jeder bestätigte Befund wird vor SHIP aufgelöst: (a) wirklich abarbeiten, (b) neue Ledger-Zeile + Recon nachschärfen, (c) Zeile streichen, (d) Reverse-Pfad bauen oder `N/A (+Grund)`. **Offener Kreuzaudit-Befund = BLOCKIERT, wann immer der Audit lief.**

### 5.1 Test-Beweis: `/feature-testing` aufrufen
Jetzt — Implementierung vollständig — `/feature-testing` invoken. Dieser Skill besitzt Test-Strategie, Test-Quality-Gates (Gate 1–8), Auto-Fix-Loop und das NO-FAIL-Test-Regime. **Nicht hier duplizieren.** Das gewählte Test-Tier (§3.2) und die Invarianten (§2.2) als Input übergeben.
(Nicht verfügbar? → Test-Disziplin inline aus `references/verification.md`.)

### 5.2 Real-Runtime-Proof: `/verify` aufrufen (das was Tests allein nicht beweisen)
Tests laufen gegen Mocks/jsdom — sie beweisen nicht dass die Änderung **in der echten laufenden App** tut was sie soll. Jetzt `/verify` invoken: es fährt die App hoch und beobachtet das tatsächliche Verhalten. **Pflicht** sobald §3.2 Real-Browser oder Real-Stack-Smoke ergab. `/verify` mit präzisem Szenario füttern (Details + `AN /verify`-Block: `references/verification.md` §3):
- **Flow + Erwartet** aus dem Contract (P0/AKZEPTANZ) — welche Route/Klicks/Request, welches beobachtbare Soll.
- **Race/Edge** explizit stressen: Doppel-Klick, Reload mitten im Flow, schnelles Navigieren, leerer/`0`-Wert aus der Falsy-Matrix (§2.3).
- **Reverse-Pfad** (P1.4) bei Statuswechsel einmal real auslösen.
- **Bei `.env`/Docker/Realm/Bootstrap berührt →** zuerst Clean-Bring-up (`down && up -d && start`), DANN `/verify` (Real-Stack-Smoke, `references/verification.md` §4).
- **Durabler Anker:** regress-anfälliger Race → zusätzlich Playwright/Cypress-E2E in `/feature-testing`s E2E-Layer. `/verify` beweist *jetzt*, der E2E wacht *später*.
- **Fallback (kein `/verify` im Projekt):** dokumentiertes manuelles Verify im echten Browser. **Hot-Path →** zusätzlich optional `/performance-boost`.
> jsdom-grün ≠ Browser-grün. „Done" bei UI-Timing-/Env-Code ohne `/verify` (oder dokumentiertes manuelles Verify) ist verboten.

### 5.3 Security-Review: `/security-review` aufrufen
Auf den Diff der laufenden Änderung `/security-review` invoken — fängt die konkret eingeführten Schwächen (Authz/Injection/Secrets/Open-Redirect …). Zusätzlich:
- die **heutigen Threat-Intel-`findings`** gegen den Diff + die berührten Angriffsklassen abgleichen (`references/threat-intel.md`),
- bei berührtem Payment/Zugang/Coupon: die **Paywall-/Abuse-Checkliste** `references/security-hardening.md` §3 durchgehen,
- bei **NO-FAIL**: `zero-fail-zones.md` von `/feature-testing` vollständig + adversariale Tests.

(Ergänzend `/code-review` für Korrektheits-Bugs. Kein `/security-review` im Projekt? → Taxonomie `references/security-hardening.md` §1 manuell durchgehen.)
> Ungemitteltes kritisches/`exposed`-Finding = **BLOCKIERT**, kein „fixe ich später".

### 5.4 Regressions-Sweep
Volle bestehende Test-Suite laufen lassen (nicht nur die neuen). Lint + Typecheck + Build grün. Keine vorher-grünen Tests jetzt rot.

---

## PHASE 6 — DEFINITION OF DONE & DELIVERY-REPORT

### 6.1 DoD-Checkliste (jede Box muss ✔ sein)
- [ ] **Coverage-Ledger vollständig** — jede Zeile ✓ oder `N/A (+Grund)`, keine `offen`
- [ ] **Reverse-Pfade** im selben Change angefasst (oder `N/A` begründet)
- [ ] **State-Table** vollständig, alle Invarianten in allen Zellen erfüllt
- [ ] **Falsy-Enumeration** für jede neue Validierung durchgegangen
- [ ] **Cross-Layer-Kopplung** (Config-Duplikate / Shared-Lib-Consumer / `CLAUDE.md`-Behaviors) abgedeckt
- [ ] **Agenten-Befunde verifiziert** — jede vom Sub-Agenten gemeldete Stelle am Source gegengelesen (kein blind übernommener Pfad)
- [ ] **Ledger↔Diff-Kreuzaudit** sauber (immer außer trivial): Selbst-Audit beim schmalen LOW-FAIL, **unabhängiger Verifier** ab Risiko-Signal/NO-FAIL; bei NO-FAIL zusätzlich kalte Zweit-Ableitung (Konsens) — keine offenen (a)/(b)/(c)/(d)-Befunde
- [ ] **Threat-Intel heute aktualisiert** (Pre-flight gelaufen; `exposed`-Funde gemittelt oder geblockt)
- [ ] **Security-Pass** ohne offene Findings (NO-FAIL: `security-hardening.md`-Taxonomie §1 + zero-fail-zones komplett)
- [ ] **`/security-review`** auf dem Diff sauber; bei Payment/Zugang: Paywall-/Abuse-Härtung (server-seitiges Entitlement, **kein** IP/Geo-Gate) geprüft
- [ ] **Test-Beweis** in der gewählten Schicht grün (`/feature-testing`-Urteil = AUSLIEFERN)
- [ ] **Real-Runtime-Proof via `/verify`** dokumentiert (Browser bei UI-Timing, Real-Stack nach Clean-Bring-up bei Env/Infra; Fallback: manuell)
- [ ] **Regressions-Sweep** grün (bestehende Tests, Lint, Typecheck, Build)
- [ ] **Tier-Floor-Gate** angewandt — Auth/Payment/Rollen/PII/Migration berührt → NO-FAIL gesetzt (nicht per Ermessen heruntergestuft)
- [ ] **Rollout (P7)** für Prod-Changes belegt — rückwärtskompatibel, Kill-Switch (NO-FAIL), Rollback getestet, Observability live (oder `N/A` begründet bei rein lokalem Tooling)
- [ ] **Commit-Message** benennt Invariante & Reverse-Pfad (nicht nur das Symptom)

> Ist ein Punkt offen → **melden, nicht "done" sagen.** Vor dem Commit, nicht als Folgekommit.

### 6.2 Delivery-Report (Pflicht-Output)

```
═══════════════════════════════════════════════════════
FEATURE DELIVERY REPORT
═══════════════════════════════════════════════════════
Feature:        [Name]            Projekt: [Repo]
Risiko-Tier:    NO-FAIL / LOW-FAIL / BEST-EFFORT
Test-Tier:      Unit / Integration / Real-Browser / Real-Stack-Smoke  (Begründung)

CONTRACT
  WAS / WARUM / INVARIANTE / NICHT-ZIEL / AKZEPTANZ
  Getroffene ANNAHMEN: [Liste oder "keine"]

COVERAGE-LEDGER
  [n] Stellen identifiziert — [n] ✓ / [n] N/A / 0 offen
  (Tabelle oder Kurzfassung; 0 offen ist Pflicht für SHIP)

BLAST-RADIUS-NACHWEIS
  Aufrufer/Konsumenten:   [n] gefunden, alle abgedeckt
  Config-Duplikate:       [Liste / keine]
  Shared-Lib-Consumer:    [Liste / keine]
  Generierte Artefakte:   [neu generiert / N/A]
  Symmetrie-Paare:        [grant↔revoke etc. — alle gepaart / N/A-Begründung]

MODELL
  State-Table:    [vollständig / N/A]  Invarianten geprüft: [Liste]
  Falsy-Fälle:    [behandelt: null/''/0/… ]
  Contracts:      [rückwärtskompatibel / Migration nötig]

THREAT-INTEL (Pre-flight)
  Stand:          [YYYY-MM-DD — heute aktualisiert / aus Cache (schon heute geprüft)]
  Neue Funde:     [n relevant]   exposed: [Liste / keine]
SECURITY
  Taxonomie (security-hardening §1): [alle Klassen adressiert / offen: …]
  Authz/IDOR / Injection / Secrets / Falsy-Bypass: [OK / Findings]
  Paywall/Abuse (server-seit. Entitlement, kein IP/Geo-Gate, Coupon-Race/Caps): [OK / N/A / Findings]
  NO-FAIL zero-fail-zones: VOLLSTÄNDIG / NICHT ZUTREFFEND
  /security-review-Urteil: SAUBER / FINDINGS [Liste]

VERIFIKATION
  Ledger↔Diff-Kreuzaudit:   sauber / Befunde (a/b/c/d)   [Selbst-Audit | unabhängiger Verifier]
  /feature-testing-Urteil:  AUSLIEFERN / BLOCKIERT
  /verify (Real-Runtime):   funktioniert / kaputt / N/A   [Beobachtung: Browser bzw. Real-Stack]
  Regressions-Sweep:        grün / [Liste]

ROLLOUT (P7 — bei Prod-Changes)
  Rückwärtskompatibel:      ja / Expand-Contract geteilt / N/A
  Flag + Kill-Switch:       [Flag-Name / direkt, da klein] · Kill-Switch ohne Redeploy: ja/N/A
  Rollback:                 [Revert-Weg · migration down getestet] / N/A
  Observability:            [Log/Metrik/Alert auf neuem Pfad] / N/A

WIRKSAMKEITS-SIGNAL
  Kreuzaudit/Konsens fing:  [n Befunde a–d / nichts]
  Tier-Floor hob an:        [ja, von X→NO-FAIL / nein]
  Ledger-Umfang:            [n Stellen]

═══════════════════════════════════════════════════════
URTEIL: SHIP / BLOCKIERT
Grund (bei BLOCKIERT): [konkret, handlungsrelevant]
═══════════════════════════════════════════════════════
```

> **BLOCKIERT = nichts verlässt den Branch** bis der Grund behoben ist. Ein offenes Coverage-Ledger ist immer BLOCKIERT.

---

## PHASE 7 — ROLLOUT, REVERSIBILITÄT & POST-SHIP (für Prod-gerichtete Changes mit aktiven Kunden)

> Korrekt & lokal bewiesen (P5/P6) ist nicht dasselbe wie *sicher bei zahlenden Kunden gelandet*. Diese Phase greift bei jedem Change der Prod trifft (entfällt nur bei rein lokalem Tooling ohne Prod-/Datenpfad). Voll-Protokoll + Expand-Contract-Tabelle: `references/rollout.md`.

Die in P3.4 gewählte Strategie jetzt **belegen** (nicht nur geplant):
- [ ] **Rückwärtskompatibel ausgeliefert** — additiv/nullable-first; brechende Schritte (`contract`) auf späteren Release verschoben (`references/rollout.md` §1).
- [ ] **Phasenweise + Kill-Switch** — riskant/NO-FAIL hinter Flag, Aus-Schalter greift **ohne Redeploy** in Sekunden; Flag-Aus-Pfad ist ein sauberer getesteter Zustand (§2).
- [ ] **Rollback bewiesen** — Revert benannt, `migration down` getestet, neu geschriebene Daten von der alten Version lesbar; irreversibler Anteil (echte Charge/Mail) isoliert & idempotent (§3).
- [ ] **Observability live** — Log/Metrik auf Erfolg **und** Fehler des neuen Pfads, Alert auf den relevanten Bruch, neue Exception von Sentry erfasst; bei NO-FAIL die P2.2-Invariante als laufender Monitor (§4).

> Faustregel: Ist die Antwort auf „und wenn das in Prod bricht?" ein neuer Hotfix-Deploy statt ein Schalter — **nicht produktionsreif.**

---

## WIRKSAMKEITS-SIGNAL (macht den Skill messbar statt geglaubt)

Damit Disziplin nicht zur ungemessenen Ceremony wird: bei jedem Lauf im Delivery-Report **kurz festhalten, ob der Aufwand etwas gefangen hat** — fand der Kreuzaudit/Konsens eine fehlende/erfundene Stelle (a–d)? Hob das Tier-Floor-Gate ein zu niedrig eingestuftes Change an? Wie viele Ledger-Stellen waren es?

> Über mehrere Läufe zeigt das, **ob** die schweren Phasen zahlen: fängt der Verifier nie etwas auf einer Change-Klasse, ist er dort Over-Engineering (lockern); fängt er regelmäßig, ist die Disziplin belegt (beibehalten/ausweiten). Das ist der Feedback-Loop, der „perfekt" von „aufgebläht" trennt — ohne Messung weiß niemand welches von beiden vorliegt.

---

## ANTI-PATTERNS — die hier sterben

| Anti-Pattern | Symptom | Gegenmittel (Phase) |
|---|---|---|
| Editieren vor Kartieren | "Bug an Stelle die ich übersah" | Coverage-Ledger zuerst (P1) |
| Symptom statt Invariante fixen | Folgekommit-Kette | State-Table + Invarianten (P2) |
| Asymmetrischer Fix | grant ohne revoke | Symmetrie-Inventar (P1.4) |
| `!== null` ohne Falsy-Liste | bricht bei `''`/`0` | Falsy-Enumeration (P2.3) |
| Einen Config-Pfad gefixt | Zwilling (`*_DOMOAI`) vergessen | Cross-Layer-Recon (P1.3) |
| Agenten-Befund blind geglaubt | halluzinierter/falscher Pfad im Ledger | Anti-Halluzinations-Gate: Source-Abgleich (P1.5) |
| Kopfzahl statt Verifikation | „viele Agenten" → viele Halluzinationen parallel | Recall ≠ Präzision; Verifier + Konsens (P1.5/§5.0) |
| jsdom-only bei UI-Async | grün, Browser rot | `/verify` im echten Browser (P5.2) |
| Unit-only bei Env/Bootstrap | grün, Stack rot | `/verify` nach Clean-Bring-up (P5.2) |
| Stale-Cache/JWT vertraut | falsche Berechtigung | Datenquelle-Frische (P2.4) |
| IP/Geo/VPN als Paywall-Gate | Umgehung per VPN/Inkognito/neuer IP | server-seitiges Account-Entitlement (hardening §3) |
| Webhook ohne Signatur-Verify | gefälschtes „bezahlt"-Event | Signatur + Idempotenz prüfen (hardening §3) |
| Threat-Intel-Refresh übersprungen | brandneue CVE übersehen | Pre-flight (1×/Tag) Pflicht |
| Neuen Helper statt Reuse | wachsender Blast-Radius | Reuse vor Neubau (P4.2) |
| "Done" ohne Beweis | unbemerkte Lücke | DoD + Delivery-Report (P6) |
| Payment/Auth als LOW-FAIL eingestuft | NO-FAIL-Schutz still aus | Tier-Floor-Gate deterministisch (P3.0) |
| Brechende Migration in einem Schritt | alte Version crasht beim Deploy | Expand-Contract, rückwärtskompatibel (P3.4/P7) |
| Rollback = neuer Hotfix-Deploy | Incident dauert zu lang | Kill-Switch ohne Redeploy (P7) |
| Ship ohne Telemetrie | Bug-Meldung kommt vom Kunden | Post-Ship-Observability (P7) |
| Lücke als Folgekommit | 4 statt 1 Commit | Vor Commit melden (Betriebs-Modus 3) |

---

## REFERENZ-DATEIEN (bei Bedarf laden)

- **`references/blast-radius.md`** — Konkrete Recon-Rezepte: Symbol-Suche, Sub-Agent-Fan-out-Templates, der vollständige Cross-Layer-Kopplungs-Katalog, das Symmetrie-Paar-Katalog, die Coverage-Ledger-Vorlage. **Laden in Phase 1, immer bei nicht-trivialem Blast-Radius.**
- **`references/multi-agent.md`** — Multi-Agent-Orchestrierung & Anti-Halluzination: Agenten-Budget nach Risiko-Tier (wie viele wann), disjunkte Stream-Schnitte, Citation-or-void + Source-Abgleich + Konsens-Gate, kalte Zweit-Ableitung, Independent-Verifier-Prompt (Red-Team Ledger↔Diff). **Laden in Phase 1.5 bei Agenten-Fan-out und Phase 5.0 bei NO-FAIL.**
- **`references/modeling.md`** — State-Table-Templates, Invarianten-Katalog, Falsy-Entscheidungsmatrix, Contract-/Idempotenz-/Nebenläufigkeits-Checklisten. **Laden in Phase 2 bei State-/Async-/Daten-Änderungen.**
- **`references/security-pass.md`** — Der Security-Engineer-Schnelldurchgang (Authz/IDOR, Injection-Klassen, Secrets, Open-Redirect/SSRF, Falsy-as-Bypass) + Eskalations-Regel wann die NO-FAIL-`zero-fail-zones.md` zu ziehen ist. **Laden in Phase 2.5, Pflicht bei NO-FAIL.**
- **`references/verification.md`** — Test-Tier-Entscheidungsbaum, jsdom-Fallen-Katalog, Orchestrierung von `/feature-testing` + `/verify` (inkl. `AN /verify`-Handoff), Real-Stack-Smoke-Rezept (Clean-Bring-up), manueller Fallback. **Laden in Phase 3 & 5.**
- **`references/security-hardening.md`** — Enterprise-Härtung gegen die komplette Angriffs-Taxonomie (OWASP + API Security Top 10), AuthN/AuthZ/Session, **Paywall-/Abuse-Resistenz** (VPN/IP/Geo, Coupon-/Trial-Abuse, Webhook-Integrität), Supply-Chain, Header/DoS/Daten. **Laden in P2.5 & P5; Pflicht bei NO-FAIL und bei Payment/Zugang.**
- **`references/threat-intel.md`** — Protokoll des täglichen Threat-Intel-Refresh: Stamp-Mechanismus (1×/Tag pro Projekt), Stack-Erkennung, Such-Quellen (CVE/GHSA/OWASP), Exposure-Check & Eskalation. **Laden in der Pre-flight.**
- **`references/rollout.md`** — Nach-SHIP-Hälfte: Expand-Contract-Rückwärtskompatibilität (nullable-first, dual-write, Feld-/Enum-/Queue-Migration), phasenweiser Rollout + Feature-Flag + Kill-Switch ohne Redeploy, Rollback-Plan (`migration down` getestet, Daten forward-kompatibel), Post-Ship-Observability (Log/Metrik/Alert/Invarianten-Monitor), Zero-Customer-Impact-Sequenzierung. **Laden in Phase 3.4 (Strategie) & Phase 7 (Ausführung) bei Prod-Changes mit aktiven Kunden.**
