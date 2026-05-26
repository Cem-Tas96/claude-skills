# Multi-Agent-Orchestrierung & Anti-Halluzination

> **Kernsatz:** Mehr Agenten kaufen **Recall**, nicht **Präzision**.
> Parallele Fächer finden mehr Stellen — aber jeder Agent halluziniert **unabhängig** Pfade, Zeilen und Symbole dazu. Wer „maximal viele Agenten" startet und ihren Output ungeprüft glaubt, hat nicht weniger Halluzination, sondern **mehr Halluzination gleichzeitig**. Was Halluzination senkt ist nicht Kopfzahl, sondern **Verifikation am Source + unabhängige Kreuzprüfung (Konsens) + Zitat-Zwang**. Dieser Skill nutzt darum Agenten *breit zum Suchen* und *streng zum Prüfen* — beides zusammen, nie das eine ohne das andere.

Dieses Dokument definiert, **wie viele** Agenten wann, **wie** sie geschnitten werden, und durch welche **Gates** ihr Output muss, bevor er Wahrheit wird.

---

## 1. Agenten-Budget nach Risiko-Tier (wie viele, wann)

Nicht „immer maximal". Kopfzahl skaliert mit Risiko-Tier (SKILL.md §3.1) und Blast-Radius-Breite. Zu viele Agenten auf einem trivialen Change = Token-Verschwendung + Rausch-Findings, die du trotzdem alle verifizieren musst.

**Kontrolle ist an die *Form* des Blast-Radius gebunden, nicht ans Domänen-Label.** Der Verifier-Nutzen (fehlende/erfundene/asymmetrische Stelle finden) hängt daran, wie *breit und gekoppelt* der Change ist — das kann auch ein LOW-FAIL-Change haben. Darum triggert der **unabhängige** Verifier an Risiko-Signalen, während ein **billiger Selbst-Audit immer** läuft (Defense-in-depth, kostenproportional):

| Tier / Lage | Recon-Fan-out | Kalte Zweit-Ableitung (Konsens) | Ledger↔Diff-Kreuzaudit (§4) |
|---|---|---|---|
| **BEST-EFFORT** / trivial, 1 Datei | 0 Agenten — direktes `grep`/`Read` | nein | nein (Ledger ist trivial) |
| **LOW-FAIL** / schmal, kein Risiko-Signal | parallele Streams A–G (blast-radius §2), je Kategorie 1 Agent | nein | **Selbst-Audit** — Orchestrator führt die 4 Checks (a–d) selbst aus, ohne neuen Agenten |
| **LOW-FAIL + Risiko-Signal** | Streams A–G | nein | **unabhängiger Agent** (§4) |
| **NO-FAIL** / Auth·Payment·Rollen·PII·Migration | volle Streams A–G | **JA** — 2. Agenten-Satz leitet Blast-Radius *kalt* neu ab (sieht Satz 1 nicht) | **unabhängiger Agent** (§4) — Pflicht |

**Risiko-Signal** (einer genügt → unabhängiger Verifier statt Selbst-Audit):
- Blast-Radius **> 8 Ledger-Zeilen** (breit),
- ein **Symmetrie-Paar** berührt (grant/revoke, sub/unsub, open/close … — historische #1-Ursache der Folgekommits),
- **Cross-Layer-Kopplung** angefasst (Config-Zwilling, Shared-Lib→N-Consumer, generiertes Artefakt),
- es wurden **überhaupt Sub-Agenten gefächert** (dann gibt es ungeprüften Agenten-Output, der ein Red-Team verdient).

> **Warum nicht „Verifier immer Pflicht"?** Was auf jedem trivialen Change Pflicht ist, wird zum Rubber-Stamp — und entwertet den Verifier dort, wo er zählt. Risiko-proportionale Kontrolle hält den teuren unabhängigen Agenten scharf, ohne den schmalen Change zu blockieren. Der Selbst-Audit kostet fast nichts und läuft darum trotzdem überall außer trivial.

> 🚨 Ein `exposed` Threat-Intel-Fund oder ein offenes Security-Finding hebt das Tier auf NO-FAIL → damit greifen automatisch Konsens **und** unabhängiger Verifier, egal wie harmlos die Fachlogik wirkt.

**Parallel starten:** Alle Agenten eines Fächers in **einer** Nachricht (mehrere Tool-Calls gleichzeitig) → sie laufen nebenläufig. `Explore` (read-only) verwenden; **kein Agent editiert Code** — Recon und Verifikation sind lesend, das Mutieren bleibt beim Orchestrator.

---

## 2. Schnitt der Suchaufträge (Streams dürfen sich NICHT überlappen)

Überlappende Aufträge erzeugen Doppel-Findings, die sich scheinbar „bestätigen" — ein Konsens-Artefakt, keine echte Bestätigung. Jeder Stream bekommt eine **disjunkte** Kategorie:

- **A** direkte Aufrufer / Importeure des Anker-Symbols
- **B** Output-Konsumenten (DB-Feld, Event-Payload, HTTP-Response, Rückgabewert)
- **C** Config-Duplikate & Env-Var-Familien (`*_DOMOAI`, `_PROD`/`_STAGING`)
- **D** parallele / duplizierte Implementierungen desselben Konzepts
- **E** Tests, Fixtures, Seeds, Mocks
- **F** generierte Artefakte **und** ihre Quellen
- **G** Docs, READMEs, `.env.example`, Migrations, Projekt-Kopplungs-Doku

**Fan-out-Prompt-Vorlage (je Stream):**

```
Suche im Repo ALLE Stellen die <SYMBOL> betreffen, AUSSCHLIESSLICH Kategorie <X: …>.
Für jede Fundstelle gib GENAU: file:line | die wörtlich zitierte Codezeile | warum betroffen (1 Satz).
HARTE REGELN:
- Nur Stellen die du im Datei-Inhalt GELESEN hast. Keine Vermutung, keine Extrapolation.
- Ohne exakte Zeilennummer + wörtliches Zitat NICHT auflisten.
- Wenn du in dieser Kategorie nichts findest: schreibe "KEINE" — erfinde nichts um die Tabelle zu füllen.
- Keine Bewertung, kein Vorschlag, keine Änderung. Nur Fundstellen.
```

Der Zwang „**wörtlich zitierte Zeile**" ist absichtlich: ein halluzinierter Pfad hat keine echte Zeile zum Zitieren, und das Zitat macht den Source-Abgleich in §3 zu einem Sekunden-Diff statt einer Neu-Suche.

---

## 3. Das Anti-Halluzinations-Gate (jeder Agenten-Output muss hindurch)

Kein Agenten-Befund wird Ledger-Wahrheit, bevor er diese drei Gates passiert. Reihenfolge ist billig→teuer, früh aussieben:

1. **Citation-or-void.** Befund ohne `file:line` **und** wörtliches Zeilen-Zitat → **verworfen**, nicht „nachrecherchiert". Ein Agent der nicht zitieren kann, hat nichts gesehen.
2. **Source-Abgleich (HART, nie überspringen).** Orchestrator öffnet die zitierte `file:line` mit `Read` und vergleicht: Existiert die Zeile? Steht das Symbol wirklich dort? Stimmt der Kontext mit der Behauptung? **Erst dann** wandert die Zeile von `behauptet` → `verifiziert` ins Ledger.
   - Zeile existiert nicht / Symbol steht nicht da → **Halluzination**: verwerfen + (bei NO-FAIL) als Signal werten, dass dieser Agent unzuverlässig war → seine übrigen Funde mit erhöhter Skepsis nachprüfen.
3. **Konsens-Abgleich (nur NO-FAIL, §1).** Vereinige die Funde aus Satz 1 und der kalten Zweit-Ableitung:
   - **In beiden** → hohe Konfidenz, trotzdem Gate 2.
   - **Nur in einem** → **nicht stillschweigend droppen und nicht blind übernehmen.** Diese Asymmetrie ist das wertvollste Signal: entweder hat ein Satz die Stelle übersehen (Recall-Lücke → muss rein) oder einer hat sie halluziniert (→ raus). Gate 2 entscheidet — am Source, nicht per Mehrheit.

> „Der Agent sagte" ist **kein** Beleg. „Ich habe die Zeile mit `Read` gesehen" ist einer. Diese Regel steht bewusst auch in der globalen Memory (`feedback_verify_agent_reports`) — sie ist nicht verhandelbar.

---

## 4. Ledger↔Diff-Kreuzaudit — die vier Anti-Lücken-Checks (Phase 5)

Recon-Agenten suchen, was **rein** muss. Der Kreuzaudit sucht, was **fehlt oder erfunden** ist — die entgegengesetzte Frage. Input ist immer **fertiger Diff + Coverage-Ledger**, gearbeitet wird *gegen* sie.

**Wer ihn ausführt (§1):**
- **NO-FAIL oder LOW-FAIL-mit-Risiko-Signal →** ein **frischer** `Explore`-Agent (nicht einer der Recon-Streams — der bestätigt nur seine eigene Arbeit). Das ist der **Independent-Verifier**.
- **LOW-FAIL schmal (kein Signal) →** der **Orchestrator selbst** geht dieselben vier Checks (a–d) durch — in-process, ohne neuen Agenten. Billig, aber die Disziplin läuft trotzdem.
- **BEST-EFFORT →** entfällt.

> Der **Selbst-Audit** ist nicht „weniger gründlich", nur „nicht unabhängig": dieselben vier Fragen, aber vom Orchestrator statt von einem fremden Agenten. Der unabhängige Agent fügt genau das hinzu, was der Selbst-Audit nicht kann — eine *zweite, von der Implementierung unbeeinflusste* Sicht. Dafür lohnt er sich erst ab Risiko-Signal.

**Verifier-Prompt-Vorlage:**

```
Du bist Red-Team-Auditor. Hier ist (1) ein Coverage-Ledger und (2) der git-Diff der Änderung.
Deine Aufgabe ist NICHT zu bestätigen — sondern Lücken zu finden. Suche konkret:

  (a) GELDED — eine Ledger-Zeile mit Status ✓, deren Stelle im Diff aber NICHT angefasst wurde
      (behauptet erledigt, real nicht). Nenne file:line.
  (b) FEHLEND — eine im Diff geänderte Stelle / ein berührtes Symbol, das in KEINER Ledger-Zeile steht
      (geändert ohne Erfassung → Blast-Radius war unvollständig). Nenne file:line.
  (c) ERFUNDEN — eine Ledger-Zeile die auf ein Symbol/eine Datei zeigt, die im Repo gar nicht existiert
      (halluzinierte Stelle). Nenne die Ledger-ID.
  (d) ASYMMETRIE — eine Vorwärts-Aktion im Diff (grant/open/subscribe/create…) ohne ihren
      Reverse-Pfad im selben Diff. Nenne beide Stellen bzw. die fehlende.

Für jeden Befund: file:line + wörtliches Zitat + welche Kategorie (a/b/c/d).
Findest du in einer Kategorie nichts: "KEINE". Nichts erfinden.
```

Output durchläuft **dasselbe** §3-Gate (auch ein Verifier-Agent halluziniert; beim Selbst-Audit ist Gate 2 — Source-`Read` — ohnehin schon dein eigener Blick). Jeder bestätigte (a)/(b)/(c)/(d)-Befund:
- (a) → Stelle wirklich abarbeiten, Ledger ehrlich machen.
- (b) → neue Ledger-Zeile, Blast-Radius war unvollständig → ggf. Recon nachschärfen.
- (c) → Ledger-Zeile streichen (war Halluzination aus Recon).
- (d) → Reverse-Pfad nachbauen oder als `N/A (+Grund)` begründen.

> Ein offener Kreuzaudit-Befund **blockiert** (SKILL.md P6), wann immer der Audit lief — d.h. NO-FAIL und LOW-FAIL-mit-Risiko-Signal (unabhängiger Agent) ebenso wie der LOW-FAIL-Selbst-Audit. Der Kreuzaudit ist die letzte Instanz, die „vollständig & nichts erfunden" beweist, bevor der Delivery-Report SHIP sagen darf.

---

## 5. Was Agenten hier NICHT tun

- **Nicht entscheiden, ob etwas geändert werden muss** — sie melden Fundstellen; die Bewertung macht der Orchestrator gegen State-Table & Invarianten.
- **Nicht Code schreiben/editieren** — Recon & Verifikation sind read-only (`Explore`). Mutation ist Orchestrator-Sache, in einem kohärenten Change.
- **Nicht ungeprüft Wahrheit liefern** — kein Agenten-Satz überspringt §3.
- **Nicht sich gegenseitig zitieren** — Konsens entsteht aus *unabhängigen* Ableitungen, nicht daraus, dass Agent 2 Agent 1s Liste „bestätigt".

---

## 6. Selbstaudit Multi-Agent (vor „Ledger vollständig" und vor SHIP)

- [ ] Kopfzahl dem Tier angemessen (nicht 0 bei NO-FAIL, nicht 7 bei Einzeiler)?
- [ ] Streams **disjunkt** geschnitten (keine sich selbst bestätigende Überlappung)?
- [ ] **Jede** gemeldete `file:line` am Source mit `Read` gegengelesen (§3 Gate 2)?
- [ ] Bei NO-FAIL: kalte Zweit-Ableitung gelaufen, Nur-in-einem-Funde aufgelöst (§3 Gate 3)?
- [ ] Bei NO-FAIL: Independent-Verifier gegen Diff+Ledger gelaufen, alle (a)–(d) sauber (§4)?
- [ ] Citation-lose Befunde verworfen, nicht „nachrecherchiert" (§3 Gate 1)?

> Wenn du diese Boxen nicht ehrlich abhaken kannst, ist nicht „zu wenig Agenten" das Problem — sondern ungeprüfter Agenten-Output. Das ist genau die Lücke, in der die Halluzination wartet.
