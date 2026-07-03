# Token-Router — Always-On-Triage (Single Source of Truth)

> Diese Datei ist die ausführliche Quelle. Ein kompakter Auszug lebt in `~/.claude/CLAUDE.md` (immer geladen, via `hooks/ensure-context.sh`); diese Datei wird bei T2/T3 nachgeladen.
>
> **Zweck:** Vor jeder substanziellen Antwort autonom festlegen — *wie viele Agenten* und *welches Modell pro Rolle* — für minimale Tokens bei gleicher Qualität. Halluzination wird durch **Verifikation** verhindert, nicht durch Kopfzahl.

---

## Schritt 0 — Triage (im Kopf, bevor du handelst)

Bestimme das **Tier** nach Komplexität & Risiko. Im Zweifel **eine Stufe höher**, nie tiefer.

| Tier | Erkennungsmerkmal | Subagenten | Workflow |
|---|---|---|---|
| **T0 — Trivial** | Einzelfrage, Lookup, 1-Zeilen-Edit, Statusabfrage, Konversation | **0**, inline | nie |
| **T1 — Standard** | Feature/Fix/Refactor in bekanntem Bereich, schmaler Blast-Radius, kein NO-FAIL | **0**, inline; Fächer **nur** wenn Blast-Radius real breit | nein |
| **T2 — Komplex / NO-FAIL** | Auth · Payment · Rollen · PII · Migration · cross-layer · multi-repo · breiter/gekoppelter Blast-Radius · Security-Signal | risiko-proportionaler Fächer **per `../feature-delivery/references/multi-agent.md` §1** (Streams A–G; bei NO-FAIL + kalte Zweit-Ableitung + Verifier) | nur wenn die Aufgabe es wirklich braucht |
| **T3 — Explizite Eskalation** | User tippt `ultracode` / „nutze einen Workflow" / „sei erschöpfend/maximal gründlich" | voller Multi-Agent-Fächer, mehr Köpfe | ja |

> **NO-FAIL hebt automatisch auf mindestens T2** — egal wie harmlos die Fachlogik wirkt. Ein `exposed` Threat-Intel-Fund ebenso.

---

## Schritt 1 — Modell pro Rolle (mechanisch, kein Ermessen)

**Hauptmodell (Orchestrator/Hauptschleife) = wie vom User gewählt (Default: das stärkste verfügbare Modell — aktuell Fable 5).** Das wird **nicht** pro Task automatisch umgestellt — der Spar-Hebel sind die **Subagenten-Modelle** (die der Orchestrator pro `Agent`/`Explore`-Call frei wählt) und **wenige Agenten**. Warum das stärkste Modell als Orchestrator: Er ist der höchste Intelligenz-Punkt des Systems (Blast-Radius-Bewertung, Modellierung, Architektur-Entscheid, Mutation) — Top-Tier-Tokens fließen in **Entscheidungen**, nicht in Suche.

| Rolle / Task (Subagent) | Modell-Tier | Warum |
|---|---|---|
| Breiten-Recon, Symbol-Suche, mechanische Scans (grep/WIP/Brand) | **Haiku** (günstig) — **immer explizit setzen** | Recall zählt, nicht Präzision — jede Stelle wird ohnehin am Source gegengelesen. Konkret: `Agent(..., subagent_type: "Explore", model: "haiku", effort: "low")`. |
| Implementierung-Helfer, Standard-Code, lokales Code-Quality-Review | **Sonnet** — **immer explizit setzen** | Solide Qualität, leicht gegen das Kontingent. |
| Independent-Verifier, kalte Zweit-Ableitung, Spec-Compliance (NO-FAIL), harte Architektur/Security-Synthese | **Stärkstes Tier — erbt das Hauptmodell** (KEIN `model`-Parameter; aktuell Fable 5, Fallback Opus). Effort `xhigh`. | Bewertung unter Unsicherheit; ein Verifier-Fehler sperrt die Lieferung. Vererbung statt Namen — siehe 🔒 unten. |

> **🔒 Zukunftssicherheit — Top-Tier NIE per Namen pinnen:** Für Verifier/Synthese den `model`-Parameter **weglassen** → der Subagent erbt das Hauptmodell der Session. Erscheint ein neues Top-Modell (Fable 6 oder ein noch unbekannter Name), zieht das Routing automatisch mit, sobald die Session darauf läuft — ohne Änderung an dieser Datei. **Einzige Ausnahme:** Läuft die Session bewusst auf einem schwächeren Hauptmodell (z.B. `/model sonnet` für Routine-Ops), erbt der Verifier zu schwach → dann explizit das stärkste **bekannte** Modell pinnen (aktuell `model: "fable"`, falls nicht verfügbar `"opus"`).
>
> **Anti-Waste-Guard (hart):** Das Top-Tier-Modell (Fable & Nachfolger) **nie für Recon, mechanische Scans oder Impl-Helfer** — dort kauft es nichts, was das Source-Gate nicht ohnehin liefert. Für diese Rollen ist das Weglassen des `model`-Parameters der Token-Leak → immer explizit Haiku/Sonnet setzen.

> **Default-Session:** Model = stärkstes verfügbares Modell (aktuell Fable 5, User-Wahl), Effort = `xhigh`. `max`/`ultracode` nur bewusst und ad-hoc.
> **Tipp bei langen reinen Routine-/Ops-Sessions:** dem User `/model sonnet` vorschlagen (spart Kontingent spürbar) — aber nie ungefragt das Hauptmodell wechseln.

---

## Schritt 2 — Der Qualitäts-Boden (NIE Teil der Sparmaßnahme)

Läuft unabhängig vom Tier (außer T0-trivial) und wird **nie** wegoptimiert:

- **Anti-Halluzinations-Gate:** Befund ohne `file:line` + wörtliches Zitat → verworfen.
- **Source-Read:** jede gemeldete Stelle selbst mit `Read` öffnen, bevor sie „wahr" ist.
- **Writer ≠ Reviewer:** wer implementiert, bewertet nicht die eigene Arbeit.
- **STOP-bei-kein-Wachstum:** 3 Runden ohne neue Erkenntnis → STOPP. Brute-Force ist Token-Waste; löst **kein** Modell-Upgrade (auch kein Fable-/Top-Tier-Upgrade) und **keine** höhere Kopfzahl aus.

> **Merksatz:** Mehr Agenten kaufen *Recall*, nicht *Präzision*. Gespart wird an Kopfzahl + Recon-Modell. Präzision kommt aus Verifikation — und die ist billig.

---

## Schritt 3 — Transparenz

Bei **T2/T3** eine Zeile vor der Arbeit ausgeben, damit der User korrigieren kann:

```
Triage: T2 · 4 Recon-Agenten (Haiku) · 1 Verifier (Top-Tier, erbt Hauptmodell — aktuell Fable) · Impl Sonnet · Grund: Payment+Auth cross-repo
```

Bei **T0/T1** still arbeiten (keine Triage-Zeile → kein Rauschen).

---

## Schritt 4 — Eskalation & De-Eskalation

- **Hoch:** User-Trigger (`ultracode`, „Workflow", „erschöpfend") → T3. NO-FAIL/Security-Signal → mindestens T2.
- **Runter:** Zeigt sich während T2, dass der Blast-Radius doch schmal ist → auf T1 zurückstufen und im Report notieren. Nicht aus Trägheit Agenten weiterlaufen lassen.
- **`ultracode`-Schutz (zentral):** Auch in einer `ultracode`-Session gilt: **kein** Workflow / **kein** 10+-Agenten-Fächer für T0/T1-Arbeit. `ultracode` *erlaubt* Maximaltiefe, **erzwingt** sie nicht für Trivia. Der „token cost is not a constraint"-Default wird durch diese Triage auf „risiko-proportional" zurückgeholt.

---

## Beziehung zu den Skills

`/feature-delivery`, `/feature-testing`, `/gameboy-gate` haben ihre eigene Tier-Logik (Risiko-Tier, Agenten-Budget). Diese Datei ist der **gemeinsame, immer-aktive Default davor** — sie ersetzt die Skill-Gates nicht, sie sorgt dafür, dass auch **ohne** Skill (jeder normale Prompt) risiko-proportional gearbeitet wird, und dass `ultracode` die Skill-Tier-Logik nicht still auf Maximum zieht.
