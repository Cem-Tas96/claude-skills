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
  /performance-boost. Denkt wie IT-Architekt + Security-Engineer. Läuft als autonome LOOP-ENGINE
  (Loop Engineering): jeder Aufruf gibt dem Lauf EIN Ziel und er promptet sich selbst — findet die Arbeit,
  erledigt sie, prüft sie mit unabhängigen Subagenten (Writer ≠ Reviewer), merkt den Fortschritt in einem
  durablen Checkpoint und macht weiter bis die DoD wirklich erfüllt ist. Nutzt die fünf Loop-Bausteine
  (Automation/Worktrees/Skills/Connectors/Subagents) risiko-proportional statt Hand-Holding.
---

# Feature-Delivery Skill — Enterprise Zero-Regression Implementation

## KERNPHILOSOPHIE

> **Die meisten Bugs sind keine falschen Zeilen — es sind fehlende Zeilen.**
> Der Bug ist die Aufruf-Stelle die du nicht angefasst hast, der Reverse-Pfad den du nicht geschrieben hast, die State-Zelle die du nicht gefüllt hast, der Falsy-Wert den du nicht behandelt hast. Code-Skill verhindert das nicht. **Vollständige Kartierung VOR dem ersten Edit** verhindert das.

> **Code zuerst kartieren, dann mutieren.**
> Wer editiert bevor er den vollständigen Blast-Radius kennt, schreibt den ersten von vier Commits. Wer zuerst jede betroffene Stelle auflistet, schreibt einen.

> **Symmetrie ist kein Stil — es ist Korrektheit.**
> Jedes `grant` ohne sein `revoke`, jedes `open` ohne `close`, jedes `subscribe` ohne `unsubscribe`, jede Migration `up` ohne `down`, **jede Status-Wechsel-Mail ohne ihre Gegen-Mail** (welcome ohne goodbye, signup ohne verify, cancel ohne cancellation-receipt, payment-success ohne payment-failed) ist ein halb gebautes Feature, das in Production die andere Hälfte nachfordert.

> **Grün in der falschen Schicht ist rot in Production.**
> Ein Test der im jsdom besteht aber den Browser-Race nicht reproduziert, ist kein Beweis — es ist eine Beruhigungspille. Ein 250-OK von SMTP ist kein Beweis dass die Mail beim Empfänger lesbar ankommt. Ein Stripe-Webhook-200 ist kein Beweis dass der Checkout das richtige Produkt zeigt.

> **„Live verifiziert" ohne Klick-Beweis ist eine Vermutung.**
> Behauptungen wie „end-to-end durchgetestet", „alle Mails live", „129 Tests grün" sind Marketing für die eigene Stand-up. Wahrheit ist nur was als **echter User-Klick-Through mit echter Karte, echter Mailbox-Inspektion, echtem Passwort-Reuse über alle Layer** belegt wurde — Screenshot je Stufe oder es zählt nicht.

> **Was nicht aus einer benannten Quelle stammt, ist erfunden.**
> Preise, Limits, Plan-Features, Pricing-Page-Texte, Plan-Beschreibungen, AGB-Klauseln, Mail-Inhalte werden **nicht aus dem Modell halluziniert**. Wenn keine Notion-Page / kein Spec-File / kein CMS-Eintrag als Quelle existiert: **STOP** und fragen — nicht plausibel-klingenden Marketing-Text generieren.

> **Dummy ist Production solange er nicht ersetzt wurde.**
> "Hab das damals auf Dummy-Basis schnell gebaut" wird zu einem live ausgelieferten Stripe-Plan mit "0,80 € pro Einheit"-Phantom-Posten — wenn niemand explizit nach `TODO|FIXME|DUMMY|PLACEHOLDER|hardcoded|sample` scannt. WIP-Code mit aktivem Production-Pfad ist die teuerste Klasse von Bugs, weil im Coverage-Ledger nichts "fehlt".

> **Multi-Repo-User-Journeys sind ein Feature, kein N getrennte Features.**
> Landing → Billing → Stripe → Flow ist EINE Onboarding-Kette über drei Repos. Wenn der Skill jeden Repo einzeln verifiziert aber niemand die Kette als ganzes klickt, fällt der Auth-Sync-Bruch zwischen Landing-Signup-PW und Flow-Login-Hash garantiert durchs Raster.

> **Der Client ist feindlich; die neueste Lücke ist noch nicht in deinem Wissen.**
> Geld, Zugang und Berechtigung entscheidet der Server aus der Quelle der Wahrheit — nie aus IP, Geo, VPN-Erkennung oder einem Client-Flag. Und weil täglich neue Angriffe erscheinen, prüfst du bei jedem Lauf einmal die frischeste Bedrohungslage, statt dich auf Gestern zu verlassen. „Unhackbar" verspricht niemand — aber jede bekannte Klasse ist bewusst gedeckt und kein kritischer Pfad geht ungeprüft live.

> **Du schreibst keine Prompts mehr — du baust die Schleife.**
> Prompt-Engineering hält dich im Hin-und-Her: du nimmst den Agenten bei jedem Schritt an die Hand. Loop-Engineering dreht das um — du gibst **ein Ziel**, und der Lauf promptet sich selbst: er findet die Arbeit, erledigt sie, prüft sie (mit einem **unabhängigen** Subagenten — wer schreibt ist nicht wer bewertet), merkt den Fortschritt in einem **durablen Checkpoint** und macht weiter, **bis die DoD wirklich erfüllt ist** — nicht bis der Prompt endet. Dieser Skill IST diese Schleife; die Phasen unten sind ihr Körper. Voll-Protokoll: `references/loop-engine.md`.

> **Brute-Force-Loops sind kein Skill, sondern Token-Waste.**
> 10x denselben Skill im Loop laufen lassen "bis er kein Bock mehr hat" produziert mit der 4. Iteration kein neues Wissen mehr. **Coverage-Wachstum messen**: 3 Iterationen ohne neue Ledger-Zeile → STOPP, das Verbleibende braucht entweder eine andere Methode (Klick-Through, Spec-Quelle, menschliche Entscheidung) oder ist außerhalb der erreichbaren Coverage. „Immer loopen" heißt **nicht** „immer maximale Automatik": die Schleife läuft bei jedem Aufruf, ihre Autonomie-Tiefe (inline → Wake-up → Cron → Worktree-Fächer) skaliert mit der Arbeit.

**Du bist nicht fertig wenn der Happy-Path läuft. Du bist fertig wenn jede betroffene Stelle nachweislich angefasst, jede Transition abgedeckt, jeder Reverse-Pfad symmetrisch gebaut, jede UI-Aussage aus einer benannten Quelle belegt, jeder Dummy ersetzt, jede User-Journey end-to-end im echten Browser geklickt, jede Mail visuell im echten Client gerendert und jedes Plan-Limit adversarial getriggert ist.**

Dieser Skill ist die destillierte, projekt-unabhängige Lehre aus ~150 Bug-Folgekommits **plus den dokumentierten Misses an einem Multi-Repo-SaaS-Onboarding** (Stripe-Doppel-Subscription mit erfundenem "0,80 €/Einheit"-Posten, Welcome-Mail die "domo!" statt Vornamen zeigt, Login nach Zahlung schlägt fehl, Pricing-Page mit hergereimten Features, vergessene Cancel-Confirmation-Mail). Diese Bug-Klassen sind in den Phasen unten als **konkrete Pflicht-Checks** kodifiziert — sie wiederholen sich nicht zufällig.

Er existiert um genau eine Sache zu erreichen: **1 Prompt → vollständig & korrekt eingebautes Feature.** Nicht "läuft bei mir", sondern "kann nicht mehr kaputt sein, weil jede Klasse wo der Bug sonst säße — Code-Stellen, Reverse-Pfade, Mail-Pflichten, Spec-Quellen, Multi-Repo-Übergänge, Dummy-Reste, Plan-Limits, Brand-Audit — ist geschlossen und mit Screenshot/Beweis belegt."

---

## BETRIEBS-MODUS: LOOP-ENGINE (autonome Selbst-Prompting-Schleife)

> **Jeder Aufruf dieses Skills startet eine Schleife, keinen Einmal-Lauf.** Du bekommst **ein Ziel** und der Lauf promptet sich selbst durch die Phasen, bis die DoD wirklich erfüllt ist. Das ist Loop-Engineering: das System, das den Agenten für dich promptet, statt ihn an die Hand zu nehmen. Voll-Protokoll: `references/loop-engine.md` (Eilig? → §12 Quickstart-Runbook).

**Der Antrieb läuft IMMER (bei jedem Aufruf, auch dem kleinsten):**
1. **Ziel** als Contract (P0) festnageln.
2. **Checkpoint laden/anlegen** (`references/loop-engine.md` §2) — der durable Spiegel von Ledger + Loop-Status unter `~/.claude/.cache/feature-delivery/<slug(pwd)>.loop.json`. Existiert er → **resumen** (ab `phaseCursor` weiter, DONE-Bedingung neu prüfen); sonst neu anlegen.
3. **Iterieren** — jede Runde: **ASSESS** (nächste unerledigte Arbeit aus dem Ledger ableiten — nicht „und jetzt?" fragen) → **ACT** (genau diese eine Arbeit tun) → **VERIFY** (frischer Subagent prüft, Writer ≠ Reviewer) → **RECORD** (Checkpoint schreiben, Coverage-Delta messen) → **DECIDE** (DoD erfüllt? → terminal; offen + Wachstum? → weiter; 3× kein Wachstum? → eskalieren) → **CONTINUE** (inline weiter oder Wiederaufruf takten).
4. **Enden nur an der DONE-Bedingung** (DoD P6.1 vollständig ✔, 0 `offen`) oder einer Stop-Garantie (Diminishing-Returns / NEEDS_CONTEXT / BLOCKIERT) — **nicht** weil „der Prompt zu Ende ist".

**Autonomie-Tiefe ist tiered (nicht „immer maximale Automatik"):** inline-Selbst-Prompting ist der Default; `Monitor`/`ScheduleWakeup`/`/loop` nur wenn der Lauf auf einen externen Zustand wartet (CI/Deploy/Migrations-Fenster/externes Review — ereignisgetrieben via `Monitor` bevorzugt, sonst selbst-getaktetes Pollen); `/schedule`+`CronCreate` nur für wiederkehrende Pflichten; `isolation:"worktree"` nur bei echter Parallel-Mutation. Darunter liegt die **harness-getriebene `settings.json`-Hook-Schicht** (SessionStart/Stop/PostToolUse, via `/update-config`) — automatisierte Verhaltensweisen, die der **Harness** ausführt, nicht der Agent (z.B. der SessionStart-Auto-Pull dieses Skills-Repos). Welche Automation-Primitive verfügbar sind, via `ToolSearch` prüfen statt annehmen; Mechanik skaliert mit der Arbeit (`references/loop-engine.md` §1/§7).

**Verhaltensregeln innerhalb der Schleife:**

1. **Niemals sofort coden.** Erst Phase 0–2 (Contract → Blast-Radius → Modellierung) durchlaufen. Das ist autonome Vorarbeit, dafür musst du nicht fragen.
2. **Nur EINMAL fragen — und nur bei einer konsequenten Gabel** die du nicht aus dem Code (oder einem verbundenen Connector, P1.8 / `loop-engine.md` §8) beantworten kannst (z.B. zwei legitime Produktverhalten, Datenverlust-Risiko, irreversible Migration). Dann gebündelt via einer einzigen Rückfrage → Loop pausiert als NEEDS_CONTEXT. Alles was aus Code, Spec, Connector, Git-History oder Konvention ableitbar ist: **selbst entscheiden und im Report notieren** — nicht fragen.
3. **Unvollständigkeit IMMER VOR dem Commit melden.** Wenn du während der Implementierung merkst dass die State-Table oder das Coverage-Ledger eine Lücke hatte: sag es, erweitere das Ledger (→ neue Ledger-Zeile + Checkpoint), baue nach — **bevor** du committest. Niemals als Folgekommit. (Das ist die #1-Ursache der historischen 4-Commit-Ketten.)
4. **Liefere mit Beweis, nicht mit Behauptung.** Der Delivery-Report (Phase 6) ist Pflicht. "Done" ohne abgehaktes Coverage-Ledger ist verboten. **Selbst-Prompting heißt nicht selbst-genehmigend:** die Schleife darf sich nie selbst SHIP geben, solange eine DoD-Box offen ist.

> Tempo entsteht nicht durch früheres Coden — sondern dadurch dass du nicht viermal zurück musst, und dass die Schleife ohne Hand-Holding weiterläuft, bis sie nachweislich fertig ist.

---

## ZUSAMMENSPIEL MIT DEN TEST-/SECURITY-/PERF-SKILLS

Dieser Skill ist der **äußere Loop** (vollständig & korrekt bauen). `/feature-testing` ist der **Test-Modul darin** (Verhalten beweisen). Doppelung wird bewusst vermieden — Test-Strategie, Test-Quality-Gates und Auto-Fix-Loop gehören `/feature-testing`, nicht hierher.

> **Das ist Loop-Baustein 3 (Skills):** dieser Skill + die Sub-Skills (`/feature-testing` · `/verify` · `/security-review` · `/code-review` · `/simplify`) + der `CLAUDE.md`/`AGENTS.md`-Projektkontext sorgen dafür, dass die Schleife das Projekt **nicht jedes Mal neu erklärt** bekommen muss — sie kennt es aus den geladenen Skills und der Projekt-Doku.

```
   /feature-delivery — die LOOP-ENGINE (jeder Aufruf = eine Schleife, nicht ein Einmal-Lauf):

   ┌────────────────────────────────────────────────────────────────────────────┐
   │ LOOP-ENGINE-ANTRIEB (läuft immer · references/loop-engine.md)               │
   │   GOAL = Contract · CHECKPOINT laden/anlegen (durabel, überlebt Wake-up)    │
   │   Iteration: ASSESS → ACT → VERIFY(Writer≠Reviewer) → RECORD → DECIDE       │
   │   Ende NUR an DONE-Bedingung (DoD ✔ · 0 offen) oder Stop-Garantie           │
   └────────────────────────────────────────────────────────────────────────────┘
        │  (Phasen P0–P7 sind der Körper der Schleife)
        ▼
   PRE-FLIGHT  Loop-Checkpoint laden → Resume oder neuer Loop
               + Threat-Intel-Refresh (1×/Tag: neueste CVEs/Angriffe → Exposure-Check)
               + Branch/Worktree-Isolations-Gate (Arbeits-Branch; Worktree bei Parallel-Mutation)
               + WIP-Scan (Dummy/Placeholder/Mock/TODO im berührten Code)
               + Grün-Baseline-Gate (existierende Suite vor dem Edit grün, wenn nicht trivial)
        ↓
   P0  Auftrags-Contract
   P1  Blast-Radius → Coverage-Ledger
       (Agenten-Fächer nach Tier · Anti-Halluzinations-Gate · NO-FAIL: kalte Zweit-Ableitung)
       P1.7  Cross-Repo Journey-Map (wenn mehrere Repos die Kette teilen)
       P1.8  Spec-Source-of-Truth (jede UI-Behauptung muss eine benannte Quelle haben)
       P1.95 Design-Optionen-Gate (nur bei architektonischem Blast-Radius: 2–3 Ansätze, begründet wählen)
        ↓
   P2  Modellierung
       P2.1–2.4  State-Table · Invarianten · Falsy · Contracts
       P2.5      Security-Pass (komplette Taxonomie)
       P2.6      Mail-Pflicht-Matrix (signup/verify/welcome/cancel/refund/passwordreset)
       P2.7      Brand/White-Label-Sweep (CLAUDE.md-Regeln · "Powered by …"-Verbote · Logo/Font)
        ↓
   P3  Tier-Floor-Gate (deterministisch) · Risiko-Tier · Test-Tier · Rollout-Strategie
        ↓
   P4  Implementierung (alle Ledger-Stellen, symmetrisch)
       P4.5  WIP-Replacement-Gate (jeder Dummy-Treffer aus Pre-flight muss ersetzt sein)
        ↓
   P5  Verifikation:
         • Independent-Verifier   (NO-FAIL: Red-Team-Agent Ledger↔Diff — fehlt/erfunden?)
         • Staged-Review          (ab Risiko-Signal: Spec-Compliance → dann Code-Quality, je frischer Agent)
         • invoke /feature-testing   (Test-Beweis: Mocks/jsdom)
         • invoke /verify            (Real-Runtime: echte App)
         P5.5  END-TO-END USER-KLICK-THROUGH (echte Karte/Mailbox/Browser-Session)
               · Screenshot je Stufe · echte Stripe-Test-Karte 4242…
               · echte Mailbox-Öffnung (visuelles Render-Audit)
               · echtes Passwort-Reuse über alle Layer
         P5.6  Adversarial Plan-Limit-Tests (limit+1 für jeden behaupteten Cap)
         P5.7  Email-Template Visual Inspection (HTML in echtem Client geöffnet,
               Anrede/Name/Links/Buttons funktionieren)
         P5.8  Multi-Repo Onboarding-Smoke (Landing→Billing→Stripe→App als eine Kette,
               Pflicht wenn Cross-Repo-Journey berührt)
         • invoke /security-review   (Diff-Security gegen heutige Threat-Intel)
         • optional /performance-boost (Hot-Path)
        ↓
   P6  DECIDE: DoD + Delivery-Report + Checkpoint schreiben
        →  offen & Coverage wuchs  → CONTINUE  ──►► PRE-TERMINAL-RÜCKSPRUNG direkt zu ASSESS (ohne P7)
        →  3× kein Wachstum        → STOP-1 Diminishing-Returns (anderes Werkzeug, §u.)
        →  Entscheidung/Info fehlt  → STOP-2 NEEDS_CONTEXT (die EINE Frage)
        →  harter Bug              → STOP-3 BLOCKIERT (Root-Cause file:line)
        →  DoD ✔ & 0 offen         → terminal: SHIP / DONE_WITH_CONCERNS  ↓ (nur hier geht's zu P7)
   P7  Rollout (rückwärtskompatibel · Flag/Kill-Switch · Rollback · Observability)
       + Branch-Finish + Checkpoint archivieren/löschen (erledigter Loop ≠ Resume)
       + Wirksamkeits-Signal (fing der Aufwand etwas? → Feedback-Loop)
       ──►► optionale Folge-WELLE (Monitor/ScheduleWakeup/Cron-getaktet) startet einen NEUEN Loop
            (frischer Checkpoint, nicht Resume des erledigten) — nur wenn weitere Wellen geplant sind.

   STOP-1 — LOOP-DISZIPLIN (Coverage-Diminishing-Returns):
       3 Iterationen ohne neue Ledger-Zeile / ohne neue gefundene Stelle → STOPP.
       Weiteres Hämmern produziert kein neues Wissen — entweder anderes Werkzeug
       (Klick-Through · Spec-Quelle/Connector · menschliche Entscheidung) oder das
       Verbleibende ist außerhalb der erreichbaren Coverage. Brute-Force ist Token-Waste.
       Triggert KEIN Modell-Upgrade und keine höhere Agenten-Kopfzahl.
```

**Reihenfolge ist nicht verhandelbar:** zuerst Loop-Checkpoint laden (Resume?), dann (1×/Tag) der Threat-Intel-Refresh, dann Blast-Radius & Modell, dann Code, dann `/feature-testing` → `/verify` → `/security-review`. Wer `/feature-testing` vor vollständiger Implementierung laufen lässt, beweist eine halbe Implementierung. Der Loop-Antrieb (`references/loop-engine.md`) trägt diese Reihenfolge über alle Iterationen — er ersetzt keine Phase, er ordnet sie als Schleifen-Körper an.

Wenn `/feature-testing` im Projekt nicht verfügbar ist: Phase 5 trotzdem durchführen, dabei die Test-Disziplin aus `references/verification.md` inline anwenden.

---

## PRE-FLIGHT — LOOP-INIT + GATES (läuft bei JEDEM Aufruf zuerst)

### Pre-Flight Teil 0 — LOOP-CHECKPOINT (Resume oder neuer Loop) ★ macht den Lauf zur Schleife

> **Zweck:** Den durablen Loop-Zustand laden, bevor irgendetwas anderes passiert — so überlebt die Schleife Context-Kompaktierung und Wake-ups und „weiß, wann sie fertig war". Voll-Protokoll: `references/loop-engine.md` §2.

1. **Checkpoint-Pfad** bilden: `~/.claude/.cache/feature-delivery/<slug(pwd)>.loop.json` (slug = `pwd`, führender Slash weg, restliche `/` → `-`; identische Konvention zum Threat-Intel-Stamp).
2. **Existiert die Datei** → **RESUME**: `goal`, `tier`, `ledger`, `phaseCursor`, `doneBoxes`, `status` laden. Ist `status` terminal (SHIP/…) und das aktuelle Ziel deckt sich → der Loop ist erledigt; **nicht** fälschlich weiterlaufen (neuer Auftrag = neuer Checkpoint). Sonst ab `phaseCursor` weiter, DONE-Bedingung neu prüfen.
3. **Fehlt die Datei** → **NEUER LOOP**: nach P0 (Contract) anlegen; `status="RUNNING"`, `phaseCursor="P0"`.
4. **Nach jeder Iteration** den Checkpoint schreiben (RECORD-Schritt) — er ist die einzige Wahrheit, auf die ein Wiederaufruf vertrauen darf. `ts` von außen stempeln (kein `Date.now()` in Subagenten/Workflows).

> Rein lokal (eine JSON-Datei), kostet nichts, läuft immer — auch bei winzigen Changes. Der Unterschied zwischen „Loop" und „Einmal-Lauf mit Loop-Vokabular" ist genau dieser Schritt.

### Pre-Flight Teil 1 — TÄGLICHER THREAT-INTEL-REFRESH

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

### Pre-Flight Teil 1b — BRANCH/WORKTREE-ISOLATIONS-GATE (vor Phase 0, Pflicht)

> **Zweck:** Der Default-Branch ist das Bild der Wahrheit für produktive Systeme. Direkt dort mutieren — ohne umkehrbaren Kontext — ist ein Reversibilitäts-Verstoß gegen den Kern-Geist dieses Skills. Ein Arbeits-Branch ist die billigste Absicherung überhaupt und kostet Sekunden. Bei **Parallel-Mutation** (Loop-Baustein 2) wird der Branch zum **Worktree** erweitert, damit gleichzeitig arbeitende Agenten sich nicht in die Quere kommen.

1. **Branch erkennen** — nur wenn das Projekt ein Git-Repo ist (sonst `N/A — kein Git` und weiter): aktuellen Branch lesen und gegen den **erkannten Default** prüfen (`git symbolic-ref refs/remotes/origin/HEAD` → Default-Name; Fallback `main`/`master`).
2. **Ist der aktuelle Branch der Default → Gate greift.** Auflösung in dieser Reihenfolge:
   - **(a) Automatisch branchen** — knapper Name aus dem Contract (`feature/…` / `fix/…`); alle weiteren Commits gehen dorthin.
   - **(b) Mehrere legitime Namen / unklarer Scope** → die EINE gebündelte Rückfrage mit konkretem Vorschlag (Ein-Prompt-Autonomie), nicht eine Frage-Kaskade.
   - **(c) Expliziter Consent** des Bosses („direkt auf den Default") → als `CONSENT: direct-on-default` im Delivery-Report dokumentieren (selten, braucht bewusste Freigabe).
3. **Isolations-Tier wählen (Loop-Baustein 2, `references/loop-engine.md` §9):**
   - **Sequenzieller Einzel-Change** → Arbeits-Branch genügt, kein Worktree-Overhead.
   - **Parallele mutierende Stränge** (zwei Features gleichzeitig · Workflow-`agent()`-Stränge die Dateien schreiben) → **`isolation:"worktree"`** je Strang bzw. `EnterWorktree` für interaktive Stränge; Pfad ins Checkpoint-Feld `worktree`. Read-only Recon/Verifikation (`Explore`) braucht **keinen** Worktree.
4. **Nie still auf dem Default editieren.** Das Ergebnis (`Branch: feature/…` / Worktree-Pfad / Consent) gehört ins Feld `Branch:` des Delivery-Reports (P6.2).

> **Projekt-agnostisch:** gilt für jeden Forge/Stack (GitHub/GitLab/Bitbucket/lokal). Kein Git-Repo → das Gate entfällt **dokumentiert** (`N/A — kein Git`), der Lauf geht weiter.

### Pre-Flight Teil 2 — WIP-SCAN (in jedem Lauf, billig, deterministisch)

> **Zweck:** Dummy-/Placeholder-/Mock-/Hardcoded-Reste im berührten Code-Pfad erkennen **bevor** Phase 1 startet. Diese sind die teuerste Bug-Klasse, weil sie im Coverage-Ledger nicht als "fehlt" erscheinen — der Code-Pfad funktioniert technisch, liefert aber semantisch Müll (Stripe-Plan "0,80 € pro Einheit" als Phantom-Posten im Live-Checkout, gerendert aus einem Dummy der nie ersetzt wurde).

1. **Berührte Pfade bestimmen:** alle Dateien/Ordner im Blast-Radius-Umkreis (alles was Phase 1 voraussichtlich anfasst — bei `--change is fix in pricing/billing/onboarding` z.B. `landing/`, `billing/`, `flow/`, `prisma/`, Stripe-Config, Mail-Templates).
2. **WIP-Grep (Pflicht, schmaler Filter — nur in berührten Pfaden):**
   ```
   TODO|FIXME|XXX|HACK|DUMMY|PLACEHOLDER|TEMP|TEMPORARY|REPLACE|MOCK|STUB
   hardcoded|hard-coded|sample|example\.com|test_|TEST_|dev_only|do not ship
   lorem ipsum|foo|bar|baz|asdf|123456|password123|changeme
   ```
3. **Pro Treffer entscheiden** (im Ledger als eigene Zeilen-Art `WIP` aufnehmen):
   - **REPLACE** — vor Ship durch echte Production-Konfig ersetzen (Pflicht für jeden Treffer auf Produktionspfad).
   - **N/A — Test/Doc/Dev-Only** mit Datei-Pfad belegt (`spec.ts`/`test/`/`docs/`/`README`-Pfad).
   - **N/A — Akzeptiert mit Grund**: explizit dokumentieren warum (z.B. echter Stripe-Test-Mode `sk_test_…` ist erwünscht in Test-Env).
4. **`WIP`-Zeilen sind Stop-Bedingungen wie jede andere Ledger-Zeile:** kein SHIP solange auch nur eine `WIP-REPLACE`-Zeile `offen` steht. (Genau das war der Stripe-Dummy: er war im Code, kein Test schlug an, aber er war semantisch eine Live-Bug-Bombe.)

> 🚨 **Historischer Miss:** „Hab das damals auf Dummy-Basis schnell gebaut" → ein Stripe-Plan mit zusätzlichem metered Price (`0,80 €/Einheit`) blieb live, weil im Coverage-Ledger nichts "fehlt"e. Der WIP-Scan hätte das Token `dummy|hardcoded|sample` getroffen — wäre er gelaufen.

### Pre-Flight Teil 3 — GRÜN-BASELINE-GATE (nur wenn nicht trivial)

> **Zweck:** Vor dem ersten Edit eine **grüne Baseline** der existierenden Tests feststellen — trennt Alt-Fehler (schon vorher rot) von neu eingeführten. Ohne Baseline maskiert ein vorab-roter Test eine echte Regression.

1. **Trigger** (einer reicht): Ledger ≥ 3 Zeilen · Symmetrie-Paar · Cross-Layer-Kopplung · NO-/LOW-FAIL. Trivial / BEST-EFFORT → **entfällt** (Tempo).
2. **Test-Scope ableiten** (stack-agnostisch): Test-Runner aus dem Manifest erkennen (`package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `Makefile` / …). Kein Manifest / keine Suite → `N/A — keine automatisierte Test-Suite`, weiter.
3. **Baseline-Lauf** auf sauberem Stand; Ergebnis kurz dokumentieren (Tests gesamt · bestanden · vorab-rote). Ist die Baseline **schon rot** → ehrlich BLOCKIERT: „kann kein Delta messen, Baseline erst grün machen" — nicht auf einer kaputten Baseline weiterbauen.
4. **Nach der Änderung** (P5.4-Sweep) das **Delta** vergleichen; jeder **neu** rote Test ist eine neue Ledger-Zeile und blockiert.

> Rein lesend (führt nur Tests aus, editiert nichts). Projekt-agnostisch — Runner und Manifest aus der Projektstruktur ableiten, nicht annehmen.

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

### 1.3b Instruktions-Präzedenz (explizite Anweisung lockert nur Ermessens-Gates)
Nennt eine **explizite** Quelle — `CLAUDE.md`/`AGENTS.md` oder eine direkte Nutzer-Ansage — eine Regel oder ein Gate, hat sie **Vorrang** vor der Default-Einstellung dieses Skills, **aber nur für Ermessens-Gates** (Risiko-Tier, Agenten-Budget, Test-/Scan-Umfang). Die Lockerung wird als Ledger-Zeile `Präzedenz-Anweisung` mit Quelle + Grund **notiert**, nie still angewandt.
> **Token-Discipline (globaler Lean-Default):** Der Default für Agenten-Kopfzahl + Subagenten-Modell steht in `~/.claude/skills/token-discipline/token-router.md` und gilt vor jedem Lauf (Datei fehlt — z.B. bei Plugin-Installation statt Repo-Clone? → dann ist `references/multi-agent.md` §1/§1.6 der vollständige Default). `ultracode` hebt das Risiko-Tier **nicht** an (siehe `references/multi-agent.md` §1 ULTRACODE-GUARD): trivial/schmal bleibt inline/Haiku, der teure Fächer kommt erst bei echtem Risiko-Signal.
> **Nicht aufweichbar** (laufen immer, egal welche Anweisung): Threat-Intel-Refresh (Pre-flight), Anti-Halluzinations-/Ledger↔Diff-Kreuzaudit, Mail-Symmetrie bei State-Wechsel (DSGVO). Faustregel: hängt das Gate **nicht** vom Boss ab (pure Architektur/Sicherheit/Rechtspflicht) → es läuft; ist es ein Ermessens-Gate → die benannte Anweisung darf es lockern, dokumentiert.

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
| signup-trigger | verify-email + welcome-email (DSGVO/UX) |
| subscription-create | subscription-cancel-confirmation-email (DSGVO Art. 7 widerrufbar belegt) |
| payment-success-mail | payment-failed-mail + dunning-mail |
| password-reset-request | password-reset-completed-confirmation-mail |
| account-anonymize / GDPR-erasure | erasure-confirmation-mail (Art. 17 Beleg) |
| invoice-create | invoice-PDF + invoice-mail-attachment |
| trial-start | trial-end-reminder (T-3, T-1) + trial-expired-notice |

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

### 1.7 CROSS-REPO JOURNEY-MAP (Pflicht wenn das Feature eine Multi-Repo-Kette berührt)

> **Zweck:** Wenn ein User-Flow über mehrere Repos läuft (typisch: `landing` → `billing` → `stripe` → `flow/app` für SaaS-Onboarding; oder `admin-portal` → `api` → `worker` → `webhook-receiver` für interne Flows), behandeln viele Skills jeden Repo einzeln — und die **Übergänge** fallen durchs Raster. Genau dort sitzen die teuersten Bugs (Auth-Sync-Bruch, Datensynchronisations-Drift, fehlende Idempotenz an Repo-Grenzen). Voll-Protokoll: `references/multi-repo-journey.md`.
> 
> **Historischer Miss:** Signup auf Landing setzte ein Passwort, Stripe-Webhook im Billing erzeugte den User im Flow-Repo — aber das Passwort wurde nie ans Flow synchronisiert. „Abonnement aktiviert" zeigte grün, **Login auf Flow schlug mit dem beim Signup eingegebenen Passwort fehl.** Jeder Einzelschritt war intern korrekt. Die Übergänge waren niemandes Code.

**Wann triggert P1.7?**
- Das Feature wird in mehreren Repos editiert ODER
- Der Test-Klick-Through müsste auf mehreren Domains/Hosts laufen ODER
- Es existieren mehrere `package.json`/`pyproject.toml`/`Cargo.toml`-Wurzeln im Blast-Radius ODER
- Ein User-State (Account, Subscription, Permission, Onboarding-Status) wird über Webhook/API/Queue an einen anderen Repo propagiert

**Pflicht-Artefakt:** die **Journey-Tabelle**

```
JOURNEY: [Name, z.B. "Trial-Signup → Paid-Account"]

Schritt | Wo (Repo · Datei)            | Eingang             | Ausgang/Effekt       | Übergangs-Mechanismus       | Status
--------|-------------------------------|---------------------|----------------------|------------------------------|-------
S1      | landing · signup.tsx          | Email + PW          | User in landing-DB   | landing-Auth-API             | offen
S2      | landing · post-signup         | landing-Session     | redirect → billing   | URL + Session-Cookie         | offen
S3      | billing · checkout.ts         | Email aus Session   | Stripe checkout sess | stripe-sdk                   | offen
S4      | stripe (extern)               | Card                | webhook payment_int  | Stripe-Webhook (signiert!)   | offen
S5      | billing · webhook.ts          | webhook payload     | User-Status active   | DB-Update + Provision-Event  | offen
S6      | flow · provision-listener     | Provision-Event     | Account+Pw im Flow   | API-Call landing→flow        | offen ← typischer Bruch
S7      | flow · login                  | Email + dasselbe PW | Session              | flow-Auth                    | offen ← bricht hier sichtbar
```

**Regeln:**
- **Jeder Übergang ist eine eigene Zeile** mit Übergangs-Mechanismus (Cookie/Redirect/Webhook/Queue/API/Direct-DB-Write).
- **Webhook-Übergänge:** Signatur verifiziert? Idempotent? Retry-sicher (kein Doppel-Provision bei Webhook-Retry)?
- **Auth-Übergänge:** Das **Geheimnis** (PW-Hash, Session-Token, JWT) — wer schreibt es, wer liest es, ist das Hash-Verfahren auf beiden Seiten identisch? (Klassiker: bcrypt vs argon2id mismatch.)
- **State-Übergänge:** Eventual-Consistency-Lücke? Was, wenn der User Schritt N+1 schneller klickt als Schritt N synct?
- **Jede Zeile bekommt einen Klick-Through-Beweis in P5.8.**

> Die Journey-Tabelle ist **Teil des Coverage-Ledgers** (jede Zeile bekommt eine ID `J1..Jn`) und blockt Ship gleichermaßen.

### 1.8 SPEC-SOURCE-OF-TRUTH (Pflicht bei UI-Texten, Preisen, Limits, Plan-Features)

> **Zweck:** Verhindern dass LLM/Skill Inhalte halluziniert die wie plausibles Marketing klingen, aber nicht aus einer benannten Quelle stammen. Wenn niemand sagen kann „dieser Text/Preis/Limit kommt aus *dieser* Notion-Page / *diesem* Spec-File / *diesem* CMS-Eintrag", ist er **erfunden** und gehört nicht in die Lieferung. Voll-Protokoll: `references/spec-source-of-truth.md`.
> 
> **Historischer Miss:** Pricing-Page zeigte „Alle Verbindungen inkl. KI", „5 Nutzer-Accounts", „1.000.000 Aktionen / Monat", „Unbegrenzte Wohneinheiten", „Custom Connectors", „Dedizierter Ansprechpartner" — vom LLM aus dem Plan-Namen hochgereimt. Boss-Reaktion: „Ich glaube ja Claude hat das einfach hergereimt."

**Pflicht-Check für jede Stelle die Phase 1 als „enthält user-sichtbaren Marketing/Preis/Limit/Feature-Text" markiert:**

1. **Quelle benennen** — pro Stelle eine Antwort auf: „**Woher** stammt dieser Text/Preis/Limit?"
   - Akzeptable Quellen: Notion-Page (URL), Spec-Dokument im Repo (Pfad), CMS-Eintrag (ID), Stripe-Dashboard (Product-ID + Price-ID), DB-Tabelle (Tabelle + Row), Mail-Template-Vorlage (Pfad).
   - Inakzeptabel: „aus dem Modell", „plausibel klingend", „so wie es bei Konkurrenten ist", „Cem hatte das mal gesagt" (ohne dokumentierte Quelle).
   - **Connector zuerst (Loop-Baustein 4):** ist ein Notion-/CMS-/Ticket-Connector verbunden, die Quelle **direkt ziehen** (`notion-search`/`notion-fetch` via `ToolSearch`) statt zu fragen — der gezogene Wert ist eine benannte Quelle (Page-ID/URL). Voll: `references/loop-engine.md` §8.
2. **Quell-Inhalt vs. Code-Inhalt diff'en** — die Werte im Code Zeichen-für-Zeichen mit der Quelle (Repo-Spec ODER gezogenem Connector-Inhalt) vergleichen. Abweichung → `WIP-REPLACE` ins Ledger.
3. **Fehlt eine Quelle** für eine UI-Behauptung (und kein Connector liefert sie) → **STOP**, beim Boss/Owner gebündelt nachfragen (eine einzige Rückfrage, nicht je Stelle) → Loop pausiert als NEEDS_CONTEXT. Keine plausibel klingenden Marketing-Texte erfinden.
4. **Plan-Limits/Preise speziell:** zusätzlich gegen die **Stripe-Konfiguration** (Product+Price+Metered-Components) diff'en. Wenn UI „1.000.000 Aktionen / Monat" zeigt aber Stripe-Plan hat kein metered-Quota dafür → ist die Behauptung nicht enforced (Lücke 8). → ins Ledger als `SPEC-SOT-MISMATCH`.

> **Faustregel:** Wenn nach dem Ship eine Person fragt „warum steht da '5 Nutzer-Accounts'?", muss eine Antwort der Form „weil das in [Quell-URL] so steht" möglich sein. Sonst gehört der Text dort nicht hin.

### 1.9 Das COVERAGE-LEDGER (Pflicht-Artefakt)
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

## PHASE 1.95 — DESIGN-OPTIONEN-GATE (nur bei architektonischem / mehrdeutigem Blast-Radius)

> **Zweck:** Wenn Phase 1 mehrere technisch zulässige Wege mit unterschiedlichen Konsequenzen offenlegt, vor der Modellierung **2–3 Ansätze skizzieren, begründet einen wählen, die Verworfenen notieren** — damit man sich nicht stillschweigend an eine schlechte Architektur bindet. Das ist der einzige Fehler, den keine noch so gute Coverage repariert. Bewusst **kein** Dialog mit dem Boss (das bräche die Ein-Prompt-Autonomie); die Entscheidung ist autonom und wird im Report belegt.

**Trigger (einer reicht):**
- Mehrere legitime Implementierungs-Pfade (z.B. additives Feld mit Default vs. separate Migration; Rolle in bestehender Tabelle vs. neue Junction-Tabelle; Feature-Flag vs. direkt).
- Ein Cross-Layer-Entscheidungspunkt (Config-Duplikat konsolidieren vs. bewusst parallel lassen).
- Unterbestimmte State-Shape (Cancel = Status-Feld vs. Soft-Delete vs. `activeUntil`-Timestamp — verschiedene Folgen für Archiv/Query/Rollback).
- Ein Symmetrie-Paar mit mehreren Lösungstechniken (grant via direkter Rolle vs. via Entitlement-Tabelle).

**Nicht triggern:** triviale Änderung · genau **ein** technischer Weg · Entscheidung bereits dokumentiert oder vom Boss vorgegeben (`CLAUDE.md`/Spec). Dann: `P1.95 N/A`.

**Prozess (< 5 Min, intern — kein Boss-Dialog):**
1. **Mehrdeutigkeit benennen** (1 Satz).
2. **2–3 Skizzen** (je 3–5 Zeilen: Technik · Hauptvorteil · Hauptnachteil).
3. **Bewerten** gegen: **Ledger-Größe** (welcher Weg trifft weniger Stellen?) · **Symmetrie/Konsistenz** mit bestehenden Patterns · **Rollback-Sicherheit** (reversibel vs. neue Migration) · **Datenmodell-Kosten**.
4. **Wählen + Verworfene mit Grund notieren** → zurück zu P2 (keine Rückfrage; die Mehrdeutigkeit ist aufgelöst).

**Selbstaudit (schnell, vor P2):**
- [ ] Liegt überhaupt eine Mehrdeutigkeit vor (nicht bei jedem Change)?
- [ ] 2–3 Skizzen ausgearbeitet (keine Einzeiler, kein 30-Seiten-Design)?
- [ ] Eine begründet gewählt, Verworfene mit Grund notiert (nicht stumm verschwunden)?

> Die Entscheidung gehört in den `DESIGN-ENTSCHEIDUNG`-Block des Delivery-Reports (P6.2) — damit bei Rollback-Diskussionen klar ist, warum dieser Weg und nicht der andere. Projekt-agnostisch: rein methodisch, keine Stack-Annahme.

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

### 2.6 MAIL-PFLICHT-MATRIX (bei jeder Status-Wechsel-Aktion auf einer User-Identität)

> **Zweck:** Sicherstellen dass jeder Statuswechsel auf einer User-/Account-/Subscription-Identität die DSGVO- und UX-Pflicht-Mails hat — **gepaart mit ihren Counter-Mails**. Mail-Symmetrie ist eine Spezialform der §1.4-Symmetrie, aber häufig vergessen weil die "andere Hälfte" nicht im Code-Pfad sondern in einem separaten Mailer-Service liegt. Voll-Protokoll + Pflicht-Liste: `references/mail-symmetry.md`.
> 
> **Historischer Miss:** Subscription-Cancel-Endpoint funktionierte, **Cancel-Confirmation-Mail war nicht im Code** — `0 von n` Kündigern hatten eine Bestätigung. DSGVO-Beleg-Pflicht verletzt. Cem-Selbst-Report wörtlich: "es ist gar nicht im Code integriert, das ist schon ein Decker, das ist schon DSGVO".

**Matrix-Check für jeden berührten Statuswechsel** — pro Trigger eine Tabellen-Zeile:

| Trigger | Pflicht-Mail vorwärts | Pflicht-Mail rückwärts/symmetrisch | Im Code belegt? (file:line) | Im echten Client geöffnet? (P5.7) |
|---|---|---|---|---|
| signup | verify-email (Doppel-Opt-In!) | account-deletion-confirmation (bei Erasure) | | |
| verify-email-clicked | welcome-mail | | | |
| trial-start | (kein Trigger-Mail) | trial-expiry-T-3 + trial-expired | | |
| subscription-create | payment-receipt + invoice-pdf | subscription-canceled-confirmation | | |
| payment-failed | dunning-1 (T+0) | dunning-2 (T+3), dunning-3 (T+7) | | |
| subscription-canceled | cancel-confirmation (DSGVO Art. 7) | reactivation-offer (optional) | | |
| password-reset-requested | reset-link-mail (10min-Token) | reset-completed-confirmation | | |
| email-changed | confirm-on-old + confirm-on-new | | | |
| permission-grant (z.B. admin) | grant-notice | revoke-notice | | |
| account-anonymized (GDPR-Art-17) | erasure-confirmation | | | |

**Regeln:**
- **Jede markierte Zeile bekommt eine Ledger-ID** (`M1..Mn`) — wie alle anderen Coverage-Stellen.
- **Doppel-Opt-In bei signup ist Pflicht** in DE/EU (Wettbewerbsrecht + DSGVO-Einwilligung). Ein Welcome-Mail VOR Verify ist ein Bug.
- **Cancel-Confirmation ist DSGVO Art. 7 Abs. 3** ("Widerruf so einfach wie Einwilligung") — der Beleg ist die Mail. Ohne sie ist die Kündigung nicht beweisbar.
- **Mails dürfen den Namen/Anrede des Empfängers nicht aus dem Email-Local-Part oder Username-Slug konstruieren** ("Willkommen domo!" weil Username `appuser` ist) — Anrede kommt aus `firstName`/`displayName`-Feld, mit dokumentiertem Fallback ("Hallo," wenn leer, nie "Hallo {{slug}}!").
- **Jede Mail wird in P5.7 visuell in einem echten Mail-Client geöffnet** — nicht nur "SMTP returned 250".

### 2.7 BRAND/WHITE-LABEL-SWEEP (bei jeder UI-/Mail-/Asset-Änderung)

> **Zweck:** Verhindern dass beim Fork/White-Label/Rebrand Reste des Original-Brands (Logo, Name, Slogan, "Powered by …", Schriftart, Farbcode) live ausgeliefert werden. Voll-Protokoll: `references/brand-audit.md`.
> 
> **Historischer Miss:** Landing-Page eines White-Label-Forks zeigte "Powered by Activepieces" im Footer, Logo fehlte, Schriftarten waren inkonsistent — obwohl im CLAUDE.md des Projekts klipp-und-klar steht „alle customer-facing UI muss white-labeled sein, kein hardgecodetes 'Activepieces'". Niemand prüft das automatisch.

**Pflicht-Schritt bei jedem berührten UI/Mail/Asset-Pfad:**
1. **CLAUDE.md/AGENTS.md lesen** und Brand-Regeln extrahieren (verbotene Strings, erforderliche Strings, erforderliche Assets).
2. **Verbots-Grep** über alle berührten + alle live ausgelieferten Bundles:
   - Original-Produktname (z.B. `Activepieces`, `activepieces`, `AP_`, `Bubble`, `Retool`, je nach Fork-Origin) als Wort-Boundary.
   - „Powered by …"-Footer-Reste.
   - Original-Domain-Strings (`activepieces.com`, `*.activepieces.com`).
   - Original-Asset-Pfade (`/assets/activepieces-logo`).
3. **Pflicht-Strings** ("Branded by Cem GmbH", Custom-Logo-Pfad, eigene Farbe) müssen vorhanden sein.
4. **Mail-Templates extra:** jede Mail-Vorlage öffnen, im Header/Footer auf den eigenen Brand prüfen — Mails sind häufig ein blinder Fleck weil sie nicht über `/verify` rendern.
5. **Generierte Bundles prüfen**: `dist/`/`build/`/`out/` greppen — manchmal lebt der alte Brand in einer kompilierten Datei, die im Source schon ersetzt ist.

> **Treffer → `BRAND-LEAK`-Zeile ins Ledger, sofortiger BLOCKIERT-Status.** Brand-Leaks haben sowohl rechtliche (Trademark) als auch Customer-Trust-Konsequenzen — billig zu finden, teuer zu erklären.

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

### 4.5 WIP-REPLACEMENT-GATE
Jede `WIP`-Zeile aus dem Pre-flight-Scan (Dummy/Placeholder/Mock/hardcoded) muss vor Commit auf `✓ (ersetzt)` oder `N/A (+begründet)` stehen. **`WIP-REPLACE offen` blockiert genauso wie eine Code-Ledger-Zeile.** (Genau diese Klasse war der Stripe-Dummy-Live-Bug.)

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

### 5.0b Staged-Review — Spec-Compliance, dann Code-Quality (eigene Linse neben dem Kreuzaudit)
Der Kreuzaudit (5.0) prüft **Coverage** („fehlt/erfunden?"). Er beantwortet **nicht** „ist das *Richtige* gebaut?" und nicht „ist es *gut* gebaut?". Diese zwei Linsen laufen jetzt — **getrennt, in dieser Reihenfolge, mit frischen Augen** (Voll-Protokoll + Prompt-Vorlagen: `references/staged-review.md`):
- **Stufe 1 — Spec-Compliance** (gegen P0-Contract + Spec-Quelle P1.8, **nicht** gegen das eigene Ledger): fängt **under-built** (Akzeptanz-Kriterium nicht erfüllt), **over-built** (ungefragter Scope-Creep), **misinterpret** (richtige Anforderung, falsches Verhalten/Default), **unsourced** (halluzinierter UI-Text/Preis). **Muss grün sein, bevor Stufe 2 startet** — Quality-Review von weg-zu-werfendem Code ist doppelt verschwendet.
- **Stufe 2 — Code-Quality** (Diff + Umfeld): Duplizierung existierender Utils, unbehandelter Fehler-/Falsy-Pfad, Idiom-/Naming-Bruch gegen das Umfeld, toter Pfad, Lesbarkeit. Nach dem letzten Fix **einmal re-checken**.

**Wer prüft, skaliert mit der Blast-Radius-Form** (wie 5.0): **Self-Review** beim schmalen LOW-FAIL, **frischer `Explore`-Agent je Stufe** ab Risiko-Signal (>8 Ledger-Zeilen · Symmetrie-Paar · Cross-Layer-Kopplung · Sub-Agenten gefächert) und immer bei NO-FAIL.
> Reviewer-Output durchläuft **dasselbe** Anti-Halluzinations-Gate (§1.5) wie jeder Agent. Offener Spec-Compliance-Befund (under/over/misinterpret/unsourced) = **BLOCKIERT**. Quality-Befunde der Klassen Duplizierung/Fehlerbehandlung sind grenzwertig zu Korrektheit → blockieren bei NO-FAIL.
> **Externes Feedback** (Mensch/Tool/Auditor während dieser Phase): nicht annehmen, sondern **verarbeiten** — jedes Finding klassifizieren · am Source validieren · mit Code-/Test-Beleg zurückschieben · Konflikt mit einer Vorentscheidung eskalieren statt auto-anwenden. Protokoll: `references/receiving-review.md`.

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
> **Bricht hier (oder in 5.1/5.2) etwas — Test rot, `/verify` falsches Verhalten, Invarianten-Verletzung —: NICHT raten.** Ab dem ersten erfolglosen Fix das Root-Cause-First-Protokoll fahren (`references/systematic-debugging.md`): Ursache benennen (`file:line` + Warum) → failing Test (RED→GREEN) → **ein** gezielter Fix → Sweep erneut. **Harte Regel: nach 3 Fehlversuchen STOPP** und Architektur/Annahme hinterfragen — exakt die Coverage-Diminishing-Returns-Disziplin, aufs Debuggen angewandt. Guess-and-Check baut versteckte Regressionen ein und ist langsamer, nicht schneller.

### 5.5 END-TO-END USER-KLICK-THROUGH (echte Karte · echte Mailbox · echter Browser · Screenshot je Stufe)

> **Zweck:** Den menschlichen User imitieren — nicht den Test-Harness, nicht den Smoke-Request. Diese Phase ist der einzige Beweis dass das Feature aus Sicht des Käufers funktioniert. Voll-Protokoll: `references/e2e-clickthrough.md`.
> 
> **Historischer Miss:** Status-Doc behauptete „Stripe end-to-end durchgetestet", „Email-Versand live verifiziert", „129 Tests grün". Boss klickte zwei Minuten durch und fand: Stripe-Checkout zeigt 2 Subscriptions ("69 €" + Phantom "0,80 €/Einheit"), Welcome-Mail grüßt mit "domo!", Login nach Zahlung schlägt fehl mit "Ungültige E-Mail oder Kennwort". Smoke-Tests beweisen Tech-Pfade. **Sie beweisen keinen Käufer-Erfolg.**

**Pflicht bei jedem Change der eine User-Journey berührt** (Auth, Payment, Onboarding, Trial, Cancellation, Refund, Permission, neue Mail, neue Landing-Page).

**Pflicht-Skript (durchführen oder Browser-Agent steuern):**
1. **Frischer privater Browser-Tab** (Cookie/Storage leer) — kein Persistenter Login-Cache.
2. **Stage 1: Discovery** — Pricing/Landing-Page öffnen, **Screenshot** machen. Jede Plan-Karte mit der Spec-Source-of-Truth-Quelle (P1.8) abgleichen.
3. **Stage 2: Signup** — echte zufällige Mail-Adresse aus einer **realen Mailbox die man öffnen kann** (Gmail/Mailtrap/MailHog/Mailpit lokal); echtes nicht-triviales Passwort merken. Submit. **Screenshot** der Post-Signup-Seite.
4. **Stage 3: Verify-Mail** — in dieser Mailbox die Verify-Mail finden. **HTML der Mail visuell anschauen** (P5.7). Verify-Link klicken in **demselben Browser**.
5. **Stage 4: Plan-Auswahl + Payment** — gewählten Plan klicken, Stripe-Checkout öffnet. **Screenshot der Checkout-Seite** — pro Line-Item prüfen: ist es ein erwartetes Item? Ist der Preis exakt der UI-Preis aus Stage 1? Ist ein Phantom-Posten (z.B. "0,80 €/Einheit") sichtbar?
6. **Stage 5: Echte Stripe-Test-Karte** — `4242 4242 4242 4242` + zukünftiges Datum + beliebiger CVC + Rechnungsadresse + Firmen-Option testen (falls B2B). Submit.
7. **Stage 6: Post-Payment-Redirect** — Ziel-URL? Welche Mail kommt jetzt (Receipt? Welcome-Paid? Beides?). **Screenshot + Mail-HTML-Inspection.**
8. **Stage 7: Login mit dem Signup-Passwort** — auf dem App-Login-Screen die Mail aus Stage 2 + das Passwort aus Stage 2 eingeben. **Hier sitzt der Multi-Repo-Auth-Sync-Bruch.** Erfolgt der Login? Wenn nicht → Journey-Tabelle P1.7 hat eine offene Zeile, sofort BLOCKIERT.
9. **Stage 8: First-Workflow** — kann der frisch eingeloggte User die behauptete Hauptaktion ausführen? (1 Workflow erstellen, 1 Custom-App auswählen, 1 Aktion abfeuern.)
10. **Stage 9: Cancel-Pfad** — Subscription kündigen, Cancel-Confirmation-Mail finden, lesen. Wenn keine Mail kommt → DSGVO-Lücke (P2.6), sofort BLOCKIERT.
11. **Stage 10: Forgot-Password** — Logout, "Passwort vergessen" klicken, Reset-Mail finden, Link nutzen, neues PW setzen, einloggen. Jede dieser Stufen ist ein häufiger Bruch.

**Browser-Agent verfügbar?** Wenn `agent-browser`-Skill / Playwright-Setup / `mcp__chrome*` o.ä. da ist: das automatisiert ausführen lassen, Screenshots speichern, Mail-Bodies dumpen. Sonst: manueller Klick-Through mit Screenshot-Disziplin (jedes Screenshot bekommt einen Stufen-Index als Dateiname).

**Bedingungen die BLOCKIERT triggern (jede einzeln):**
- Eine Stufe schlägt fehl ODER
- Stripe-Checkout zeigt unerwartete Line-Items ODER
- Eine Pflicht-Mail (aus P2.6-Matrix) kommt nicht an ODER
- Eine Mail rendert kaputt (defekte Anrede, defekte Links, Buttons funktionieren nicht, Brand-Leak) ODER
- Login mit dem Signup-PW über die Multi-Repo-Grenze schlägt fehl ODER
- Ein Plan-Limit-Text aus der UI ist nicht in der echten Stripe-/Backend-Config hinterlegt (P5.6).

> **Faustregel:** Wenn du den Klick-Through nicht selber durchziehen kannst (kein Browser-Agent, kein Mailtrap, kein Stripe-Test-Account) → das ist nicht „best effort", das ist **BLOCKIERT mit Grund "Klick-Through nicht ausführbar — Boss-Aktion oder Tooling notwendig"**. Lieber ehrlich blocken als „läuft bei mir" behaupten.

### 5.6 ADVERSARIAL PLAN-LIMIT-TESTS (jedes UI-versprochene Limit muss adversarial getroffen sein)

> **Zweck:** Jede UI-Behauptung „Bis X Einheiten / X Aktionen / X Nutzer-Accounts" ist eine implizite Sicherheits-Garantie. Wenn der Server limit+1 erlaubt, ist die Behauptung gelogen UND der Plan ist nicht kommerziell sicher (Free-Tier-Abuse).
> 
> **Historischer Miss:** Boss-Frage „Plan-Limits werden korrekt enforced?" → Antwort „lass ich testen". Code-Review hatte das nicht abgedeckt — die Pricing-Page zeigte „Bis 500 Wohneinheiten", aber niemand hat 501 Wohneinheiten in einem Starter-Plan erzeugt.

**Pflicht für jeden behaupteten Plan-Cap aus P1.8 / Pricing-Page:**
1. Im niedrigsten Plan einloggen.
2. Limit-Wert + 1 erzeugen versuchen (501 Wohneinheiten, 11ter Workflow, 250.001ste Aktion, 51ster Nutzer-Account).
3. Erwartetes Verhalten: **HTTP 402 Payment Required** oder vergleichbarer expliziter Block + UX-Upgrade-CTA.
4. Tatsächliches Verhalten beobachten. Wenn `limit+1` durchgeht → BLOCKIERT mit `LIMIT-BYPASS`-Ledger-Zeile.
5. **Boundary-Test:** auch `limit-1`, `limit`, `limit+1`, `limit*10` durchspielen — typischer Off-by-One.
6. **Wichtige Variante:** wenn das Limit metered (per-unit-billing) ist, prüfen ob `limit+1` zwar erlaubt wird aber **abgerechnet** wird. Sonst ist das Limit eine Lüge in beide Richtungen.

### 5.7 EMAIL-TEMPLATE VISUAL INSPECTION (jede Mail im echten Mail-Client gerendert)

> **Zweck:** „SMTP 250 OK" beweist nur dass der Server die Mail angenommen hat. Nicht dass sie den Empfänger erreicht, nicht dass sie im Spam landet, nicht dass die HTML im Dark-Mode lesbar ist, **und schon gar nicht dass die Anrede einen echten Namen statt eines Username-Slug enthält.**
> 
> **Historischer Miss:** Welcome-Mail-Anrede war „Willkommen bei MyApp, domo!" / „Willkommen bei MyApp, appuser!" — Username-Slug fiel direkt in die `{{firstName}}`-Variable. Niemand hatte die Mail je in einem Mail-Client geöffnet.

**Pflicht pro Mail-Template das in P2.6 als angefasst markiert ist:**
1. Mail an die echte Test-Mailbox aus P5.5 senden.
2. **In einem echten Mail-Client öffnen** — Gmail Web ODER iOS Mail ODER Outlook Web ODER Mailtrap/Mailpit-UI. Nicht nur Source-Code anschauen.
3. **Visual-Audit-Checkliste:**
   - Anrede: ein echter Name? Kein Username, kein E-Mail-Local-Part, kein `null`/`undefined`/`{{firstName}}`-Template-Rest.
   - Brand-Audit: Logo da? Korrekter Brand-Name? Keine "Powered by …"-Reste?
   - Links: jeden klicken, prüfen ob das Ziel die erwartete Domain ist (nicht `localhost`, nicht Original-Brand-Domain, nicht 404).
   - Button-Text: macht der Sinn im Kontext? ("Zu MyApp" oder generisch "Click here"?)
   - Dark-Mode: in Gmail Dark-Mode anschauen — gelegentlich verschwindet weißer Text auf weißem Hintergrund.
   - Unsubscribe-Link: Pflicht in Marketing-Mails, klick-bar?
   - Footer: Impressum-Link funktioniert?
4. **Screenshot speichern, in den Delivery-Report einbinden.**

### 5.8 MULTI-REPO ONBOARDING-SMOKE (wenn P1.7 eine Journey-Tabelle hatte)

> **Zweck:** Die Journey-Tabelle aus P1.7 Schritt-für-Schritt als realer Klick-Through ausführen — **jeder Übergang ist ein eigener Beweis**.

Aus der Journey-Tabelle ableiten:
- Für jeden Schritt: kurze Beobachtung + Screenshot/Log-Snippet + Status `✓` / `✗`.
- Besonders kritisch: Webhook-Übergänge (S4→S5 in unserem Beispiel) → in den Server-Logs prüfen dass der Webhook empfangen + verifiziert + idempotent verarbeitet wurde.
- Auth-Übergänge: die `users`-Row auf beiden Seiten der Grenze (landing-DB vs flow-DB) öffnen — sind die Hashes identisch? Ist der Hash-Algo identisch?
- State-Übergänge mit Eventual-Consistency: gibt es einen sichtbaren „warten"-Zustand für den User oder fliegt er auf eine 404?

**Output:** die Journey-Tabelle aus P1.7 wird zum **Klick-Through-Protokoll** mit `✓`/`✗` je Zeile + Screenshot-Pfaden. Eine offene Zeile = BLOCKIERT.

---

## PHASE 6 — DEFINITION OF DONE & DELIVERY-REPORT

### 6.1 DoD-Checkliste (jede Box muss ✔ sein)
- [ ] **Loop-Engine geführt (P0/Pre-flight Teil 0)** — Checkpoint angelegt/resumed & bei jeder Iteration geschrieben; `status` an `doneBoxes` gekoppelt (kein selbst-vergebenes SHIP); Autonomie-Tier passend (inline Default, Wake-up/Cron/Worktree nur gegen konkretes Warten/Parallel-Problem); bei SHIP Checkpoint archiviert/gelöscht — Selbstaudit `references/loop-engine.md` §11
- [ ] **Coverage-Ledger vollständig** — jede Zeile ✓ oder `N/A (+Grund)`, keine `offen`
- [ ] **Branch/Worktree-Isolations-Gate (Pre-flight)** — nicht auf dem Default-Branch mutiert: Arbeits-Branch angelegt (`Branch:` im Report) **oder** `isolation:"worktree"`-Strang bei Parallel-Mutation **oder** dokumentierter `CONSENT: direct-on-default` **oder** `N/A — kein Git`
- [ ] **WIP-Scan abgehandelt** — jeder Pre-flight-Treffer (`TODO|DUMMY|HARDCODED|…`) ist `✓ (ersetzt)` oder `N/A (+Datei-Pfad als Test/Doc-Beleg)`
- [ ] **Produktions-Hygiene** — kein test-only-Code in Produktionsklassen (Iron-Law, `wip-scanner.md` §6); keine reinen Mock-Assertions ohne Verhaltens-Beweis (`/feature-testing` Gate 7)
- [ ] **Reverse-Pfade** im selben Change angefasst (oder `N/A` begründet) — inkl. **Mail-Symmetrien** aus P2.6
- [ ] **State-Table** vollständig, alle Invarianten in allen Zellen erfüllt
- [ ] **Falsy-Enumeration** für jede neue Validierung durchgegangen
- [ ] **Cross-Layer-Kopplung** (Config-Duplikate / Shared-Lib-Consumer / `CLAUDE.md`-Behaviors) abgedeckt
- [ ] **Cross-Repo Journey-Map (P1.7)** — bei Multi-Repo-Features: jede Übergangs-Zeile in P5.8 mit ✓ belegt (Screenshot/Log je Übergang)
- [ ] **Spec-Source-of-Truth (P1.8)** — jeder user-sichtbare Marketing/Preis/Limit-Text hat eine benannte Quelle; UI-Code-Wert == Quell-Wert (Zeichen-für-Zeichen)
- [ ] **Design-Optionen (P1.95)** — bei architektonischer Mehrdeutigkeit: 2–3 Ansätze gegeneinander skizziert, einer begründet gewählt, Verworfene notiert (oder `N/A — trivial / 1 Weg / dokumentiert`)
- [ ] **Mail-Pflicht-Matrix (P2.6)** — pro Trigger im Diff ist Vorwärts- + Counter-Mail im Code belegt + in P5.7 visuell verifiziert
- [ ] **Brand/White-Label-Sweep (P2.7)** — keine Original-Brand-Reste; CLAUDE.md-Brand-Regeln eingehalten; Mail-Templates auf Brand geprüft
- [ ] **Agenten-Befunde verifiziert** — jede vom Sub-Agenten gemeldete Stelle am Source gegengelesen (kein blind übernommener Pfad)
- [ ] **Instruktions-Präzedenz & Rekursions-Guard** — explizite User-/Projekt-Anweisungen gelesen, Gate-Lockerungen als `Präzedenz-Anweisung` notiert (oder `N/A`); gefächerte Agenten angewiesen, `/feature-delivery` nicht zu re-entern
- [ ] **Ledger↔Diff-Kreuzaudit** sauber (immer außer trivial): Selbst-Audit beim schmalen LOW-FAIL, **unabhängiger Verifier** ab Risiko-Signal/NO-FAIL; bei NO-FAIL zusätzlich kalte Zweit-Ableitung (Konsens) — keine offenen (a)/(b)/(c)/(d)-Befunde
- [ ] **Staged-Review (P5.0b)** — Spec-Compliance (under/over-built · misinterpret · unsourced) grün **vor** Code-Quality (Duplizierung · Fehlerbehandlung · Idiom · toter Pfad); ab Risiko-Signal/NO-FAIL je frischer Agent; keine offenen blockierenden Befunde
- [ ] **Externes Review verarbeitet (falls angekommen)** — jedes Finding klassifiziert (Real/kontext-blind/halluziniert/unklar), am Source validiert (Laufzeit-Test bei Laufzeit-Bug), Pushback mit Beleg statt Diskurs, echte Bugs als E-Ledger-Zeilen (`references/receiving-review.md`)
- [ ] **Bei Brüchen Root-Cause-First** (`systematic-debugging.md`) gefahren — Ursache benannt, RED→GREEN-Test, kein Guess-and-Check, nach ≤3 Fehlversuchen Architektur hinterfragt
- [ ] **Threat-Intel heute aktualisiert** (Pre-flight gelaufen; `exposed`-Funde gemittelt oder geblockt)
- [ ] **Security-Pass** ohne offene Findings (NO-FAIL: `security-hardening.md`-Taxonomie §1 + zero-fail-zones komplett)
- [ ] **`/security-review`** auf dem Diff sauber; bei Payment/Zugang: Paywall-/Abuse-Härtung (server-seitiges Entitlement, **kein** IP/Geo-Gate) geprüft
- [ ] **Test-Beweis** in der gewählten Schicht grün (`/feature-testing`-Urteil = AUSLIEFERN)
- [ ] **Real-Runtime-Proof via `/verify`** dokumentiert (Browser bei UI-Timing, Real-Stack nach Clean-Bring-up bei Env/Infra; Fallback: manuell)
- [ ] **End-to-End User-Klick-Through (P5.5)** — bei User-Journey-Changes: alle 10 Stages durchgeführt, Screenshots gespeichert, keine BLOCKIERT-Bedingung getroffen
- [ ] **Adversarial Plan-Limit-Tests (P5.6)** — jeder UI-versprochene Cap mit `limit+1` adversarial getestet; keine `LIMIT-BYPASS`-Funde
- [ ] **Email-Template Visual Inspection (P5.7)** — jede angefasste Mail in echtem Client geöffnet, Screenshot gespeichert, Anrede + Brand + Links + Buttons funktional
- [ ] **Multi-Repo Onboarding-Smoke (P5.8)** — bei Cross-Repo: Journey-Tabelle Schritt-für-Schritt als ✓-Liste, Webhook-Logs geprüft, Auth-Hash-Identität bestätigt
- [ ] **Grün-Baseline-Gate (Pre-flight Teil 3, wenn nicht trivial)** — existierende Suite vor dem Edit grün dokumentiert; nach dem Change 0 neu-rote Tests (oder als Ledger-Zeile erfasst); `N/A` bei trivial / keiner Suite
- [ ] **Regressions-Sweep** grün (bestehende Tests, Lint, Typecheck, Build)
- [ ] **Tier-Floor-Gate** angewandt — Auth/Payment/Rollen/PII/Migration berührt → NO-FAIL gesetzt (nicht per Ermessen heruntergestuft)
- [ ] **Rollout (P7)** für Prod-Changes belegt — rückwärtskompatibel, Kill-Switch (NO-FAIL), Rollback getestet, Observability live (oder `N/A` begründet bei rein lokalem Tooling)
- [ ] **Branch-Finish (P7.1)** — Disposition gewählt (lokal/PR/Archiv, NO-FAIL→Review), Report als PR-Body/Handoff, Post-Merge-Retest bei NO-FAIL durchgeführt (oder `N/A`)
- [ ] **Loop-Disziplin** — nicht im Brute-Force-Loop gefahren; keine 3 aufeinanderfolgenden Iterationen ohne neue Ledger-Zeile / neue Coverage; bei Stall auf anderes Werkzeug eskaliert (Klick-Through/Connector/menschliche Entscheidung), kein Modell-Upgrade/Kopfzahl-Hochfahren (STOP-1, `loop-engine.md` §4)
- [ ] **Writer ≠ Reviewer (Loop-Baustein 5)** — der VERIFY-Schritt lief durch einen frischen, von der Implementierung unabhängigen Subagenten (kein Recon-Stream, der nur sich selbst bestätigt); Output durchs Anti-Halluzinations-Gate
- [ ] **Graded-Status konsequent (P6.2b)** — SHIP nur bei 0 offen; DONE_WITH_CONCERNS nur mit benannten Concerns + Owner + Deadline; NEEDS_CONTEXT mit der einen Frage; BLOCKIERT mit Root-Cause (file:line/Artefakt)
- [ ] **Commit-Message** benennt Invariante & Reverse-Pfad (nicht nur das Symptom)

> Ist ein Punkt offen → **melden, nicht "done" sagen.** Vor dem Commit, nicht als Folgekommit.

### 6.2 Delivery-Report (Pflicht-Output)

```
═══════════════════════════════════════════════════════
FEATURE DELIVERY REPORT
═══════════════════════════════════════════════════════
Feature:        [Name]            Projekt: [Repo]
Branch:         [feature/… angelegt | isolation:worktree-Strang | Default + CONSENT: direct-on-default | N/A — kein Git]
Risiko-Tier:    NO-FAIL / LOW-FAIL / BEST-EFFORT
Test-Tier:      Unit / Integration / Real-Browser / Real-Stack-Smoke  (Begründung)

LOOP-ENGINE
  Automation-Modus:  inline / Monitor / ScheduleWakeup / Cron-Routine   (Begründung des Tiers)
  Checkpoint:        [Pfad · n Iterationen · resumed? · bei SHIP archiviert/gelöscht]
  Iterationen:       [n — letzte coverageDelta · coverageStall-Stand]
  Writer ≠ Reviewer: [VERIFY durch unabhängigen Subagenten? ja/Selbst-Audit + Grund]
  Connectoren:       [gezogen: Notion/M365/… für Spec-Quelle (P1.8) | zurückgeschrieben: Report (6.2c) | keiner verfügbar]
  Stop-Grund:        [DONE (DoD ✔) / Diminishing-Returns / NEEDS_CONTEXT / BLOCKIERT]

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

DESIGN-ENTSCHEIDUNG (P1.95 — bei architektonischer Mehrdeutigkeit)
  Mehrdeutigkeit:   [was war unterbestimmt / N/A — trivial/1 Weg/dokumentiert]
  Gewählt:          [Ansatz + Grund in 1 Satz]
  Verworfen:        [Ansatz X: Grund · Ansatz Y: Grund]

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
  E2E Klick-Through (P5.5): [10 Stages durchgespielt? | Screenshot-Pfade | N/A — kein User-Flow berührt]
  Adversarial Limits (P5.6): [n Caps getestet · 0 Bypässe / Findings: Liste]
  Email-Visual (P5.7):       [n Mails visuell auditiert · Anrede OK · Brand OK / Findings]
  Multi-Repo-Smoke (P5.8):   [Journey-Tabelle n Schritte · alle ✓ / offene Schritte / N/A]
  Spec-Source-of-Truth:      [n UI-Texte gegen Quelle geprüft · 0 erfunden / Mismatches]
  WIP-Scan:                  [n Treffer · alle ersetzt / N/A-belegt]
  Brand-Sweep:               [keine Leaks / Liste]
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
URTEIL: SHIP / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKIERT
Grund (bei BLOCKIERT):              [konkret — file:line/Artefakt, nicht "geht nicht"]
Concerns (bei DONE_WITH_CONCERNS):  [Klasse → Owner → Deadline; je Concern eine Zeile]
Context needed (bei NEEDS_CONTEXT): [die EINE Frage → an wen]
═══════════════════════════════════════════════════════
```

> **BLOCKIERT = nichts verlässt den Branch** bis der Grund behoben ist. Ein offenes Coverage-Ledger ist immer BLOCKIERT.

### 6.2c Connector-Write-back (Loop-Baustein 4 — die Schreib-Hälfte, `references/loop-engine.md` §8)

> **Zweck:** Connectoren ziehen nicht nur (P1.8), sie **bedienen** auch — der Loop schreibt das Ergebnis dorthin zurück, wo das Team es erwartet, statt es nur lokal auszugeben.

- Ist ein **Notion-/Ticket-/Chat-Connector** verbunden (via `ToolSearch` geladen): den Delivery-Report (6.2) in die **benannte Quelle** zurückschreiben — Notion-Page-Update / Ticket-Kommentar / Status-Sync (z.B. `notion-update-page`, Ticket-Comment-API). Bei Multi-Repo-Journey (P1.7) den Status an der verlinkten Onboarding-Page/dem Epos aktualisieren.
- **Kein Connector verfügbar** (oder headless/cron-Lauf ohne interaktive Auth) → Report lokal lassen und im Feld `Connectoren:` notieren („keiner verfügbar — Report lokal").
- Write-back ist **read-after-write-bewusst:** keine Secrets/Keys aus dem Report in eine extern indizierte Quelle schreiben (CLAUDE.md-Secret-Regel gilt auch für Connector-Ziele).

### 6.2b Graded Completion Status (Zwischenstufen statt binär)

Damit „funktional fertig, aber außerhalb dieses Prompts hängend" nicht fälschlich als harter Block oder als sauberes SHIP verbucht wird, hat das Urteil vier Stufen:

| Status | Bedeutung | Auslöser | Folge |
|---|---|---|---|
| **SHIP** | live-fähig | alle DoD ✔, 0 offene Ledger-/Verifier-Befunde, verifiziert | deployen (P7) |
| **DONE_WITH_CONCERNS** | funktional vollständig & verifiziert, aber ≥1 **benannter, dokumentierter Rest** | Concern-Klasse-Treffer + Owner + Deadline festgenagelt | shippen **mit** Concern-Tracking; Rollout ok |
| **NEEDS_CONTEXT** | hängt an einer **Entscheidung/Information** (kein Code-Bug) | Boss-OK / Spec-Klärung / Zugang fehlt; DoD sonst ✔ | **kein Merge** bis Antwort; die EINE Frage an den Owner |
| **BLOCKIERT** | offene **Code-/Daten-/Sicherheits-Lücke** | Ledger `offen` · Verifier-Befund · `/verify`-Bruch · Security-Finding | nichts verlässt den Branch; Root-Cause benannt |

**Concern-Katalog** (löst DONE_WITH_CONCERNS aus — funktional korrekt, aber geschäftlich/architektonisch unvollständig): zurückgestellte Härtung · sekundäre UI fehlt · Eventual-Consistency-Lag · Live-Datenmigration ausstehend · externes Setup nötig (Key/Webhook/Plan) · Observability noch nicht konfiguriert · Kundenkommunikation/Changelog offen · Compliance/Legal-Review offen.

> **Faustregel:** Fehlt **„Code schreiben"** → Bug (BLOCKIERT). Fehlt **„jemand sagt ja / externes Setup / Compliance / Migrations-Fenster"** → Concern (DONE_WITH_CONCERNS mit Owner + Deadline) oder NEEDS_CONTEXT, **kein** Block. Rein über die Art des fehlenden Schritts entschieden — projekt-agnostisch.

> **STOP-1 (Loop-Diminishing-Returns) ist kein eigener Status.** Wenn die Schleife nach 3 Iterationen ohne neue Coverage stoppt (`references/loop-engine.md` §4), wird das Verbleibende **ehrlich auf eine der vier Stufen abgebildet**: braucht es ein anderes Werkzeug/eine Entscheidung → **NEEDS_CONTEXT** (die eine Frage) oder **DONE_WITH_CONCERNS** (benannter Rest + Owner + Deadline); ist eine harte Lücke offen → **BLOCKIERT**. Das Feld `Stop-Grund: Diminishing-Returns` im Report begründet nur, *warum* die Schleife endete — der **Status** bleibt einer der vier.

---

## PHASE 7 — ROLLOUT, REVERSIBILITÄT & POST-SHIP (für Prod-gerichtete Changes mit aktiven Kunden)

> Korrekt & lokal bewiesen (P5/P6) ist nicht dasselbe wie *sicher bei zahlenden Kunden gelandet*. Diese Phase greift bei jedem Change der Prod trifft (entfällt nur bei rein lokalem Tooling ohne Prod-/Datenpfad). Voll-Protokoll + Expand-Contract-Tabelle: `references/rollout.md`.

Die in P3.4 gewählte Strategie jetzt **belegen** (nicht nur geplant):
- [ ] **Rückwärtskompatibel ausgeliefert** — additiv/nullable-first; brechende Schritte (`contract`) auf späteren Release verschoben (`references/rollout.md` §1).
- [ ] **Phasenweise + Kill-Switch** — riskant/NO-FAIL hinter Flag, Aus-Schalter greift **ohne Redeploy** in Sekunden; Flag-Aus-Pfad ist ein sauberer getesteter Zustand (§2).
- [ ] **Rollback bewiesen** — Revert benannt, `migration down` getestet, neu geschriebene Daten von der alten Version lesbar; irreversibler Anteil (echte Charge/Mail) isoliert & idempotent (§3).
- [ ] **Observability live** — Log/Metrik auf Erfolg **und** Fehler des neuen Pfads, Alert auf den relevanten Bruch, neue Exception von Sentry erfasst; bei NO-FAIL die P2.2-Invariante als laufender Monitor (§4).

> Faustregel: Ist die Antwort auf „und wenn das in Prod bricht?" ein neuer Hotfix-Deploy statt ein Schalter — **nicht produktionsreif.**

### 7.1 Branch-Finish & PR-Handoff (Lieferung an Repo/Team)

Nach belegtem Rollout den lokalen Branch abschließen — die Grenze zwischen „fertig" und „lebt auf dem Default-Branch". Voll-Protokoll: `references/branch-finish.md`.
- **Disposition** wählen (lokal mergen / PR-MR / Archiv) — **NO-FAIL geht in Review**, kein stiller Merge auf den Default.
- **Delivery-Report = PR-Body** (keine Doppelung); **forge-agnostisch**: `git push` universal, PR-Erstellung je nach Forge (`gh`/`glab`/…), sonst dokumentiertes **manuelles Handoff** (Diff + Report ins Ticket). Kein Git → `N/A`.
- **Post-Merge-Retest** bei NO-FAIL/Risiko-Signal: auf dem **gemergten** Stand Spot-Check der kritischen Ledger-Stellen + Real-Stack-Smoke + Invarianten (fängt Integrations-only-Bugs). Entfällt nur bei konfliktfreiem Fast-Forward / reinem Read-only-Change.

> Faustregel: Lokales `/verify` auf dem Feature-Branch ist kein Beweis für den gemergten Default — bei NO-FAIL nach dem Merge einmal die kritischen Stufen wiederholen.

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
| „Live verifiziert" ohne Klick-Beweis | Boss findet 5 Bugs in 2 Min | E2E Klick-Through (P5.5) Pflicht, Screenshot je Stufe |
| UI-Text aus dem Modell halluziniert | Plan-Features die nicht existieren | Spec-Source-of-Truth (P1.8) — Quelle pro Stelle benennen |
| Multi-Repo-Übergang ohne eigene Coverage | Auth-Sync-Bruch zwischen Landing & App | Cross-Repo Journey-Map (P1.7) + Multi-Repo-Smoke (P5.8) |
| Dummy-/Placeholder-Code live ausgeliefert | Stripe-Phantom-Posten „0,80 €/Einheit" | WIP-Scan (Pre-flight Teil 2) + Replacement-Gate (P4.5) |
| `SMTP 250 OK` als Mail-Beweis | Welcome-Mail grüßt mit „domo!" | Visual Inspection in echtem Mail-Client (P5.7) |
| Cancel ohne Bestätigungs-Mail | DSGVO-Beleg-Lücke | Mail-Pflicht-Matrix (P2.6) erzwingt Counter-Mails |
| UI-Limit ohne Server-Enforcement | Free-Tier-Abuse | Adversarial Plan-Limit-Test (P5.6) — `limit+1` |
| Brand-Reste im White-Label-Fork | „Powered by Activepieces" auf Landing | Brand-Sweep (P2.7) gegen CLAUDE.md-Regeln |
| Brute-Force-Loop „bis er kein Bock mehr hat" | Token-Waste, kein Coverage-Wachstum | Loop-Diminishing-Returns-Stopp (3 Iter. ohne Neues → andere Methode) |
| Direkt auf `main`/`master` editiert | irreversibler Live-Edit ohne Draft-Zyklus | Branch-Safety-Gate (Pre-flight) — Arbeits-Branch oder Consent |
| `BLOCKIERT` mit `DONE_WITH_CONCERNS` verwechselt | Migration/Setup fehlt → Feature fälschlich geblockt (oder still geshippt) | Graded-Status (P6.2b): Code-Bug = BLOCKIERT, Ressourcen-/Entscheidungslücke = Concern/NEEDS_CONTEXT |
| Externes Review-Finding blind übernommen | Reviewer-Kontextlücke wird zu Folgekommit | Externes Review empfangen (`receiving-review.md`): klassifizieren, am Source validieren, mit Beleg zurückschieben |
| Hand-Holding statt Schleife | Agent fragt nach jedem Schritt „und jetzt?" | Loop-Engine: ASSESS leitet die nächste Arbeit selbst ab (`loop-engine.md` §3) |
| Loop ohne Checkpoint | Wake-up/Kompaktierung → Fortschritt verloren, fängt von vorn an | durabler Loop-Checkpoint, bei jeder Iteration geschrieben (Pre-flight Teil 0) |
| Selbst-vergebenes SHIP | Schleife sagt „fertig", weil der Prompt endet | DONE-Bedingung an DoD-Boxen gekoppelt, nicht an „Agent zufrieden" (`loop-engine.md` §4) |
| „immer maximale Automatik" | Cron-Routine + Worktree für einen Einzeiler | tiered Autonomie — inline ist der Default (`loop-engine.md` §1) |
| Writer prüft sich selbst | Agent schreibt sich selbst SHIP | frischer Reviewer-Subagent, Writer ≠ Reviewer (`loop-engine.md` §6) |
| Connector-Wert ungeprüft übernommen | falscher Spec-Wert aus alter Notion-Page live | Connector-Fund = benannte Quelle, trotzdem Zeichen-für-Zeichen-Diff (`loop-engine.md` §8) |

---

## REFERENZ-DATEIEN (bei Bedarf laden)

- **`references/loop-engine.md`** — Der Loop-Engineering-Antrieb, der den ganzen Skill zur autonomen Selbst-Prompting-Schleife macht: die fünf Bausteine (Automation/Worktrees/Skills/Connectors/Subagents) auf konkrete Claude-Code-Primitive abgebildet, das durable Checkpoint-Artefakt („weiß, wann es fertig war"), die Iterations-Mechanik (ASSESS→ACT→VERIFY→RECORD→DECIDE→CONTINUE), die DONE-Bedingung + Stop-Garantien, das Gesetz „immer loopen ≠ immer maximale Automatik" (tiered: inline → Wake-up → Cron → Worktree), die Writer-≠-Reviewer-Invariante, Connector-/Worktree-Operationalisierung, **das Quickstart-Runbook (§12: Loop in Schritt 1–7 tatsächlich starten — von inline bis „rund um die Uhr")**. **Laden bei jedem Aufruf (Pre-flight Teil 0) — das ist der Betriebs-Modus, nicht eine Phase.**
- **`references/blast-radius.md`** — Konkrete Recon-Rezepte: Symbol-Suche, Sub-Agent-Fan-out-Templates, der vollständige Cross-Layer-Kopplungs-Katalog, das Symmetrie-Paar-Katalog, die Coverage-Ledger-Vorlage. **Laden in Phase 1, immer bei nicht-trivialem Blast-Radius.**
- **`references/multi-agent.md`** — Multi-Agent-Orchestrierung & Anti-Halluzination: Agenten-Budget nach Risiko-Tier (wie viele wann), **Modell-Tier pro Agent (§1.6: günstig für Recon, stark für Verifikation)**, disjunkte Stream-Schnitte, **Subagent-Rekursions-Guard (§2b)**, Citation-or-void + Source-Abgleich + Konsens-Gate, kalte Zweit-Ableitung, Independent-Verifier-Prompt (Red-Team Ledger↔Diff). **Laden in Phase 1.5 bei Agenten-Fan-out und Phase 5.0 bei NO-FAIL.**
- **`references/staged-review.md`** — Zwei-Stufen-Implementierungs-Review durch frische Agenten: Spec-Compliance (under/over-built · misinterpret · unsourced) ZUERST, dann Code-Quality (Duplizierung · Fehlerbehandlung · Idiom-Bruch · toter Pfad · Lesbarkeit), mit Prompt-Vorlagen, Risiko-Gate und Fix-Re-Check-Schleife. Eigene Linse **neben** dem Ledger↔Diff-Kreuzaudit (Coverage). Inkl. Severity-Kalibrierung (Critical/Important/Minor) + SHA-Anker (`BASE_SHA..HEAD_SHA`) für reproduzierbare Reviews. **Laden in Phase 5.0b ab Risiko-Signal, Pflicht bei NO-FAIL.**
- **`references/systematic-debugging.md`** — Root-Cause-First-Debug-Protokoll (4 Phasen: Investigation → Pattern-Analyse → Hypothese/Test → Fix), Red-Flag-Liste, „nach 3 Fehlversuchen Architektur hinterfragen" + konkrete Taktiken (Condition-based Waiting, Test-Env-Guard für destruktive Ops, Defense-in-Depth-Schichten, Test-Pollution-Bisection, Architektur-Erkennungsmuster). Greift wann immer etwas **bricht statt fehlt** (Test rot · `/verify` falsch · Invarianten-Verletzung · Auto-Fix-Thrashing). **Laden in Phase 4/5 ab dem ersten erfolglosen Fix.**
- **`references/receiving-review.md`** — Externes Review **empfangen** (Gegenstück zu staged-review, das Review *gibt*): Feedback von Mensch/Tool/Auditor klassifizieren (Real/kontext-blind/halluziniert/unklar), am Source validieren, begründeter Pushback mit Code-/Test-Beleg, Eskalation bei Konflikt mit Vorentscheidung, echte Bugs ins E-Ledger. **Laden in Phase 5, wenn externes Feedback ankommt.**
- **`references/modeling.md`** — State-Table-Templates, Invarianten-Katalog, Falsy-Entscheidungsmatrix, Contract-/Idempotenz-/Nebenläufigkeits-Checklisten. **Laden in Phase 2 bei State-/Async-/Daten-Änderungen.**
- **`references/security-pass.md`** — Der Security-Engineer-Schnelldurchgang (Authz/IDOR, Injection-Klassen, Secrets, Open-Redirect/SSRF, Falsy-as-Bypass) + Eskalations-Regel wann die NO-FAIL-`zero-fail-zones.md` zu ziehen ist. **Laden in Phase 2.5, Pflicht bei NO-FAIL.**
- **`references/verification.md`** — Test-Tier-Entscheidungsbaum, jsdom-Fallen-Katalog, Orchestrierung von `/feature-testing` + `/verify` (inkl. `AN /verify`-Handoff), Real-Stack-Smoke-Rezept (Clean-Bring-up), manueller Fallback. **Laden in Phase 3 & 5.**
- **`references/security-hardening.md`** — Enterprise-Härtung gegen die komplette Angriffs-Taxonomie (OWASP + API Security Top 10), AuthN/AuthZ/Session, **Paywall-/Abuse-Resistenz** (VPN/IP/Geo, Coupon-/Trial-Abuse, Webhook-Integrität), Supply-Chain, Header/DoS/Daten. **Laden in P2.5 & P5; Pflicht bei NO-FAIL und bei Payment/Zugang.**
- **`references/threat-intel.md`** — Protokoll des täglichen Threat-Intel-Refresh: Stamp-Mechanismus (1×/Tag pro Projekt), Stack-Erkennung, Such-Quellen (CVE/GHSA/OWASP), Exposure-Check & Eskalation. **Laden in der Pre-flight.**
- **`references/rollout.md`** — Nach-SHIP-Hälfte: Expand-Contract-Rückwärtskompatibilität (nullable-first, dual-write, Feld-/Enum-/Queue-Migration), phasenweiser Rollout + Feature-Flag + Kill-Switch ohne Redeploy, Rollback-Plan (`migration down` getestet, Daten forward-kompatibel), Post-Ship-Observability (Log/Metrik/Alert/Invarianten-Monitor), Zero-Customer-Impact-Sequenzierung. **Laden in Phase 3.4 (Strategie) & Phase 7 (Ausführung) bei Prod-Changes mit aktiven Kunden.**
- **`references/branch-finish.md`** — Branch-Abschluss nach SHIP/Rollout: Disposition (lokal mergen vs. PR/MR vs. Archiv), Delivery-Report als PR-Body, **forge-agnostischer** Handoff (git push universal, PR-Erstellung je Forge, sonst manuelles Handoff), Post-Merge-Retest (Spot-Check kritischer Ledger-Stellen + Real-Stack-Smoke + Invarianten). **Laden in Phase 7.1 nach belegtem Rollout.**
- **`references/e2e-clickthrough.md`** — Voll-Protokoll für End-to-End User-Klick-Through: das 10-Stage-Skript, Browser-Agent-Patterns (Playwright/agent-browser/MCP-Chrome), Mailbox-Strategien (Mailtrap/Mailpit/Gmail), Stripe-Test-Karten-Katalog, Screenshot-Disziplin, BLOCKIERT-Bedingungen je Stufe. **Laden in Phase 5.5; Pflicht bei jeder User-Journey-Änderung.**
- **`references/multi-repo-journey.md`** — Cross-Repo-Onboarding/Cross-Service-State-Übergänge: Journey-Tabellen-Template, Webhook-Idempotenz-Checks, Auth-Hash-Identitäts-Beweis, Eventual-Consistency-Marker. **Laden in Phase 1.7 & 5.8.**
- **`references/wip-scanner.md`** — Dummy/Placeholder/Mock-Detection: vollständige Grep-Patterns, Entscheidungs-Matrix pro Treffer, Ersetzungs-Patterns für typische WIP-Klassen (Stripe-Test-Pläne, Dummy-Mailadressen, Lorem-Ipsum-Marketing-Text). **Laden in Pre-flight Teil 2 & Phase 4.5.**
- **`references/spec-source-of-truth.md`** — Verfahren zum Abgleich von UI-Texten/Preisen/Limits gegen Notion-Pages, Spec-Files, CMS-Einträge, Stripe-Dashboards. **Laden in Phase 1.8.**
- **`references/brand-audit.md`** — White-Label-Brand-Sweep: Verbots-Wort-Listen je Fork-Quelle, Asset-Audit-Patterns, Mail-Footer-Audit. **Laden in Phase 2.7.**
- **`references/mail-symmetry.md`** — Vollständige Pflicht-Matrix für transaktionale Mails (Signup/Verify/Welcome/Cancel/Refund/PasswordReset/Erasure), DSGVO-Pflichten, Anrede-Fallback-Patterns. **Laden in Phase 2.6.**
