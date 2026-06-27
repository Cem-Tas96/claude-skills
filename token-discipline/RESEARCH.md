# Token-Discipline — Research & Faktenlage

> Stand: 2026-06-28. Zweck: die Faktenbasis für `PLAN.md`. Keine Secrets. Noch nicht committet — erst nach Cems Review.

---

## 1. Die Kernfrage: `ultracode` vs. `/effort`

**Antwort: `ultracode` IST die höchste `/effort`-Stufe — kein separates Konzept.**

Stufen-Reihenfolge (aufsteigend):

```
low  →  medium  →  high  →  xhigh  →  max  →  ultracode
```

| Stufe | Was sie tut | Multi-Agent-Fan-out? | Als Default persistierbar? |
|---|---|---|---|
| `low`–`high` | wenig bis mittel Thinking-Budget pro Turn | nein | ja |
| `xhigh` | hohes Thinking-Budget pro Turn | nein | **ja** (höchste persistierbare Stufe) |
| `max` | maximales Thinking-Budget pro Turn | nein | session-only |
| `ultracode` | `xhigh`-Thinking **+ automatische Workflow-Orchestrierung** | **JA — der Treiber** | session-only |

**Das ist der ganze Burn-Mechanismus:** `ultracode` weist den Agenten an, „für jede substanzielle Aufgabe einen Workflow zu bauen" und „token cost is not a constraint" — das fächert 50–100 Subagenten pro Aufgabe. Genau das ist im letzten Chat passiert (49 + 96 Subagenten ≈ 5,2 Mio Tokens).

> **Zwei orthogonale Dinge, die oft verwechselt werden:**
> - **Thinking-Effort** (`low…max`) = wie viel denkt das Modell pro Turn. Linearer, moderater Kostenfaktor.
> - **`ultracode`** = schaltet zusätzlich die Multi-Agenten-Maschinerie scharf. Exponentieller Kostenfaktor.
>
> Man will hohes *Thinking* (Qualität) ohne die *Agenten-Explosion*. Das ist exakt `xhigh`.

**Empfehlung Default-Effort:** **`xhigh`**, nicht `max`, nicht `ultracode`.
- `xhigh` ist die höchste *persistierbare* Stufe → überlebt Sessions/Geräte.
- Delta `xhigh → max` ist klein (nur mehr Thinking-Token pro Turn), kostet aber jeden Turn extra. Für die seltene wirklich harte Architektur-Frage `max` ad-hoc in der Session setzen.
- `ultracode` bleibt **rein opt-in** — nur wenn du es explizit tippst.

> ⚠️ Der genaue settings.json-Schlüssel für einen persistenten Effort-Default (`effortLevel`?) ist in der Ausführungsphase zu verifizieren, bevor wir ihn schreiben — die Doku-Aussage dazu war nicht 100 % sicher.

---

## 2. Was bereits existiert (und gut ist) — NICHT neu bauen

Die risiko-proportionale Spar-Logik ist schon implementiert:

| Ort | Was er kann |
|---|---|
| `feature-delivery/references/multi-agent.md` §1 | **Agenten-Zahl nach Tier**: BEST-EFFORT/trivial = **0 Agenten** (direktes grep); LOW-FAIL = Streams A–G; NO-FAIL = voll + kalte Zweit-Ableitung + Verifier |
| `multi-agent.md` §1.6 | **Modell-Tier pro Agent**: Recon → günstig (Haiku); Verifier/Synthese → stark (Opus); Code-Quality → mittel. „Warum nicht stärkstes Modell für alles? Token-Waste." |
| `multi-agent.md` §3–§4 | Anti-Halluzinations-Gate (Citation-or-void, Source-Read, Konsens) + Writer≠Reviewer Kreuzaudit — **das ist der Qualitäts-Boden** |
| `feature-delivery` SKILL P3 | Tier-Floor-Gate (deterministisch), STOP-1 Diminishing-Returns (3× kein Wachstum → STOPP, **kein** Modell-Upgrade, **keine** höhere Kopfzahl) |
| `feature-testing` SKILL §1.2 | Risiko-Tiers (NO-FAIL/LOW-FAIL/BEST-EFFORT) mit proportionaler Testtiefe |
| `gameboy-gate` | fast reines deterministisches Bash — spawnt kaum Agenten; der Burn kam vom ultracode-Wrapper, nicht vom Skill |

**Schlussfolgerung:** Wir erfinden kein neues System. Wir machen das vorhandene **(a) global & immer-an**, **(b) ultracode-resistent**, **(c) auf alle Geräte verteilt**, **(d) tatsächlich in die Agent-Calls verdrahtet**.

---

## 3. Cross-Device / Cross-Project — die Infrastruktur existiert schon

- `~/.claude/skills/` ist ein Git-Repo, das per **SessionStart-Hook** (`git pull`) auf **jedem Gerät** automatisch synct und in **jedem Projekt** geladen wird (Skills sind global).
- `install.ps1` / `install.sh` patchen **idempotent**:
  - `~/.claude/settings.json` (SessionStart-Hook) — **hier können wir Default-Model + Default-Effort setzen**
  - `~/.claude/CLAUDE.md` (Block mit Marker `<!-- claude-skills-sync:do-not-remove -->`) — **hier kommt die Always-On-Triage rein**

> **Das ist der „einmal, überall"-Hebel:** Was wir in den Installer + die CLAUDE.md-Block-Logik schreiben, landet beim nächsten `skills updaten` automatisch auf allen Geräten und gilt in allen Projekten. Kein Per-Projekt-Erklären nötig.

---

## 4. Fertige Netz-Lösung? — `claude-code-router` evaluiert → für dich NICHT geeignet

`claude-code-router` (musistudio) ist die bekannteste „Model-Routing"-Lösung: ein Proxy zwischen Claude Code und der API, der Requests regelbasiert auf günstigere/andere Modelle (DeepSeek, OpenRouter, …) routet.

**Warum es für dich nicht passt:**
- Es braucht **Provider-API-Keys** und rechnet **pro Token gegen externe APIs ab** — es **umgeht das Max-Abo**.
- Dein Engpass ist nicht Pro-Token-Geld, sondern das **Max-5h-Token-Kontingent**. Ein externer Proxy spart dieses Kontingent nicht — er verlagert Kosten auf eine zusätzliche, kostenpflichtige Schiene und bringt Proxy-Infra + Risiko (ein weiterer Prozess, Auth-Forwarding, Bruch bei Claude-Code-Updates).
- Fremde Modelle hinter dem Proxy ≠ „gleiche Code-Qualität" — genau das willst du nicht.

**Verdikt:** Native Hebel nutzen (Default-Model, Default-Effort, Subagent-Modell-Tiering, Skill-Tiering) — alles bleibt auf dem Abo, gleiche Modell-Familie, kein Infra-Risiko. `claude-code-router` nur relevant, falls du je auf API-Billing wechselst.

---

## 5. Was Tokens gegen das Max-Kontingent spart (Wirkhebel, nach Impact)

1. **`ultracode` weglassen** (Default `xhigh`) — verhindert die 50–100-Agenten-Fächer. Größter Hebel.
2. **Default-Model Sonnet 4.6** statt Opus — Sonnet/Haiku zählen deutlich leichter gegen das Kontingent; Opus nur für harte Architektur. (Deckt sich mit Memory `feedback_token_efficiency`.)
3. **Recon-Subagenten auf Haiku** verdrahten (multi-agent.md §1.6 sagt es, die Calls müssen es auch tun).
4. **Always-On-Triage**: pro Prompt zuerst Tier + Modell autonom festlegen → keine Über-Eskalation bei Trivia.
5. **Frische Chats pro Thema** (`/clear`) — hält Context (= Pro-Runde-Kosten) klein. Verhaltens-Hinweis, kein Code.

> **Qualität bleibt gleich, weil gespart wird an Kopfzahl + Recon-Modell — NICHT an den Verifikations-Gates.** Anti-Halluzinations-Gate, Source-Read und Writer≠Reviewer bleiben unangetastet. Mehr Agenten kaufen *Recall*, nicht *Präzision* (multi-agent.md §0); Präzision kommt aus Verifikation, und die ist billig.
