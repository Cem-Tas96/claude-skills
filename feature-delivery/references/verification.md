# Verifikation — richtiges Test-Tier & echter Beweis (via /feature-testing + /verify)

> Falsche Tier-Wahl ist die Ursache für "Tests grün, Bug live". Dieses Dokument entscheidet die Schicht, katalogisiert was jede Schicht NICHT sieht, und orchestriert die **zwei** Beweis-Werkzeuge: `/feature-testing` (automatisierter Test-Beweis) und `/verify` (Beweis in der echten laufenden App). Die Test-*Strategie* selbst (Layer, Quality-Gates, Auto-Fix-Loop) gehört `/feature-testing` — hier geht es um Tier-Wahl und um den Beweis den Mock-/jsdom-Tests allein nicht liefern.

---

## 0. Die zwei Beweise — und warum beide

| Werkzeug | Phase | Beweist | Grenze |
|---|---|---|---|
| **`/feature-testing`** | P5.1 | Verhalten gegen **Mocks + jsdom** — schnell, wiederholbar, CI-tauglich | sieht keine echten Timing-/Hydration-/Env-/Bootstrap-Effekte |
| **`/verify`** | P5.2 | das **tatsächliche** Verhalten der **echten laufenden App** (Browser bzw. voller Stack) | kein Ersatz für die Test-Breite — beweist *diese* Änderung, nicht alle Pfade |

> Grüne Tests **und** nicht im Real-Runtime verifiziert = halber Beweis. Sobald §1 **Real-Browser** oder **Real-Stack** ergibt, sind beide Pflicht.

---

## 1. Test-Tier-Entscheidungsbaum

```
Berührt die Änderung …
├─ .env / docker / Auth-Realm / Bootstrap / Infra-Config?
│     → REAL-STACK-SMOKE (Pflicht) → via /verify nach Clean-Bring-up (§4).
├─ UI-Timing / Effekte / Hydration / SSR / Subscriptions / Render-Race?
│     → REAL-BROWSER (Pflicht) → via /verify (§3). jsdom reproduziert diese Races NICHT.
├─ DB / Service-Grenze / Queue / mehrere Layer / Nebenläufigkeit?
│     → INTEGRATION (echte Test-DB, externe APIs gemockt) → /feature-testing.
└─ reine Logik / Pure Function / Reducer / Validator / Mapping?
      → UNIT (schnell, deterministisch) → /feature-testing.
```

Mehrere Treffer → **alle** zutreffenden Tiers, nicht den billigsten. Eine SSR-Route die aus der DB liest braucht Integration (`/feature-testing`) **und** Real-Browser (`/verify`).

---

## 2. Was jede Schicht NICHT sieht (Fallen-Katalog)

**jsdom / Unit kann nicht:**
- echte Render-Reihenfolge & Lifecycle-Timing (ViewChild verfügbar erst nach echtem Render)
- Hydration-Mismatch (Server-HTML ≠ Client-Render)
- Layout-Shift, Sichtbarkeit, CSS-`url()`-Auflösung, echtes Event-Bubbling
- Auth-Redirect-Races, Double-Fire von Effekten beim Re-Mount
- `requestAnimationFrame`/`IntersectionObserver`/echte Microtask-Timings
→ Deshalb: UI-Timing-Änderung in jsdom „grün" ist kein Browser-Beweis → `/verify` (§3).

**Unit/Integration mit Mocks kann nicht:**
- Env-Var-Auflösung & Reihenfolge (Shell-ENV überschreibt `.env`)
- Bootstrap-Reihenfolge (SMTP/Realm-Werte post-boot injiziert)
- Realm-/Container-Init, DB-Datei-Mismatch nach Tool-Update
- echtes Netzwerk-/TLS-/CORS-Verhalten
→ Deshalb: Env/Infra-Änderung braucht Real-Stack-Smoke → `/verify` nach Clean-Bring-up (§4).

---

## 3. Real-Browser-Proof via `/verify` (UI / Timing / SSR)

`/verify` ist der primäre Real-Runtime-Beweis: es fährt die App hoch und beobachtet das echte Verhalten — kein jsdom. In P5.2 `/verify` mit einem **präzisen Szenario** füttern (sonst klickt es ins Blaue):

```
AN /verify:
  Flow:         [konkreter Pfad aus Contract P0 — Route, Klicks, Request]
  Erwartet:     [beobachtbares Soll aus AKZEPTANZ P0]
  Race/Edge:    [die spezifische Timing-/Edge-Falle: Doppel-Klick, Reload mitten im Flow,
                 schnelles Navigieren, leerer/0-Wert aus der Falsy-Matrix (modeling.md §3)]
  Reverse:      [bei Statuswechsel den Partner-Pfad (P1.4) einmal real auslösen]
  Bei Env/Boot: [zuerst Clean-Bring-up nach §4, DANN beobachten]
```

- **Durabler Anker:** ist der Race regress-anfällig → zusätzlich einen Playwright/Cypress-**E2E** als bleibenden Regressionstest anlegen (gehört in `/feature-testing`s E2E-Layer). `/verify` ist der Beweis *jetzt*, der E2E der Wächter *später*.
- **Fallback (kein `/verify` im Projekt):** dokumentiertes manuelles Verify im Report festhalten:
```
MANUAL VERIFY (real browser):
  Browser/Device: [Chrome 1xx / Mobile-Emulation 4G]
  Schritte:       1. … 2. … 3. …
  Erwartet / Beobachtet: [konkret — mit Screenshot/Konsole wenn UI]
  Race geprüft:   [Doppel-Klick / Reload mitten im Flow / schnelles Navigieren]
```
> "Done" bei UI-Timing-Code ohne `/verify` (oder dokumentiertes manuelles Verify) ist verboten. jsdom-grün zählt nicht als Beweis.

---

## 4. Real-Stack-Smoke (Env / Bootstrap) — via `/verify` nach Clean-Bring-up

Bei `.env`/Docker/Auth-Realm/Bootstrap/Infra-Änderung muss aus **sauberem Zustand** hochgefahren werden, bevor `/verify` beobachtet:

```
1. Clean-Bring-up:  <infra down> && <infra up -d> && <app start>
                    (z.B. docker compose down && docker compose up -d && npm start)
2. Health:          Boot-Logs ohne Fehler? Alle Container „healthy"?
3. /verify:         echten Pfad fahren — Login mit Testuser → 1 Kern-/Premium-Request durch den ganzen Stack
4. Symmetrie:       bei Statuswechsel auch den Reverse-Pfad (P1.4) einmal real auslösen
5. Report:          was hochgefahren, welcher Request, /verify-Beobachtung
```
> Niemals Env/Infra-Änderung mit „Unit-Tests grün" abschließen. Der laufende Stack ist der einzige Zeuge — `/verify` ist der Weg ihn zu befragen.

---

## 5. Orchestrierung — Reihenfolge & Handoff

P5 läuft strikt: **P5.1 `/feature-testing`** → **P5.2 `/verify`** → **P5.3 Regressions-Sweep.** Nicht `/verify` vor `/feature-testing` — erst die Tests grün, dann das Real-Runtime-Bild (sonst klickst du eine Version durch, die noch nicht alle Tests besteht).

**Handoff an `/feature-testing` (P5.1):**
```
AN /feature-testing:
  Feature/Fix:        [Name]
  Risiko-Tier:        NO-FAIL / LOW-FAIL / BEST-EFFORT   (aus Phase 3.1)
  Gewähltes Test-Tier:[Unit/Integration/Real-Browser/Real-Stack]  (aus Phase 3.2)
  Invarianten:        [aus modeling.md §2 — werden zu Assertions]
  State-Table:        [Link/Inline — jede Transition = ein Testfall-Kandidat]
  Geänderte Stellen:  [Coverage-Ledger — Basis für Phase-0-Änderungsanalyse]
  Bekannte Edge-Cases:[Falsy-Matrix-Entscheidungen aus modeling.md §3]
```
`/feature-testing` übernimmt Test-Strategie, Quality-Gates und Auto-Fix-Loop. Sein Urteil (AUSLIEFERN/BLOCKIERT) fließt in den Delivery-Report.

**Handoff an `/verify` (P5.2):** der `AN /verify`-Block aus §3.

**Fallback (Skill nicht im Projekt):**
- statt `/feature-testing`: Test-Disziplin inline — pro Invariante mindestens ein Test der bei Verletzung **fehlschlägt**, echte Assertions auf Output (nicht „kein Throw"), Negativ-/Falsy-Pfade abgedeckt, isoliert & deterministisch.
- statt `/verify`: manuelles Verify nach §3.

---

## 6. Verifikations-Abschluss

In den Delivery-Report (`VERIFIKATION`-Block):
- `/feature-testing`-Urteil: AUSLIEFERN / BLOCKIERT
- `/verify` (Real-Runtime): funktioniert / kaputt / N/A — Beobachtung (Browser bzw. Real-Stack)
- Regressions-Sweep: bestehende Suite + Lint + Typecheck + Build grün

> Solange ein Tier das laut §1 Pflicht war nicht durchlaufen ist (insb. `/verify` bei UI/Env) → **BLOCKIERT**, egal wie grün die anderen sind.
