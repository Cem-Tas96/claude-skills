# Loop-Engine — autonome Selbst-Prompting-Schleife (Loop Engineering)

> **Kernsatz:** Du schreibst keine Prompts mehr — du baust die Schleife.
> Prompt-Engineering hält dich im Hin-und-Her: du nimmst den Agenten bei jedem Schritt an die Hand. Loop-Engineering dreht das um — du gibst **ein Ziel**, und ein System *promptet den Agenten für dich*: es **findet** die Arbeit, **erledigt** sie, **prüft** sie, **merkt sich** den Fortschritt und **macht weiter, bis es wirklich fertig ist**. `/feature-delivery` IST diese Schleife. Die Phasen P0–P7 sind ihr **Körper**; dieses Dokument ist ihr **Antrieb**.

Dieses Dokument definiert, **wie** der Lauf zur Schleife wird: das durable Checkpoint-Artefakt (das „weiß, wann es fertig war"), die Iterations-Mechanik (ASSESS→ACT→VERIFY→RECORD→DECIDE→CONTINUE), die fünf Bausteine auf konkrete Claude-Code-Primitive abgebildet, und — am wichtigsten — **warum „immer loopen" nicht „immer maximale Automatik" heißt.**

---

## 0. Die fünf Bausteine → konkrete Mechanismen

Loop-Engineering steht auf fünf Bausteinen. Jeder ist in Claude Code ein **realer** Mechanismus — kein Konzept, sondern ein Tool/Skill/Hook, den dieser Lauf benutzt:

| Baustein | Wozu | Konkreter Mechanismus in diesem Lauf |
|---|---|---|
| **1 Automation** | läuft von allein weiter, statt nur auf Befehl | Je nach Harness (Verfügbarkeit via `ToolSearch` prüfen, nicht annehmen): `/loop` (Intervall/selbst-getaktet) · `ScheduleWakeup` (Selbst-Wiederaufruf im `/loop`-Dynamic-Mode) · `Monitor` (ereignisgetriebenes Warten auf externe Events) · `/schedule`+`CronCreate` (Routinen) · `settings.json`-Hooks (SessionStart/Stop/PostToolUse, via `/update-config`). **Stop-Bedingung jeder Automatik = die DoD (P6.1).** |
| **2 Worktrees** | zwei Agenten gleichzeitig, ohne sich in die Quere zu kommen | `EnterWorktree`/`ExitWorktree` · `isolation:"worktree"` in `Agent`/`Workflow`. Hebt das Branch-Safety-Gate (Pre-flight 1b) zum **Isolations-Gate**. |
| **3 Skills** | Projekt nicht jedes Mal neu erklären | Dieser Skill + Sub-Skills (`/feature-testing` · `/verify` · `/security-review` · `/code-review` · `/simplify`) + `CLAUDE.md`/`AGENTS.md`-Projektkontext. Schon Kern des Skills. |
| **4 Connectors** | wirklich deine Tools bedienen | MCP-Connectoren via `ToolSearch` — **Notion** (Spec-Source-of-Truth P1.8: `notion-fetch`/`notion-search`), **M365** (Outlook/SharePoint), Ticket-/Chat-Systeme. Quelle der Wahrheit **ziehen**, Report **zurückschreiben**. |
| **5 Subagents** | wer schreibt ≠ wer prüft | `Explore`/`Agent`-Subagenten. Der Orchestrator **mutiert**, frische Subagenten **verifizieren** (`multi-agent.md`). Writer und Reviewer sind nie derselbe. |

> Baustein 3 und 5 trägt der Skill schon im Kern; dieses Dokument **operationalisiert 1, 2, 4** und bindet alles zur Schleife zusammen.

---

## 1. Das Gesetz: „immer loopen" ≠ „immer maximale Automatik"

Die Schleife läuft bei **jedem** Aufruf — aber ihre **Autonomie-Tiefe** skaliert mit der Arbeit, exakt wie Agenten-Kopfzahl und Risiko-Tier (SKILL.md §3, `multi-agent.md` §1). Sonst bricht der Skill sein eigenes Anti-Brute-Force-Gesetz (KERNPHILOSOPHIE: „Brute-Force-Loops sind kein Skill, sondern Token-Waste").

**Was IMMER läuft (der Antrieb, unverhandelbar):**
- ein **Ziel** als Contract (P0),
- ein **Checkpoint** (§2) der den Fortschritt durable hält,
- eine **DONE-Bedingung** (die DoD P6.1) gegen die jede Iteration prüft,
- **Selbst-Prompting**: nach jeder Iteration leitet der Lauf die nächste Arbeit selbst ab — keine Rückfrage „und jetzt?".

**Was TIERED ist (die Automatik-Mechanik, kostenproportional):**

| Lage | Automation-Modus | Worktree | Subagent-Verifikation |
|---|---|---|---|
| trivial / 1 Datei / BEST-EFFORT | **inline**, kein Scheduling | nein (Branch reicht) | Selbst-Audit |
| LOW-FAIL, normal | **inline** Selbst-Prompting | optional | Selbst-Audit, Verifier ab Risiko-Signal |
| wartet auf externen Zustand (CI · Deploy · Migrations-Fenster · externes Review) | **`Monitor`** (ereignisgetrieben, bevorzugt) **oder** **`ScheduleWakeup`** (selbst-getaktetes Pollen) — der Lauf taktet seinen Wiederaufruf selbst | je nach Change | unabhängiger Verifier |
| wiederkehrende Pflicht (z.B. nächtliches Vorantreiben offener Loops, täglicher Threat-Intel) | **`/schedule`+`CronCreate`** Routine | je nach Change | unabhängiger Verifier |
| **parallele** Features / parallele mutierende Agenten | inline + **`isolation:"worktree"`** je Strang | **ja** — Pflicht | unabhängiger Verifier je Strang |

> **Faustregel:** Cron/Worktree/Wake-up sind **Mittel gegen ein konkretes Problem** (Warten · Parallelität), kein Default-Zierrat. Ein Einzeiler-Fix in inline-Modus IST eine vollständige Loop-Engine — er durchläuft denselben Antrieb, nur ohne Scheduling-Maschinerie. Wer für `fix typo` eine Cron-Routine anlegt, hat Loop-Engineering missverstanden.

---

## 2. Der Loop-Checkpoint — das Artefakt, das „weiß, wann es fertig war"

Eine echte Schleife überlebt Context-Kompaktierung und Wake-ups. Der **in-context** Coverage-Ledger (P1.9) ist flüchtig; der Checkpoint ist sein **durabler Spiegel** plus Loop-Zustand. Ohne ihn ist der „Loop" nur ein Einmal-Lauf mit Loop-Vokabular.

**Pfad (parallel zum Threat-Intel-Stamp):**
```
~/.claude/.cache/feature-delivery/<slug(pwd)>.loop.json
   slug(pwd): Arbeitsverzeichnis, führender Slash weg, restliche „/" → „-"
```
Existiert die Datei beim Aufruf → **resumen** (Zustand laden, ab `phaseCursor` weiter, DONE-Bedingung neu prüfen). Fehlt sie → **neuer Loop** (Contract P0 schreiben, Checkpoint anlegen).

**Schema (knapp, maschinenlesbar):**
```json
{
  "goal":            "<Contract WAS — 1 Satz>",
  "invariant":       "<Contract INVARIANTE>",
  "acceptance":      ["GEGEBEN/WENN/DANN …"],
  "branch":          "feature/…",
  "worktree":        "<pfad | null>",
  "tier":            "NO-FAIL | LOW-FAIL | BEST-EFFORT",
  "automationMode":  "inline | event | wakeup | cron",
  "phaseCursor":     "P0|P1|…|P7|DONE",
  "ledger":          [{ "id":"C1", "stelle":"file:line", "art":"Caller", "status":"offen|✓|N/A" }],
  "iterations":      [{ "n":1, "did":"…", "coverageDelta":3, "verdict":"weiter", "ts":"<von außen gestempelt>" }],
  "coverageStall":   0,
  "doneBoxes":       { "ledger0offen": false, "tests": false, "verify": false, "security": false, "e2e": false, "rollout": false },
  "status":          "RUNNING | SHIP | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKIERT",
  "blockReason":     "<file:line/Artefakt | null>"
}
```

**Lebenszyklus:**
1. **Aufruf/Wake-up:** Checkpoint lesen. Vorhanden → Resume; sonst neu anlegen nach P0.
2. **Nach jeder Iteration:** `ledger`, `phaseCursor`, `iterations[]`, `coverageStall`, `doneBoxes`, `status` schreiben. Der Schreibvorgang ist die einzige „Wahrheit", auf die ein Wiederaufruf vertrauen darf.
3. **DONE:** `status` auf SHIP / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKIERT (Graded-Status P6.2b). Bei SHIP nach Rollout/Branch-Finish den Checkpoint **archivieren oder löschen** — ein erledigter Loop darf einen Folge-Lauf nicht fälschlich „resumen".

> **Zeitstempel-Disziplin:** Workflow-Skripte haben kein `Date.now()`. Den `ts` von außen stempeln (Orchestrator schreibt das Systemdatum), nicht im Subagenten erzeugen — sonst bricht Resume-Determinismus. Konsistent mit dem Threat-Intel-Stamp (`lastCheck`).

---

## 3. Die Iteration — ASSESS → ACT → VERIFY → RECORD → DECIDE → CONTINUE

Jede Runde der Schleife durchläuft dieselben sechs Schritte. Das ist das „System, das den Agenten für dich promptet": der Lauf stellt sich die nächste Frage selbst.

```
┌─ ASSESS  ── Checkpoint + Ledger lesen. Nächste UNERLEDIGTE Arbeit bestimmen
│            (erste `offen`-Zeile / nächste Phase ab phaseCursor / offener Verifier-Befund).
│            → „Was ist das nächste, das fertig sein muss?" — nicht gefragt, abgeleitet.
│
├─ ACT     ── Genau diese eine Arbeit tun (Orchestrator mutiert; bei Parallelität Worktree-Strang).
│            Symmetrische Paare zusammen (P4.1). Keine Stelle „später".
│
├─ VERIFY  ── FRISCHER Subagent prüft (writer ≠ reviewer, §6): Ledger↔Diff-Kreuzaudit (SKILL.md P5.0),
│            Staged-Review (SKILL.md P5.0b), /feature-testing · /verify · /security-review je nach Phase.
│            Output durch das Anti-Halluzinations-Gate (multi-agent.md §3).
│
├─ RECORD  ── Checkpoint schreiben: Zeile(n) ✓/N/A, phaseCursor vor, Iteration + coverageDelta loggen.
│            coverageDelta = neue ✓- + neue erfasste Stellen dieser Runde.
│
├─ DECIDE  ── DONE-Bedingung prüfen (§4):
│            • alle DoD-Boxen ✔, 0 `offen`  → STATUS terminal (SHIP/…); Schleife ENDET.
│            • Arbeit offen, coverageDelta>0 → weiter (coverageStall=0).
│            • coverageDelta==0              → coverageStall++; bei 3 → ESKALIEREN (§4), nicht hämmern.
│            • braucht Entscheidung/Info     → NEEDS_CONTEXT (die EINE Frage), Schleife pausiert.
│            • harter Code-/Daten-/Sec-Bug   → BLOCKIERT (Root-Cause file:line), Schleife pausiert.
│
└─ CONTINUE ─ inline-Modus: direkt nächste Iteration (Selbst-Prompt).
             wakeup/cron-Modus: nächsten Wiederaufruf takten (§7), Checkpoint ist der Übergabe-Zustand.
```

> Der Unterschied zum klassischen Lauf: **DECIDE und CONTINUE sind explizit.** Der Lauf hört nicht auf, weil „der Prompt zu Ende ist", sondern weil die **DONE-Bedingung erfüllt** oder eine **Stop-Bedingung** erreicht ist. Genau das ist „macht weiter, bis es wirklich fertig ist".

---

## 4. DONE-Bedingung & Stop-Garantien (wann die Schleife endet)

Die Schleife hat **eine** Erfolgs-Endbedingung und **drei** Stop-Garantien — alle existieren im Skill schon, der Loop-Engine macht sie nur zur formalen Exit-Logik.

**DONE (Erfolg):** die **DoD-Checkliste P6.1** vollständig ✔ **und** 0 `offen` im Ledger **und** Verifikation (P5) bestanden. Dann `status = SHIP` (oder DONE_WITH_CONCERNS, wenn nur benannte, dokumentierte Reste übrig sind — P6.2b). Das ist die einzige Bedingung, unter der die Schleife „fertig" sagt.

**STOP-1 — Coverage-Diminishing-Returns (Anti-Brute-Force):** 3 Iterationen mit `coverageDelta==0` (keine neue Ledger-Zeile, keine neue ✓) → **ESKALIEREN statt hämmern**. Das Verbleibende braucht ein **anderes Werkzeug**, kein weiteres Loopen:
- echter Klick-Through (P5.5) statt noch ein Test,
- eine **Spec-Quelle/Connector** (P1.8, §8) statt halluzinierter Text,
- eine **menschliche Entscheidung** (→ NEEDS_CONTEXT),
- oder das Ziel ist außerhalb der erreichbaren Coverage (→ ehrlich DONE_WITH_CONCERNS/BLOCKIERT mit Grund).
> Loop-Disziplin triggert **kein** Modell-Upgrade und keine höhere Agenten-Kopfzahl — dieselbe erschöpfte Suche teurer ist kein neuer Erkenntnis-Hebel (`multi-agent.md` §1.6).

**STOP-2 — NEEDS_CONTEXT:** hängt an einer Entscheidung/Information, nicht an Code (Boss-OK · Spec-Klärung · fehlender Zugang). Die **eine** gebündelte Frage an den Owner, Checkpoint pausiert, kein Merge.

**STOP-3 — BLOCKIERT:** offene Code-/Daten-/Sicherheits-Lücke (Ledger `offen` · Verifier-Befund · `/verify`-Bruch · kritisches Security-Finding). Root-Cause `file:line` in `blockReason`, nichts verlässt den Branch.

> **Selbst-Prompting heißt nicht selbst-genehmigend.** Die Schleife darf sich NIE selbst SHIP geben, solange eine DoD-Box offen ist — der Checkpoint-`status` ist an `doneBoxes` gekoppelt, nicht an „der Agent ist zufrieden". Ein Loop ohne harte DONE-Bedingung ist ein Endlos-Token-Brenner.

---

## 5. Hooks zwischen Loop-Engine und den bestehenden Phasen

Der Loop-Engine ersetzt **nichts** in P0–P7 — er ordnet sie als Schleifen-Körper an:

| Loop-Schritt | Bestehende Phase(n) |
|---|---|
| GOAL setzen | P0 Auftrags-Contract |
| ASSESS (Arbeit finden) | P1 Blast-Radius → Coverage-Ledger · Pre-flight (Threat-Intel/WIP/Baseline) |
| ACT (Arbeit tun) | P4 Implementierung (Ledger abarbeiten) |
| VERIFY (prüfen) | P5 (Kreuzaudit · Staged-Review · `/feature-testing` · `/verify` · `/security-review` · E2E) |
| RECORD (merken) | Checkpoint-Schreibvorgang (§2) — spiegelt Ledger + Status |
| DECIDE (fertig?) | P6 DoD + Graded-Status |
| CONTINUE (weiter) | P7 Rollout/Branch-Finish **oder** nächste Iteration |

> Die Pre-flight-Gates (Threat-Intel · Branch/Worktree-Isolation · WIP · Baseline) laufen in der **ersten** Iteration; bei Resume aus dem Checkpoint nur, was der `phaseCursor` noch nicht passiert hat (Threat-Intel höchstens 1×/Tag, §0-Stamp).

---

## 6. Subagent-Invariante: Writer ≠ Reviewer (Baustein 5)

Der fünfte Baustein ist eine **Trennung**, kein Werkzeug: wer den Code schreibt, ist nicht, wer ihn prüft und bewertet. Im Loop-Engine ist das eine harte Invariante des VERIFY-Schritts:

- **Der Orchestrator (Writer)** mutiert — im ACT-Schritt, in einem kohärenten Change.
- **Frische `Explore`-Agenten (Reviewer)** verifizieren — im VERIFY-Schritt, read-only, ohne die Implementierung „verteidigen" zu wollen. Nie ein Recon-Stream, der nur seine eigene Arbeit bestätigt (`multi-agent.md` §4).
- **Beim Workflow-Pattern** (Review-Phase): die `agent()`-Verifier laufen mit eigenem, von der Implementierung unbeeinflusstem Kontext; ihr Urteil durch dasselbe Anti-Halluzinations-Gate.

> Warum die Trennung den Loop trägt: ein Agent, der sich selbst prüft, schreibt sich selbst SHIP. Die DONE-Bedingung (§4) ist nur so ehrlich wie die Unabhängigkeit ihres Prüfers. Darum ist „writer ≠ reviewer" kein Stil — es ist die Voraussetzung dafür, dass „fertig" etwas bedeutet.

---

## 7. Automation operationalisiert (Baustein 1)

**inline (Default):** kein Scheduling. Der Lauf promptet sich selbst von Phase zu Phase innerhalb der Session. Für die meisten Changes der vollständige Loop.

**Warten auf externen Zustand (ereignisgetrieben bevorzugt):** wenn der nächste sinnvolle Schritt erst nach einem externen Ereignis möglich ist (CI grün · Deploy durch · Migrations-Fenster offen · externes Review eingetroffen). Welche Primitive der Harness bereitstellt, via `ToolSearch` prüfen — nicht annehmen:
- **`Monitor`** (wenn vorhanden): wartet ereignisgetrieben auf den Event-Stream — kein Polling, reagiert sofort. Erste Wahl, wenn der Zustand als Event ankommt.
- **`ScheduleWakeup`** (selbst-getaktetes Pollen im `/loop`-Dynamic-Mode): der Lauf schreibt den Checkpoint und taktet seinen eigenen Wiederaufruf. Delay nach Cache-Fenster wählen (<5 min = Cache warm fürs aktive Pollen; 20–30 min als Idle-Heartbeat). Beim Feuern: Checkpoint lesen → resumen.
- **Fallback:** fehlt beides, auf `/loop` mit festem Intervall oder eine `/schedule`-Routine ausweichen.
> Kein Kurz-Intervall-Polling für Arbeit, die der Harness ohnehin meldet (Hintergrund-Tasks rufen dich beim Abschluss zurück). Self-Wakeup/Monitor ist für Zustände, die der Harness **nicht** signalisiert (externe CI/Deploy/Queue).

**`/schedule` + `CronCreate` (wiederkehrende Pflicht):** für Routinen, nicht für Einzel-Tasks — z.B. „jeden Morgen offene feature-delivery-Loops in diesem Repo voranbringen", oder den täglichen Threat-Intel-Refresh als Routine statt als Pre-flight-Stamp. Braucht bewusste Einrichtung; nie als Default für einen einzelnen Change.

**`settings.json`-Hooks:** automatisierte Verhaltensweisen, die der **Harness** ausführt (nicht der Agent) — SessionStart (z.B. der Skills-Auto-Pull dieses Repos), Stop, PostToolUse. Hooks sind die „läuft von allein"-Schicht unter der Schleife. Konfiguration via `/update-config` (sie schreibt `settings.json`).

> **Stop-Bedingung jeder Automatik bleibt die DoD (§4).** Eine Wake-up-Kette oder Cron-Routine ohne DONE-Bedingung ist ein unbeaufsichtigter Token-Brenner — genau das, was der Skill verhindert. Jede geplante Wiederaufnahme prüft zuerst den Checkpoint-`status`; ist er terminal, terminiert die Automatik.

---

## 8. Connectors operationalisiert (Baustein 4)

Connectoren machen aus „STOP und frag den Boss" ein „STOP, **zieh die Quelle**, dann weiter" — und schließen so eine der teuersten Loop-Stalls (Warten auf eine Information, die ein Tool liefern kann).

- **Spec-Source-of-Truth (P1.8):** ist ein Notion/CMS/Ticket-Connector verbunden, die Quelle **direkt ziehen** (`notion-search`/`notion-fetch` via `ToolSearch`) statt UI-Text zu halluzinieren. Der Wert im Code wird Zeichen-für-Zeichen gegen die gezogene Quelle geprüft — exakt der P1.8-Diff, nur ohne Rückfrage.
- **Tickets/Anforderungen:** Contract-Lücken (P0) aus dem verlinkten Ticket/der Notion-Page füllen, statt anzunehmen.
- **Report zurückschreiben:** den Delivery-Report (P6.2) in die Quelle zurück (Notion-Page-Update / Ticket-Kommentar), wenn der Connector da ist — der Loop „bedient deine Tools", statt nur zu lesen.
- **Verfügbarkeit prüfen, nicht annehmen:** Connectoren via `ToolSearch` laden; fehlt der Connector (z.B. headless/cron-Lauf ohne interaktive Auth), auf den normalen P1.8-STOP-und-frag-Pfad zurückfallen und das im Report notieren.

> Connector-Funde durchlaufen dasselbe Quellen-Gate wie alles andere: ein gezogener Notion-Wert ist eine **benannte Quelle** (URL/Page-ID) — das macht ihn legitim. „Aus dem Modell" bleibt verboten, auch wenn ein Connector verfügbar gewesen wäre.

---

## 9. Worktree-Isolation operationalisiert (Baustein 2)

Das Branch-Safety-Gate (Pre-flight 1b) verhindert Edits auf dem Default-Branch. Der Loop-Engine erweitert es zum **Isolations-Gate**, sobald Parallelität ins Spiel kommt:

- **Sequenzieller Einzel-Change:** Arbeits-Branch genügt (wie bisher). Kein Worktree-Overhead.
- **Parallele mutierende Stränge** (zwei Features gleichzeitig · ein Workflow, dessen `agent()`-Stränge Dateien schreiben): **`isolation:"worktree"`** je Strang — jeder Agent arbeitet auf einer isolierten Repo-Kopie, keine Kollision im Arbeitsbaum. `EnterWorktree`/`ExitWorktree` für interaktive Stränge.
- **Kosten bewusst:** Worktree-Setup kostet (Disk + ~hunderte ms je Agent). Nur ziehen, wenn echte Parallel-Mutation droht — read-only Recon/Verifikation (`Explore`) braucht **keinen** Worktree (sie schreiben nichts).
- **Checkpoint-Feld `worktree`** hält den Pfad; beim Merge-/Finish-Schritt (P7.1) den Worktree sauber zurückführen (`ExitWorktree`, auto-cleanup wenn unverändert).

> Der Wert des Worktrees ist genau der Satz aus dem fünften Baustein-Block: „zwei Agenten, die gleichzeitig arbeiten, kommen sich nicht in die Quere". Ohne echte Parallel-Mutation ist er Zierrat.

---

## 10. Anti-Patterns — was hier stirbt

| Anti-Pattern | Symptom | Gegenmittel |
|---|---|---|
| Hand-Holding statt Schleife | Agent fragt nach jedem Schritt „und jetzt?" | Selbst-Prompting: ASSESS leitet die nächste Arbeit aus dem Ledger ab (§3) |
| Loop ohne Checkpoint | Context-Kompaktierung/Wake-up → Fortschritt verloren, fängt von vorn an | durabler Checkpoint, bei jeder Iteration geschrieben (§2) |
| Loop ohne DONE-Bedingung | Endlos-Token-Brenner / selbst-vergebenes SHIP | DoD = harte Exit-Logik, `status` an `doneBoxes` gekoppelt (§4) |
| „immer maximale Automatik" | Cron-Routine + Worktree für einen Einzeiler | tiered Autonomie — inline ist der Default (§1) |
| Brute-Force-Loop | 3+ Iterationen ohne neue Coverage, weiter hämmern | Diminishing-Returns-Stopp → anderes Werkzeug (§4 STOP-1) |
| Writer prüft sich selbst | Agent schreibt sich selbst SHIP | frischer Reviewer-Subagent, writer ≠ reviewer (§6) |
| Wake-up-Polling für getrackte Arbeit | Cache verbrannt fürs Pollen, was der Harness ohnehin meldet | Wake-up nur für extern-untrackbare Zustände (§7) |
| Connector-Wert ungeprüft als Wahrheit | falscher Spec-Wert aus alter Notion-Page live | Connector-Fund = benannte Quelle, trotzdem Zeichen-für-Zeichen-Diff (§8) |
| Worktree als Default-Zierrat | Disk/Zeit-Overhead ohne Parallel-Mutation | Worktree nur bei echter Parallel-Mutation (§9) |
| Terminal-Loop „resumed" weiter | erledigter Loop blockiert/verwirrt Folge-Lauf | bei SHIP Checkpoint archivieren/löschen (§2 Lebenszyklus) |

---

## 11. Selbstaudit Loop-Engine (vor SHIP)

- [ ] **Checkpoint geführt** — bei jeder Iteration geschrieben, spiegelt Ledger + Status (§2)?
- [ ] **DONE-Bedingung formal** — `status` an DoD-Boxen gekoppelt, kein selbst-vergebenes SHIP (§4)?
- [ ] **Autonomie-Tier passend** — inline für Normal-Change; Wake-up/Cron/Worktree nur gegen ein konkretes Warten/Parallel-Problem (§1)?
- [ ] **Writer ≠ Reviewer** — VERIFY-Schritt durch frischen Subagenten, nicht durch den Mutierenden (§6)?
- [ ] **Diminishing-Returns respektiert** — kein 3×-Null-Coverage-Hämmern; bei Stall eskaliert auf anderes Werkzeug (§4 STOP-1)?
- [ ] **Connector-Quellen benannt** — gezogene Spec-Werte mit Quell-ID, gegen Code ge-difft (§8)?
- [ ] **Automatik hat Stop** — jede geplante Wiederaufnahme prüft Checkpoint-`status`, terminiert bei terminal (§7)?
- [ ] **Terminal aufgeräumt** — bei SHIP Checkpoint archiviert/gelöscht, kein Geister-Resume (§2)?

> Kannst du diese Boxen nicht ehrlich abhaken, hast du keinen Loop gebaut — du hast einen Einmal-Lauf mit Loop-Vokabular. Der Antrieb (§1: Ziel · Checkpoint · DONE-Bedingung · Selbst-Prompting) ist das, was die Schleife zur Schleife macht.
