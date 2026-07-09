---
version: 1.0.0
changelog: |
  1.0.0 — Initiale Version: mess-getriebene Bottleneck-Jagd über alle Layer
          (Algorithmus/CPU/DB/IO/Netz/Cache/Frontend/Memory/Build), Phasen,
          ROI-Priorisierung (Amdahl), Regressions-Guard, Report. Projekt-agnostisch,
          integriert mit token-discipline (Lean-Default) + feature-delivery (P5.6).
name: performance-boost
description: >
  Mess-getriebene Performance-Optimierung für JEDES Projekt auf JEDEM Stack. Diesen Skill verwenden
  wann immer etwas zu langsam ist oder schneller werden soll — hohe Latenz/Antwortzeit, niedriger
  Durchsatz, langsame DB-Queries (N+1), lange Ladezeiten/große Bundles, Memory-Leaks/hoher RAM,
  langsame Builds/CI, Hot-Path-CPU. Trigger-Wörter: "performance", "bottleneck", "langsam", "slow",
  "optimieren", "profiling", "latency/Latenz", "throughput", "speed up", "schneller machen",
  "memory leak", "bundle size", "Ladezeit". Der Skill kartiert ALLE Bottlenecks eines Projekts
  empirisch (profilen statt raten), priorisiert nach echtem Laufzeit-Anteil (Amdahl), fixt den
  größten zuerst, beweist jeden Fix mit einer Vorher/Nachher-Zahl und schützt gegen Regressionen.
  Ziel: 1 Prompt → gemessene Baseline → gerankte Bottleneck-Liste → höchster-ROI-Fix → bewiesener
  Speedup, ohne Korrektheit zu brechen. Ist der `/performance-boost`, den `/feature-delivery` (P5.6)
  als optionalen Hot-Path-Schritt orchestriert; läuft auch eigenständig.
triggers:
  - "performance boost"
  - "performance optimieren"
  - "bottleneck finden"
  - "find bottlenecks"
  - "warum ist das langsam"
  - "schneller machen"
  - "optimize performance"
  - "profiling"
  - "memory leak"
  - "langsame query"
---

# Performance-Boost Skill — mess-getriebene Bottleneck-Jagd

## KERNPHILOSOPHIE

> **Miss, rate nicht.** Der Bottleneck sitzt fast nie da, wo die Intuition ihn vermutet. Jede Optimierung beginnt mit einem Profil, nicht mit einer Vermutung. „Das ist bestimmt die Schleife" ist der Anfang von verschwendeter Zeit an einem kalten Pfad.

> **Amdahl regiert.** Ein 10×-Speedup auf 3 % der Laufzeit bringt gesamt 1,03×. Der einzige Fix, der zählt, ist der auf dem **größten Laufzeit-Anteil**. Bottlenecks werden nach gemessenem Beitrag gerankt — der teuerste zuerst, nicht der offensichtlichste.

> **Kein Fix ohne Zahl.** Jede Änderung braucht ein Vorher **und** ein Nachher aus derselben, reproduzierbaren Messung. „Sollte jetzt schneller sein" ist eine Behauptung, kein Beweis. Wenn du das Delta nicht zeigen kannst, hast du nichts optimiert.

> **Schnell und falsch ist falsch.** Korrektheit ist Vorbedingung, nicht Verhandlungsmasse. Eine Optimierung, die die Test-Suite rot macht oder ein Ergebnis verändert, ist ein Bug mit Tempo. Tests bleiben grün — vorher wie nachher.

> **Das Profil lügt seltener als die Intuition — aber Micro-Benchmarks lügen auch.** JIT-Warmup, warme Caches, unrepräsentative Eingaben und Messrauschen erzeugen Phantom-Ergebnisse. Gemessen wird der **echte, repräsentative Workload**, mehrfach, mit Warmup — nicht ein 3-Zeilen-Loop im luftleeren Raum.

> **Optimierung ohne Ziel ist endlos.** Es gibt immer noch 5 % rauszuholen. Ohne definiertes Ziel (p95 < X ms, Bundle < Y kB, Build < Z s) optimierst du bis zum Sankt-Nimmerleins-Tag. Ziel definieren, erreichen, aufhören.

**Du bist nicht fertig, wenn „es sich schneller anfühlt". Du bist fertig, wenn die Ziel-Metrik auf dem echten Workload gemessen das Ziel erreicht, jeder Fix ein belegtes Delta hat, keine Regression an anderer Stelle entstand und die Korrektheits-Tests grün sind.**

---

## BETRIEBS-MODUS

Mess-getriebene Schleife: **BASELINE → PROFILE → RANK → FIX (höchster ROI) → RE-MEASURE → wiederholen bis Ziel erreicht oder Diminishing Returns.** Immer nur **eine** Änderung zwischen zwei Messungen — sonst ist das Delta nicht zuordenbar.

**Token-Discipline (Lean-Default, `~/.claude/skills/token-discipline/token-router.md`):** Profiling-Recon ist günstig — kein 10-Agenten-Fächer für einen Perf-Scan. Breiten-Recon (mehrere Layer parallel messen) via `Explore`-Subagenten nur bei echtem Multi-Layer-Blast-Radius; Standard ist inline profilen. Kein Modell-Upgrade fürs Messen.

**Zusammenspiel:** Dies ist der `/performance-boost`, den `/feature-delivery` in **P5.6 (optional, Hot-Path)** orchestriert. Läuft dort nach dem Correctness-Beweis (`/verify`) — Reihenfolge ist bewusst: erst korrekt, dann schnell. Eigenständig aufrufbar für „mach Projekt X schneller".

---

## PRE-FLIGHT — REPRODUZIERBARKEIT ZUERST (Pflicht)

Ohne reproduzierbare Messung ist alles danach Rauschen.

1. **Ziel-Metrik festnageln** — welche EINE Zahl zählt? Latenz (p50/p95/p99), Durchsatz (req/s), Ladezeit (LCP/TTI), Bundle-Größe, Peak-RAM, Build-Dauer, DB-Query-Zeit. Mehrere Metriken → priorisieren, nicht gleichzeitig jagen.
2. **Repräsentativen Workload definieren** — echte Datenmengen, echte Query-Muster, echte Nebenläufigkeit. Ein Benchmark mit 3 Zeilen Testdaten sagt nichts über Produktion mit 3 Mio. Zeilen.
3. **Baseline messen und festschreiben** — dieselbe Messung, die am Ende das Delta beweist. Mit Warmup, mehreren Läufen, Median + Streuung. Zahl notieren.
4. **Umgebung fixieren** — dieselbe Maschine/Container, dieselbe Datenlage, keine parallelen Last-Fremdkörper. Prod-nah messen, wenn möglich; sonst dokumentieren, dass lokal gemessen wurde.

> Reine Messung, editiert nichts. Kein Manifest/kein Runner → dokumentieren („N/A — manuell gestoppt: … s") und weiter, nicht blockieren.

---

## PHASE 1 — BOTTLENECK-KARTIERUNG (★ „finde ALLE Bottlenecks")

Nicht den erstbesten Verdacht fixen — **erst das ganze Feld vermessen und ranken.** Über alle relevanten Layer profilen, jeden Hotspot mit seinem **prozentualen Laufzeit-/Ressourcen-Anteil** ins Ledger.

### Layer-Katalog (projekt-agnostisch — pro Layer das passende Werkzeug)

| Layer | Typische Bottlenecks | Werkzeug (Beispiele, stack-abhängig) |
|---|---|---|
| **Algorithmus** | O(n²) wo O(n) reicht, unnötige Arbeit in heißen Schleifen, falsche Datenstruktur (Liste statt Set/Map) | Code-Read + Komplexitäts-Analyse, Flame-Graph |
| **CPU / Hot-Path** | heiße Funktionen, übermäßige Allokation, Serialisierung | Node `--prof`/`clinic`/`0x`; Python `cProfile`/`py-spy`; Go `pprof`; JVM `async-profiler` |
| **Datenbank** | N+1-Queries, fehlender Index, Full-Table-Scan, teurer Join, kein Connection-Pool | Slow-Query-Log, `EXPLAIN (ANALYZE)`, ORM-Query-Count |
| **I/O / Netzwerk** | synchron-blockierend, serielle statt parallele Calls, zu große Payloads, zu viele Round-Trips, keine Kompression | Trace/Waterfall, `curl -w`, APM-Spans |
| **Caching** | fehlender/kalter Cache, falsche Invalidierung, keine Memoization, wiederholte Neuberechnung | Cache-Hit-Rate, Wiederholungs-Zähler |
| **Frontend** | großes Bundle, unnötige Re-Renders, kein Code-Splitting/Lazy-Load, Render-Waterfall, blockierende Ressourcen | Lighthouse, DevTools-Performance/-Profiler, `source-map-explorer`/Bundle-Analyzer |
| **Memory** | Leaks, übermäßige Retention, GC-Druck, unbegrenzte Caches/Puffer | Heap-Snapshot, RSS über Zeit, GC-Logs |
| **Nebenläufigkeit** | Lock-Contention, Serialisierung an Engpass, Thread-/Pool-Starvation | Contention-Profiler, Queue-Tiefe |
| **Build / CI** | kein Cache, keine Parallelisierung, kein inkrementelles Kompilieren | Build-Timings, Cache-Hit-Rate |

### Regeln der Kartierung
- **Anteil messen, nicht schätzen** — jeder Hotspot bekommt seinen gemessenen % am Ziel-Metrik-Budget. Ein Hotspot ohne Zahl ist ein Verdacht, keine Ledger-Zeile.
- **Bis der Rest im Rauschen verschwindet** — Hotspots sammeln, bis die verbleibenden einzeln < ~5 % beitragen. Der lange Schwanz ist selten die Mühe wert (Amdahl).
- **Breiten-Recon nur bei echtem Multi-Layer-Verdacht** — dann mehrere Layer parallel via `Explore`-Subagenten (je Agent ein Layer, `file:line` + gemessene Zahl). Sonst inline.

### Das PERFORMANCE-LEDGER (Pflicht-Artefakt)
```
PERFORMANCE-LEDGER — [Ziel-Metrik: z.B. p95 API-Latenz, Baseline 840 ms, Ziel < 300 ms]
ID | Hotspot (file:line / Query / Bundle-Chunk) | Layer  | Anteil | Root-Cause              | Fix-Idee                | Status
---|--------------------------------------------|--------|--------|-------------------------|-------------------------|--------
H1 | user.repo.ts:88  findAll+Loop              | DB     |  61 %  | N+1 (1+N Queries)       | JOIN / eager-load / IN  | offen
H2 | report.service.ts:210 buildRows            | CPU    |  22 %  | O(n²) dedup in Schleife | Set-basiert O(n)        | offen
H3 | main.bundle.js moment-with-locales         | FE     |   9 %  | schwere Lib voll gebündelt | leichter Ersatz/Tree-shake | offen
```
> Das Ledger blockt „fertig", solange die Ziel-Metrik nicht erreicht ist **oder** eine `offen`-Zeile mit relevantem Anteil ungefixt ist.

---

## PHASE 2 — ROOT-CAUSE JE HOTSPOT

Für jede Ledger-Zeile das **Warum** benennen, bevor gefixt wird — die Fix-Klasse folgt aus der Ursache:

- **N+1 / Query-Fanout** → Batch/JOIN/`IN`-Liste/Dataloader; nicht „Query schneller machen", sondern Query-Anzahl senken.
- **Fehlender Index / Scan** → Index auf Filter-/Join-Spalte; `EXPLAIN` vorher/nachher vergleichen.
- **O(n²)/schlechte Struktur** → passende Datenstruktur (Set/Map/Heap), Arbeit aus der heißen Schleife ziehen.
- **Synchron-blockierend / seriell** → Parallelisieren (`Promise.all`/Worker/async), Round-Trips bündeln.
- **Wiederholte Neuberechnung** → Memoization/Cache mit klarer Invalidierung.
- **Zu große Payload / Bundle** → Feld-Selektion/Pagination/Kompression; Tree-Shaking/Code-Splitting/Lazy-Load.
- **Memory-Retention** → Lebenszyklus/Bounds klären, Leak-Quelle im Heap-Diff isolieren.

---

## PHASE 3 — FIX NACH ROI (höchster Anteil zuerst, EINE Änderung)

1. **Sortiere das Ledger nach Anteil.** Fix H1 (61 %) vor H2 (22 %) — immer.
2. **Ein Fix isoliert umsetzen.** Keine zwei Optimierungen zwischen zwei Messungen (sonst kein zuordenbares Delta).
3. **Korrektheit halten:** die relevanten Tests laufen nach dem Fix — grün, gleiches Ergebnis. Bei Bedarf einen Test ergänzen, der das Verhalten festnagelt (Zusammenspiel mit `/feature-testing`).
4. **Nach dem Fix sofort re-messen** (Phase 4), Delta ins Ledger, Zeile `erledigt` mit Vorher→Nachher-Zahl.

> Wenn ein Fix architektonisch tief eingreift (Query-Layer, Datenmodell, Bundle-Strategie) → über `/feature-delivery` fahren (Blast-Radius + Symmetrie), nicht als Einzel-Edit.

---

## PHASE 4 — RE-MESSUNG + REGRESSIONS-GUARD

1. **Dieselbe Baseline-Messung** erneut fahren (gleicher Workload, gleiche Umgebung, Warmup, Median). Delta = Beweis.
2. **Regression anderswo ausschließen** — ein DB-Index beschleunigt Reads, verlangsamt Writes; ein Cache kostet RAM; Parallelisierung erhöht Peak-Last. Die **nicht** optimierte Nachbar-Metrik gegenprüfen, nicht nur die Ziel-Metrik.
3. **Kein Delta / negativ?** Fix zurücknehmen (Branch!) — eine Optimierung, die nichts bringt, ist Komplexität ohne Gegenwert. Ledger-Zeile als `verworfen — kein Effekt` markieren, nächster Hotspot.
4. **Ziel erreicht?** → Report. **Nicht?** → nächste Ledger-Zeile.

---

## PHASE 5 — DIMINISHING-RETURNS-STOP (Loop-Disziplin)

**Aufhören, wenn:** Ziel-Metrik erreicht **ODER** der nächste Hotspot < ~5 % beiträgt **ODER** 2 aufeinanderfolgende Fixes kein messbares Delta brachten. Weiter-Micro-Optimieren produziert dann Komplexität statt Speedup. Ehrlich melden: „Ziel erreicht bei X" oder „verbleibende Bottlenecks tragen je < 5 %, weiterer Aufwand nicht gerechtfertigt".

---

## PHASE 6 — DELIVERY-REPORT (Pflicht)

```
PERFORMANCE-REPORT — [Ziel-Metrik]
Baseline:   840 ms (p95, 1k req, warm)
Ergebnis:   210 ms (p95, gleicher Workload)   →  4,0× / −75 %   ✅ Ziel < 300 ms erreicht

Fixes (nach Beitrag):
  H1  N+1 → JOIN            840→320 ms  (−62 %)   [user.repo.ts]  Tests grün
  H2  O(n²) → Set-dedup     320→235 ms  (−27 %)   [report.service.ts]  Tests grün
  H3  moment → date-fns     235→210 ms  (−11 %, Bundle −180 kB)  [main.bundle]

Regressions-Check:  Writes +3 % (Index-Kosten, akzeptiert) · Peak-RAM unverändert
Offen / bewusst nicht gefixt:  H4 Template-Render 4 % — unter Schwelle, dokumentiert
Branch:  perf/api-latency
```

**Regeln:**
- **Jede Zeile hat eine Vorher→Nachher-Zahl** aus derselben Messung. Keine „gefühlt schneller"-Einträge.
- **Regressions-Check ist Pflicht**, nicht optional — die geopferte Nachbar-Metrik gehört benannt.
- **Bewusst nicht gefixte Hotspots** mit Grund listen (unter Schwelle / zu riskant / braucht Umbau) — Ehrlichkeit vor Vollständigkeits-Theater.

---

## ANTI-PATTERNS (die teuren Fehler)

- **Raten statt messen** — „bestimmt die Regex" → 2 h an 2 % Laufzeit optimiert. Immer erst profilen.
- **Kalten Pfad optimieren** — schön, aber Amdahl-irrelevant. Nur was im Profil heiß ist.
- **Mehrere Fixes, eine Messung** — Delta nicht zuordenbar, ein Fix könnte sogar schaden und vom anderen maskiert sein.
- **Micro-Benchmark ohne Warmup/echte Daten** — misst JIT/Cache, nicht Realität.
- **Korrektheit für Tempo opfern** — schneller falsches Ergebnis, kaputter Edge-Case. Tests bleiben grün.
- **Premature Optimization im Feature-Bau** — erst korrekt & vollständig (`/feature-delivery`), dann Hot-Path (dieser Skill). Nicht umgekehrt.
- **Endlos-Optimieren ohne Ziel** — ohne Zielzahl kein Stopp-Kriterium.
