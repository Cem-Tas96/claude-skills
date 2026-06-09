# Staged Review — Zwei-Stufen-Implementierungs-Review durch frische Agenten

> **Kernsatz:** Der Independent-Verifier (`multi-agent.md` §4) prüft **Coverage** — „ist jede Stelle angefasst, nichts erfunden?". Er beantwortet **nicht** „ist das *Richtige* gebaut?" und **nicht** „ist es *gut* gebaut?". Das sind drei verschiedene Linsen, und ein einziger Agent, der alle drei gleichzeitig durch denselben Kontext sieht, verwischt sie. Darum: **getrennte, frische Agenten — erst Spec-Compliance, dann Code-Quality** — und nie umgekehrt.

Adaptiert aus dem `subagent-driven-development`-Pattern (obra/superpowers): Zwei-Gate-Review *nach* der Implementierung. Bewusst **nicht** deren „Implementer-Subagent pro Task" übernommen — dieser Skill hält Mutation im Orchestrator (ein kohärenter Change, read-only Recon). Übernommen ist nur die wertvolle Hälfte: **die zwei Review-Linsen als separate frische Augen.**

---

## 0. Warum zwei Stufen, warum diese Reihenfolge

- **Spec-Compliance ZUERST.** Sie fängt **Scope-Fehler** — over-building (Features die niemand wollte) und under-building (Akzeptanz-Kriterium nicht erfüllt). Diese vor der Quality-Linse zu fangen ist billig: es hat keinen Sinn, die Code-Qualität von Code zu polieren, der das Falsche tut oder zu viel tut. Quality-Review von wegzuwerfendem Code ist doppelt verschwendet.
- **Code-Quality DANACH.** Erst wenn feststeht *dass das Richtige gebaut wurde*, lohnt der Blick auf *wie gut*: Lesbarkeit, Duplizierung, Fehlerbehandlung, Namens-/Idiom-Konsistenz mit dem Umfeld, tote Pfade.
- **Frische Agenten, nicht der Orchestrator.** Der Orchestrator hat die Implementierung geschrieben — er ist betriebsblind für die eigenen Annahmen. Ein frischer `Explore`-Agent sieht nur Contract + Diff, ohne die Rechtfertigungs-Geschichte im Kopf. Das ist derselbe Grund wie beim Independent-Verifier: eine *von der Implementierung unbeeinflusste* Sicht.

> Reihenfolge ist nicht verhandelbar: **Code-Quality-Review startet NIE, bevor Spec-Compliance grün ist.** Sonst poliert man potenziell weg-zu-werfenden Code.

---

## 1. Wann (Risiko-proportional — wie der Rest des Skills)

Gleiches Prinzip wie `multi-agent.md` §1: nicht „immer", sondern an die Blast-Radius-Form gebunden. Self-Review (Orchestrator führt beide Linsen selbst durch) ist die billige Baseline; **frische Agenten** sobald ein Risiko-Signal vorliegt.

| Tier / Lage | Spec-Compliance | Code-Quality |
|---|---|---|
| **BEST-EFFORT** / trivial, 1 Datei | entfällt (Contract trivial) | entfällt |
| **LOW-FAIL** / schmal, kein Risiko-Signal | **Self-Review** (Orchestrator gegen P0-Contract) | **Self-Review** |
| **LOW-FAIL + Risiko-Signal** | **frischer `Explore`-Agent** | **frischer `Explore`-Agent** |
| **NO-FAIL** / Auth·Payment·Rollen·PII·Migration | **frischer Agent — Pflicht** | **frischer Agent — Pflicht** |

**Risiko-Signal** (identisch zu `multi-agent.md` §1): >8 Ledger-Zeilen · Symmetrie-Paar berührt · Cross-Layer-Kopplung · überhaupt Sub-Agenten gefächert. Ein `exposed` Threat-Intel-Fund oder offenes Security-Finding hebt auf NO-FAIL → beide Stufen mit frischem Agent.

> Der Staged-Review ist **eine eigene Linse neben** dem Ledger↔Diff-Kreuzaudit (`multi-agent.md` §4), nicht sein Ersatz. Kreuzaudit = „fehlt/erfunden" (Coverage). Staged-Review = „richtig gebaut?" (Spec) + „gut gebaut?" (Quality). Bei NO-FAIL laufen beide.

---

## 1.5 Severity-Kalibrierung & SHA-Anker (für beide Stufen)

**Severity je Befund** — Reviewer-Output dreistufig statt nur „blockierend/nicht", gegen Über-Blocking:

| Severity | blockiert bei | Beispiele |
|---|---|---|
| **CRITICAL** | allen Tiers | Akzeptanz-Kriterium nicht erfüllt · Security/Payment-Lücke · unbehandelter Fehler-/Falsy-Fall auf kritischem Pfad · fehlende Reverse-/Counter-Mail |
| **IMPORTANT** | nur NO-FAIL | Duplizierung existierender Logik · Idiom-Bruch der Wartung hemmt · Race im Edge-Szenario · unvollständige Spec-Quelle |
| **MINOR** | nie | Lesbarkeit/Naming ohne Wartungs-Folge · Kommentar-Genauigkeit · Stil-Varianz |

Auflösungs-Reihenfolge: CRITICAL → IMPORTANT → MINOR. **Nicht alles ist CRITICAL** — Über-Blocking entwertet die Kategorie. (Mapping auf §2/§3: CRITICAL + IMPORTANT-bei-NO-FAIL = die bisher „blockierenden" Befunde; MINOR = dokumentieren, nicht erzwingen.)

**SHA-Anker** — Reviewer-Agenten erhalten die **exakte Diff-Grenze** statt „der Diff": `BASE_SHA..HEAD_SHA`, vom Orchestrator vor dem Fan-out ermittelt (`git merge-base <default> HEAD` → BASE · `git rev-parse HEAD` → HEAD). So ist die Review reproduzierbar; ein Befund auf einer Zeile **außerhalb** der Range ist per Definition Halluzination (greift ins §3-Gate). `BASE_SHA`/`HEAD_SHA` im Delivery-Report festhalten. *Projekt-agnostisch — reine git-Mechanik; kein Git → die Anker entfallen, Review läuft gegen den Working-Diff.*

> Beide Prompt-Vorlagen unten erhalten zusätzlich die Zeile: *„Die Änderung umfasst nur `BASE_SHA..HEAD_SHA`; Zeilen, die in BASE_SHA unverändert existieren, sind außerhalb der Review. Versieh jeden Befund mit Severity (CRITICAL|IMPORTANT|MINOR)."*

---

## 2. Stufe 1 — Spec-Compliance-Reviewer

**Input:** P0-Contract (Auftrag + Akzeptanz-Kriterien) + Spec-Source-of-Truth-Quellen (P1.8) + git-Diff. **Kein** Ledger — diese Linse prüft *gegen die Absicht*, nicht gegen die eigene Stellen-Liste.

**Prompt-Vorlage:**

```
Du bist Spec-Compliance-Reviewer. Du hast (1) den Auftrags-Contract + Akzeptanz-Kriterien,
(2) ggf. benannte Spec-Quellen (Notion/Spec-File/CMS), (3) den git-Diff der Änderung.
Deine Aufgabe ist NICHT Code-Qualität zu bewerten — nur: tut der Diff GENAU das, was der
Contract verlangt? Suche konkret:

  (a) UNDER-BUILT — ein Akzeptanz-Kriterium / eine Contract-Anforderung, die im Diff NICHT
      erfüllt ist. Nenne die Anforderung + warum nicht erfüllt.
  (b) OVER-BUILT — Verhalten im Diff, das KEIN Contract-Punkt verlangt (Scope-Creep,
      ungefragtes Feature, spekulative Generalisierung). Nenne file:line.
  (c) MISINTERPRET — eine Anforderung ist umgesetzt, aber anders als der Contract meint
      (falsches Verhalten am Rand, falscher Default, falsche Quelle). Nenne file:line + Soll.
  (d) UNSOURCED — ein UI-Text/Preis/Limit im Diff, der zu keiner benannten Spec-Quelle passt
      (halluzinierter Inhalt). Nenne file:line.

Für jeden Befund: konkrete Stelle + wörtliches Zitat + welche Kategorie. Nichts gefunden
in einer Kategorie: "KEINE". Erfinde keine Mängel, um die Liste zu füllen.
```

**Auflösung:** Jeder bestätigte Befund wird **vor** Stufe 2 abgearbeitet:
- (a) → fehlendes Verhalten nachbauen, Ledger erweitern.
- (b) → entfernen (oder, wenn bewusst gewollt, im Report begründen — Scope-Creep ist Default-verboten).
- (c) → korrigieren gegen Contract/Quelle.
- (d) → STOP → Spec-Source-of-Truth (P1.8): echte Quelle finden oder Text raus. Nicht plausibel-klingend lassen.

> Befund-Output durchläuft **dasselbe** Anti-Halluzinations-Gate wie alle Agenten (`multi-agent.md` §3): citation-or-void, dann Source-`Read`. Auch der Reviewer halluziniert.

**Gate:** Stufe 1 ist grün, wenn keine offenen (a)–(d). Erst dann Stufe 2.

---

## 3. Stufe 2 — Code-Quality-Reviewer

**Input:** git-Diff + Umgebungscode der berührten Dateien (damit „passt zum Umfeld" beurteilbar ist). **Voraussetzung:** Stufe 1 grün.

**Prompt-Vorlage:**

```
Du bist Code-Quality-Reviewer. Spec-Compliance ist bereits bestätigt — bewerte NICHT erneut
ob das Richtige gebaut wurde, sondern nur WIE GUT. Du hast den git-Diff + den umgebenden
Code der berührten Dateien. Suche konkret:

  (a) DUPLIZIERUNG — neue Logik, die eine existierende Funktion/Util im Repo dupliziert,
      statt sie zu nutzen. Nenne beide Stellen.
  (b) FEHLERBEHANDLUNG — unbehandelter Fehlerpfad, verschluckter Catch, fehlender Falsy-/
      Null-/Leer-Fall (Abgleich mit Falsy-Matrix §2.3), Race ohne Schutz. Nenne file:line.
  (c) IDIOM-BRUCH — Stil/Naming/Struktur weicht ohne Grund vom umgebenden Code ab
      (anderes Error-Pattern, anderer Logger, anderes Async-Idiom). Nenne file:line.
  (d) TOTER/UNERREICHBARER PFAD — eingeführter Code, der nie läuft; verwaiste Branch;
      auskommentierter Rest. Nenne file:line.
  (e) LESBARKEIT — eine Stelle, die ein Wartender in 30s nicht versteht (Magic-Number ohne
      Konstante, verschachtelte Bedingung, missverständlicher Name). Nenne file:line.

Für jeden Befund: file:line + wörtliches Zitat + 1-Satz-Begründung + konkreter Fix-Vorschlag.
Nichts in einer Kategorie: "KEINE". Keine Stil-Nörgelei ohne Substanz — nur was Wartung,
Korrektheit oder Konsistenz real beeinträchtigt.
```

**Auflösung:** Bestätigte Befunde fixen; danach **Stufe 2 einmal re-checken** (re-run gegen den gefixten Diff — ein Fix kann einen neuen Befund einführen). Erst wenn ein Re-Check sauber ist, gilt Quality grün.

> Quality-Findings sind **Empfehlungen mit Substanz**, keine Coverage-Blocker. Aber: (a) Duplizierung und (b) Fehlerbehandlung sind grenzwertig zu Korrektheit — ein unbehandelter Falsy-Fall ist ein Bug, kein Stil. Solche werden wie Korrektheits-Findings behandelt (blockieren bei NO-FAIL).

---

## 4. Fix-und-Re-Check-Schleife (mit Loop-Disziplin)

Beide Stufen folgen: **Review → Fix → Re-Check derselben Stufe → erst dann weiter.** Nie einen offenen Reviewer-Befund stehen lassen und vorrücken.

Aber: dieselbe **Coverage-Diminishing-Returns-Disziplin** wie der Haupt-Loop (SKILL.md). Wenn ein Re-Check in **3 Runden** keine neue substanzielle Finding-Klasse mehr bringt → STOPP. Weiteres Polieren ist Token-Waste; das Verbleibende ist entweder Geschmack (kein Befund) oder braucht eine menschliche Entscheidung. Reviewer-Loops sind genauso wenig ein Brute-Force-Freibrief wie Recon-Loops.

---

## 5. Verhältnis zu den anderen Review-Schichten (keine Doppelung)

| Schicht | Frage | Quelle | Datei |
|---|---|---|---|
| **Ledger↔Diff-Kreuzaudit** | Ist jede Stelle angefasst, nichts erfunden? (**Coverage**) | Ledger + Diff | `multi-agent.md` §4 |
| **Spec-Compliance** (hier §2) | Ist das *Richtige* gebaut — nicht zu viel, nicht zu wenig? | Contract + Spec-Quelle | dieses Doc |
| **Code-Quality** (hier §3) | Ist es *gut* gebaut? | Diff + Umfeld | dieses Doc |
| **`/feature-testing`** | Beweist ein Test das Verhalten? | Test-Suite | extern |
| **`/security-review`** | Führt der Diff eine Schwäche ein? | Threat-Taxonomie | extern |

Vier verschiedene Fragen. Keine ersetzt die andere. Bei NO-FAIL laufen alle.

---

## 6. Selbstaudit Staged-Review (vor SHIP)

- [ ] Spec-Compliance **vor** Code-Quality gelaufen (nie umgekehrt)?
- [ ] Bei Risiko-Signal/NO-FAIL: **frische** Agenten (nicht Orchestrator-Selbstbestätigung)?
- [ ] Jeder Reviewer-Befund durch das §3-Anti-Halluzinations-Gate (Source-`Read`)?
- [ ] Alle (a)–(d) der Spec-Stufe aufgelöst, bevor Quality startete?
- [ ] Quality-Stufe nach dem letzten Fix einmal re-gecheckt?
- [ ] Loop-Disziplin eingehalten (kein endloses Polieren)?

> Fehlt eine Box, ist nicht „zu wenig Review" das Problem, sondern eine ungeprüfte Linse. Genau dort — „richtig gebaut, aber falsches Scope" oder „korrekt, aber dupliziert die halbe Codebase" — sitzt der Bug, den Coverage-Audit und Tests beide nicht sehen.
