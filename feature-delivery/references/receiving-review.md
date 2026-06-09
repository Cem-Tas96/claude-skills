# Externes Review empfangen & Feedback verarbeiten

> **Gegenstück zu `staged-review.md`:** Dort *geben* wir Review (eigene frische Agenten prüfen unseren Diff). Hier kommt Feedback von **außen** — Mensch (Boss/Peer/Auditor), Tool (`/code-review`, Linter, Security-Scanner) — und wir müssen es **verarbeiten statt annehmen**.
>
> **Kernprinzip:** Jeder externe Befund ist eine **Hypothese**, keine Wahrheit. Der Reviewer kennt Contract, Architektur-Gründe, Trade-offs und Legacy-Restriktionen meist nicht. Wir validieren **jeden** Befund — und schieben mit Code-/Test-Beleg zurück, wenn der Reviewer *real-aber-falsch* liegt. (Projekt-agnostisch: rein methodisch, keine Stack-Annahme.)

---

## 0. Wann dieses Protokoll greift
Während Phase 5 (oder vor/nach Commit, solange der Change offen ist) kommt Feedback an: menschlicher Review, Tool-Finding, fehlgeschlagener Policy-/Architektur-Check. **Nicht** dieses Protokoll: ein eindeutig richtiger Befund / unser klarer Fehler (Syntaxfehler, echte Lücke) → direkt fixen.

## 1. Klassifizieren (jeden Befund einordnen)
Findings ohne `Claim + Evidence (file:line) + Impact` → **einmal gebündelt klären**, nicht interpretieren.

| Typ | Frage | Handeln |
|---|---|---|
| **Real + Breakage** | echter Laufzeit-Bug? | sofort fixen (kein Schach) |
| **Real + kontext-blind** | technisch richtig, aber Grund/Trade-off unbekannt? | **Pushback mit Beleg** (§3) |
| **Stil / Grau** | Idiom-/Naming-Bruch? | NO-FAIL: fixen; sonst dokumentieren & weiter |
| **Halluziniert** | zeigt auf Code, der so nicht existiert? | Source-Abgleich → widerlegen |
| **Unklar** | zu vage zum Prüfen? | eine gebündelte Klär-Rückfrage |

## 2. Validieren (drei Checks, am Source)
- **Laufzeit-Check:** Test schreiben, der den behaupteten Bug triggert. Rot → fixen → grün. Grün → Halluzination (raus).
- **Kontext-Check:** Gibt es einen dokumentierten Grund? `git log`/`blame` der Stelle, `CLAUDE.md`/`AGENTS.md`/ADR. Legacy-Restriktion, Feature-Flag-Phase, Ext-API-Eigenheit, bewusst akzeptiertes Risiko?
- **Lokal vs. Querschnitt:** Ist es eine Einzelstelle oder ein Muster, das **überall** gleich wäre? Querschnitt → alle Stellen fixen + Test (oder Ledger erweitern + **vor Commit melden**).

## 3. Pushback-Protokoll (begründetes „Nein" mit Substanz)
Bei *real-aber-kontext-blind*: nicht als Meinung, sondern als **Beleg** zurückschieben:
```
REVIEWER:  [Finding, 1–2 Sätze]
KONTEXT:   [konkreter Grund — Legacy / Flag / Trade-off / Ext-API / ADR]
EVIDENZ:   [Commit-Hash | CLAUDE.md-Stelle | Test der das Pattern absichert | Benchmark]
URTEIL:    [bleibt — hier korrekt; entfällt die Restriktion später → nachgelagerter Cleanup (Link)]
```
**Sofort fixen statt Pushback**, wenn: Laufzeit-Fehler · kategorische Regel (Security „keine Secrets in Logs", Codebase-Stil) · Security/Compliance-Tool mit echter Exposure (→ NO-FAIL blockt).

## 4. Eskalation
- **Unklar** → eine gebündelte Klär-Rückfrage (kein Ping-Pong).
- **Konflikt mit früherer Human-/Architektur-Entscheidung** → an Owner **eskalieren**, nicht eigenmächtig auto-anwenden.
- **Architektur-/Business-Streit** (nicht technisch entscheidbar) → mit Kontext + beiden Positionen + Entscheidungskriterium an den Owner; er entscheidet.

## 5. Ledger-Integration
Bestätigte externe Bugs → eigene Ledger-Zeilen `E1 | file:line | External-Bug | … | Status`. Widerlegte Findings (Halluzination/kontext-blind) → **nicht** ins Ledger (kein eigener Fehler), aber Entscheidung in der Commit-Message/Report dokumentieren.

## 6. Selbstaudit (vor SHIP, wenn externes Feedback ankam)
- [ ] Jeder Befund klassifiziert (Real/kontext-blind/halluziniert/unklar)?
- [ ] Real-Bugs: Laufzeit-Test RED→GREEN geschrieben?
- [ ] Pushback nur mit Code-/Git-/Test-Beleg, nicht als Diskurs?
- [ ] Unklares **einmal** gebündelt geklärt; Konflikt mit Vorentscheidung eskaliert (nicht auto-angewandt)?
- [ ] Echte externe Bugs als E-Ledger-Zeilen erfasst?

> **Verhältnis zu anderen Schichten:** `staged-review.md` (eigene Agenten gegen Contract), `multi-agent.md` §4 (Independent-Verifier Ledger↔Diff) — **dies** ist die einzige Schicht, die Feedback von *außerhalb* des Skills behandelt. Sie wiederholt deren Gates nicht, sie nutzt sie (Source-Abgleich aus `multi-agent.md` §1.5).
