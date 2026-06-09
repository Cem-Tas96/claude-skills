# Systematic Debugging — Root-Cause-First statt Guess-and-Check

> **Kernsatz:** KEIN FIX OHNE ROOT-CAUSE. Ein Fix, der das Symptom abstellt ohne die Ursache zu kennen, verschiebt den Bug nur — meist in eine schwerer auffindbare Schicht. „Ich verstehe es nicht ganz, aber das könnte helfen" ist kein Fix, sondern eine neue, getarnte Wette.

Adaptiert aus dem `systematic-debugging`-Pattern (obra/superpowers). Greift, wann immer in diesem Skill **etwas bricht statt zu fehlen**: ein Test wird rot, `/verify` zeigt falsches Verhalten, der Regressions-Sweep (P5.4) fängt einen Bruch, der `/feature-testing`-Auto-Fix-Loop thrasht, oder die Implementierung (P4) tut nicht was die State-Table sagt.

> **Resonanz mit der Kernphilosophie:** Der Skill sagt schon „Brute-Force-Loops sind Token-Waste — 3 Iterationen ohne neues Wissen → STOPP". Systematisches Debuggen ist die *konstruktive* Hälfte derselben Regel: nicht nochmal blind probieren, sondern die Ursache verstehen. Das hier ist das Werkzeug, auf das die Loop-Disziplin verweist, wenn sie „braucht eine andere Methode" sagt.

---

## Wann dieses Protokoll PFLICHT ist

- Ein vorher-grüner Test ist jetzt rot (Regression).
- `/verify` / Klick-Through (P5.5) zeigt anderes Verhalten als der Contract.
- Die Implementierung produziert einen Zustand, den die State-Table (§2.1) als unmöglich/invariant-verletzend markiert.
- Du hast **bereits 1 Fix versucht und er hat nicht gewirkt** → ab jetzt nicht weiter raten, sondern das Protokoll fahren.

Bei einem trivialen, offensichtlichen Tippfehler mit eindeutiger Stack-Trace-Zeile: fixen, weiter. Das Protokoll greift, sobald die Ursache **nicht** auf den ersten Blick klar ist.

---

## Phase 1 — Root-Cause-Investigation (bevor IRGENDEIN Fix vorgeschlagen wird)

1. **Fehlermeldung vollständig lesen.** Nicht überfliegen, nicht wegklicken. Stack-Traces enthalten oft die Lösung direkt — die unterste eigene Frame, nicht die Library-Frames.
2. **Zuverlässig reproduzieren.** Exakte auslösende Schritte dokumentieren. Ein Bug, den du nicht reproduzieren kannst, kannst du nicht verifiziert fixen — du kannst nur hoffen. „Tritt manchmal auf" → erst die Bedingung finden, die ihn *immer* auslöst (Race? Reihenfolge? Daten-abhängig? Zustand aus vorherigem Schritt?).
3. **Letzte Änderungen prüfen.** `git log`/`git diff` der berührten Pfade, Dependency-Bumps, Config-/Env-Änderungen. Was war zuletzt grün, was hat sich seitdem geändert? (`git bisect` wenn der Bruchpunkt unklar ist.)
4. **Mehrschichtige Systeme instrumentieren.** An jeder Schicht-Grenze (Controller→Service→DB, Client→API→Worker) Diagnose-Logging setzen, um die Fehl-Schicht einzugrenzen. Erst die Schicht finden, *dann* die Zeile.
5. **Datenfluss rückwärts verfolgen.** Vom falschen Wert flussaufwärts zur Quelle. Wo wird der Wert zuletzt korrekt, wo zuerst falsch? Dazwischen sitzt die Ursache — nicht dort, wo der Fehler *auffällt*.

> Output dieser Phase ist **nicht** ein Fix, sondern ein Satz: „Die Ursache ist X an `file:line`, weil Y." Ohne diesen Satz geht es nicht weiter.

---

## Phase 2 — Pattern-Analyse (gegen Funktionierendes spiegeln)

- Ähnlichen **funktionierenden** Code im Repo finden (anderer Aufrufer derselben Funktion, analoger Flow, der grün ist).
- Referenz **vollständig** lesen, nicht selektiv.
- **Alle** Unterschiede zwischen funktionierend und kaputt auflisten — auch die scheinbar irrelevanten (Reihenfolge, Await, Config, Default-Wert, Initialisierung).
- Dependencies & Config-Anforderungen abgleichen: Hat der kaputte Pfad ein Setup, das der funktionierende implizit hat?

---

## Phase 3 — Hypothese & Test (wissenschaftliche Methode)

- **Hypothese explizit formulieren:** „X ist die Ursache, weil Y." Aufschreiben, nicht nur denken.
- **Minimal testen — eine Variable nach der anderen.** Mehrere Änderungen gleichzeitig = du weißt am Ende nicht, welche gewirkt hat (und welche einen neuen Bug einführte).
- **Ergebnis verifizieren, bevor du weitergehst.** Hat der Test die Hypothese bestätigt oder widerlegt?
- Widerlegt → **neue Hypothese**, nicht dieselbe nochmal mit Variation. Eine widerlegte Hypothese ist Fortschritt (Suchraum kleiner), kein Misserfolg.

---

## Phase 4 — Implementierung (Problem fixen, nicht Symptom)

1. **Erst einen failing Test schreiben**, der den Bug demonstriert (RED). Das beweist, dass du den Bug wirklich verstanden hast und ankert ihn gegen Regression — gehört in den E2E-/Test-Layer von `/feature-testing`.
2. **Einen** gezielten Fix an der Ursache (GREEN). Nicht „zur Sicherheit" drei Stellen anfassen.
3. Verifizieren: Der neue Test ist grün **und** kein anderer vorher-grüner Test ist jetzt rot (P5.4-Sweep).
4. **🚨 Harte Regel: Nach 3 fehlgeschlagenen Fixes — STOPP.** Nicht den 4. probieren. Das Problem liegt fast sicher eine Ebene höher als gedacht: falsche Annahme über die Architektur, falsches mentales Modell, der Bug ist woanders. Architektur/Annahme in Frage stellen, ggf. menschliche Entscheidung holen. (Das ist exakt die Coverage-Diminishing-Returns-Regel des Skills, angewandt aufs Debuggen.)

---

## Konkrete Taktiken — Phase 1–4 vertieft

Die folgenden sechs Taktiken docken an die vier Phasen oben an. Jede ist als **Prinzip** formuliert; konkrete Befehle sind als Stack-Beispiel markiert — im jeweiligen Stack das Äquivalent nehmen (projekt-agnostisch).

### T1 — Condition-based Waiting statt fixer Wartezeit  *(Phase 1 + Test-Setup)*
Ein fester `sleep`/`setTimeout` maskiert Races und macht Tests langsam + flaky. Konstruktiv wartet man auf die **Bedingung**, nicht die Zeit: auf ein reales Prädikat pollen (Event eingetreten · State erreicht · Count == n · Datei existiert), mit **Pflicht-Timeout und beschreibender Fehlermeldung** — nie unbegrenzt, nie nur „timeout".
- **Regel:** jede Warte-Konstruktion hat (1) ein reales Prädikat, (2) ein gebundenes Timeout, (3) eine Fehlermeldung die erwarteten vs. letzten Zustand nennt.
- *Beispiel: `waitFor(pred, timeoutMs, ~10ms-Poll)` in JS; `Eventually(...)` (Gomega) in Go; `wait_for`/Polling in Python; `Awaitility` in Java.*

### T2 — Destruktive Operationen hinter Test-Environment-Flag + isolierter Temp-Pfad  *(Phase 4)*
Destruktive Ops (Verzeichnis löschen, DB droppen, Cleanup) dürfen NUR im Test-Kontext laufen, sonst sauber abbrechen. Temp-Pfade müssen **projekt-relativ und pro Lauf eindeutig** sein, nicht der OS-Tmp-Root (sonst keine Isolation zwischen Läufen).
- **Regel:** `wenn nicht Test-Env → mit Fehler abbrechen`; Temp-Pfad relativ zum Projekt-Root + pro Lauf eindeutig; im Teardown gezielt aufräumen.
- *Beispiel-Flag: `NODE_ENV==='test'` (JS), `PYTEST_CURRENT_TEST`/`pytest`-Marker (Python), `RAILS_ENV=test`, Build-Tag/`testing.Testing()` (Go).*

### T3 — Defense-in-Depth: validiere in mehreren Schichten, jede fängt eine andere Bug-Klasse  *(Phase 2 + 3)*
Multi-Punkt-Validierung ist nicht Redundanz — jede Schicht fängt einen anderen Fehler-Typ. Vier benannte Schichten, jede separat getestet:

| Schicht | Bug-Klasse | Test-Frage |
|---|---|---|
| **Entry-Validation** | ungültige Eingabe, Format, Null/leer | wird ungültiger Input am Eingang abgewiesen? |
| **Business-Logic** | falsche Berechnung/Transition/Prädikat | liefert gültiger Input das korrekte Ergebnis? |
| **Environment-Guard** | Config fehlt, Service down, Permission | bricht der Pfad bei fehlender Abhängigkeit sauber ab? |
| **Instrumentation** | falsches/fehlendes Log/Metrik/Auditlog | wird der erwartete Effekt beobachtbar? |

- **Regel:** für jeden kritischen Wert prüfen, ob er an *mehr als einer* Schicht abgesichert ist; und testen, dass eine untere Schicht greift, wenn man eine obere umgeht. Fällt eine Schicht, die anderen grün → Bug ist auf diese Schicht lokalisiert.

### T4 — Test-Pollution-Bisection  *(Phase 1 — „zuverlässig reproduzieren")*
Ein Test rot nur **in Kombination** mit einem anderen = Isolations-Bruch, nicht Flakiness. Finde den Verschmutzer per Halbierung, nicht per Raten:
1. verdächtigen Test **isoliert** laufen → grün?
2. mit Vorgängern kombiniert → rot? → die Test-Menge halbieren, bis der **direkte** Verschmutzer isoliert ist; dann dessen Teardown / globalen State prüfen.
- *Ergänzt die Order-Randomisierung (`jest --randomize`, `pytest-randomly`, `go test -shuffle`): das Randomisieren **findet** die Order-Abhängigkeit, die Bisection **isoliert** die Ursache.*

### T5 — Instrumentieren VOR der Operation, auf einen erfassten Stream  *(Phase 1, Schritt 4 vertieft)*
Diagnose-Logging gehört **vor** die verdächtige Operation (um den Zustand zu sehen, der hineinführt), nicht nach dem Fehler. Im Test auf einen Stream loggen, den der Test wirklich **erfasst** — nicht auf einen evtl. stummgeschalteten Logger.
- *Beispiel: in JS-Tests `console.error` statt evtl. unterdrücktem Logger; im jeweiligen Stack das Äquivalent.* Reichen Kontext mitloggen (Eingabe, Zwischenwerte), nicht nur „hier".

### T6 — Architektur-Problem-Erkennungsmuster (bevor die 3-Fehlversuch-Grenze erreicht ist)  *(Phase 4)*
Diese Muster signalisieren: das Problem ist nicht *eine Zeile*, sondern Architektur / falsche Annahme — Architektur hinterfragen, ohne erst 3 Fehlversuche zu sammeln:

| Muster | Symptom | Wahrer Grund / Antwort |
|---|---|---|
| Jeder Fix legt neue Kopplung frei | Fix in X bricht Y, Fix in Y bricht Z | gemeinsamer impliziter State / Init-Reihenfolge → Abhängigkeitsgraph entkoppeln |
| Erfordert Massiv-Refactor | jeder Patch nur temporär, der nächste Fall bricht neu | Feature passt nicht ins Modell → Design-Annahme hinterfragen, nicht weiterpatchen |
| Erzeugt neues Symptom | Fix behebt A, erzeugt B woanders | mehrere Pfade mit gemeinsamer Root-Cause → alle Pfade gleichzeitig instrumentieren |
| Nur bei Parallelität rot | lokal grün, parallel/CI rot | Race / geteilter Cache → Environment-Guard-Schicht (T3) prüfen |
| Nur beim 2. Lauf rot | erster Lauf grün, zweiter rot | Cleanup- / State-Remanenz → Test-Env-Guard + isolierter Temp-Pfad (T2) |

---

## Red Flags — sofort Protokoll von vorn

- Du schlägst eine Lösung vor, **bevor** du den Datenfluss verfolgt hast.
- Du änderst **mehrere** Dinge gleichzeitig.
- Du nimmst etwas an, **ohne** es verifiziert zu haben.
- Du sagst „ich verstehe es nicht ganz, aber das könnte funktionieren".
- Fehlversuche stapeln sich, **ohne** dass du die Architektur hinterfragst.

Jede dieser Zeilen bedeutet: zurück zu Phase 1. Raten fühlt sich schneller an, ist aber langsamer — die Folgekosten sind versteckte Regressionen und verlorene Reproduzierbarkeit.

---

## Warum (die Begründung, die das Protokoll teuer-aber-billig macht)

Systematisches Debuggen ist **schneller** als Guess-and-Check-Thrashing — nicht trotz, sondern *wegen* der Vorab-Disziplin. Jeder geratene Fix, der nicht die Ursache trifft, kann eine neue Regression einbauen, die du später separat jagst; die scheinbar „verschwendete" Investigationszeit kauft dir den Verzicht auf diese Kette. Dieselbe Logik wie „Code zuerst kartieren, dann mutieren" — nur auf Bugs statt auf Features angewandt.

---

## Selbstaudit Debugging (bevor der Fix ins Ledger/Delivery-Report geht)

- [ ] Root-Cause **benannt** (file:line + Warum), nicht nur Symptom abgestellt?
- [ ] Bug **reproduzierbar** vor dem Fix, **nicht mehr reproduzierbar** danach?
- [ ] Failing Test geschrieben (RED→GREEN), der den Bug gegen Regression ankert?
- [ ] **Nur eine** Ursache gefixt, nicht „zur Sicherheit" mehrere Stellen?
- [ ] Regressions-Sweep (P5.4) grün — kein vorher-grüner Test jetzt rot?
- [ ] Bei ≥3 Fehlversuchen: gestoppt und Architektur/Annahme hinterfragt statt weiter geraten?
- [ ] Async-Wartezeiten als **Bedingung** (T1) statt fixem sleep — mit Timeout + klarer Fehlermeldung?
- [ ] Destruktive Test-Ops hinter Test-Env-Flag + isoliertem, projekt-relativem Temp-Pfad (T2)?
- [ ] Bei „nur in Kombination rot": Test-Pollution-Bisection (T4) gefahren, Verschmutzer isoliert?
- [ ] Architektur-Erkennungsmuster (T6) geprüft, bevor blind weiter gepatcht wurde?
