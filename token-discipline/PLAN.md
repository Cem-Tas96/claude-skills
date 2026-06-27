# Token-Discipline — Implementierungsplan (IT-Architekt-Sicht)

> Stand: 2026-06-28. Status: **UMGESETZT** (Phase 1–6 ausgeführt; auf diesem Gerät aktiv).
> Grundlage: `RESEARCH.md` (gleicher Ordner). Finalisierte Always-On-Regel: `token-router.md` (Draft entfernt).
>
> **Entscheidungslog (vom User bestätigt):** (1) Effort-Default `xhigh` — war bereits in settings.json gesetzt. (2) **Default-Model = Opus behalten**; Spar-Hebel sind Subagenten-Modelle + wenige Agenten, nicht das Hauptmodell. (3) Scope = **global** (CLAUDE.md + Skills-Repo, alle Geräte, alle Repos). (4) Transparenz-Zeile ab **T2**. (5) Plan-Dokus **mitcommitten** als Design-Doc.

---

## 0. Zielbild (eine Seite)

> **„Bei jedem Prompt schätzt Claude autonom zuerst ein: wie komplex ist das, wie viele Agenten brauche ich wirklich, welches Modell pro Rolle — und liefert gleiche Qualität bei minimalen Tokens. Einmal eingerichtet, gilt es auf allen Geräten und in allen Projekten."**

Erreicht durch **vier Bausteine**, die zusammenwirken:

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. ALWAYS-ON-TRIAGE  (~/.claude/CLAUDE.md, via Installer auf alle     │
│    Geräte)  → gilt für JEDEN Prompt, auch ohne Skill                  │
│    "Tier 0/1/2/3 bestimmen → Agentenzahl + Modell pro Rolle wählen"   │
├─────────────────────────────────────────────────────────────────────┤
│ 2. ULTRACODE-GOVERNANCE  → Default-Effort xhigh, Default-Model Sonnet │
│    (settings.json via Installer). ultracode = strikt opt-in.          │
├─────────────────────────────────────────────────────────────────────┤
│ 3. SKILL-HÄRTUNG  → die vorhandene Tier-Logik gegen ultracode-Override│
│    schützen + Recon-Agenten real auf Haiku verdrahten                 │
├─────────────────────────────────────────────────────────────────────┤
│ 4. SINGLE SOURCE OF TRUTH  → token-discipline/token-router.md, auf das│
│    CLAUDE.md + alle drei Skills verweisen (DRY, kein Duplikat-Drift)  │
└─────────────────────────────────────────────────────────────────────┘
```

**Leitprinzip:** Wir bauen **kein neues System** — die risiko-proportionale Logik existiert bereits (`RESEARCH.md` §2). Wir machen sie **global, immer-an, ultracode-resistent und auf alle Geräte verteilt**. Das ist die token-sparsame, risikoarme Variante (kleine, gezielte Edits statt Neubau).

---

## 1. Die Triage-Tiers (das Herzstück — Detail in `token-router.draft.md`)

| Tier | Wann | Subagenten | Modell | Workflow? |
|---|---|---|---|---|
| **T0 — Trivial / Konversation** | Einzelfrage, Mini-Edit, Lookup, Statusabfrage | **0**, inline | Haiku/Sonnet | nie |
| **T1 — Standard** | Feature/Fix/Refactor in bekanntem Bereich, schmaler Blast-Radius | **0–wenige** (nur wenn Blast-Radius breit) | Sonnet (Opus nur für echt harte Logik) | nein |
| **T2 — Komplex / NO-FAIL** | Auth/Payment/Rollen/PII/Migration, cross-layer, multi-repo, breiter Blast-Radius | risiko-proportionaler Fächer **per multi-agent.md §1** | Recon=Haiku, Verifier/Synthese=Opus, Impl=Sonnet | nur wenn nötig |
| **T3 — Explizite Eskalation** | Du tippst `ultracode` / „nutze einen Workflow" / „sei erschöpfend" | voller Multi-Agent-Fächer | wie T2, mehr Köpfe | ja |

**Nicht verhandelbar (gilt in allen Tiers):** Anti-Halluzinations-Gate, Source-Read jeder gemeldeten `file:line`, Writer≠Reviewer. **Gespart wird an Kopfzahl + Recon-Modell, nie an Verifikation.**

**Transparenz:** Bei T2/T3 (und optional T1) gibt Claude **eine Zeile** aus: `Triage: T2 · 4 Recon-Agenten (Haiku) · Verifier (Opus) · Grund: Payment+Auth cross-repo`. So kannst du sofort hoch-/runterkorrigieren.

---

## 2. Architektur-Entscheidungen (mit Begründung)

| # | Entscheidung | Warum |
|---|---|---|
| A1 | Always-On-Triage gehört in **CLAUDE.md**, nicht in einen Skill | Skills sind opt-in (laden nur bei Invocation). Die Triage muss bei **jedem** Prompt laufen → nur CLAUDE.md ist immer geladen. |
| A2 | Detail-Rubrik als **Referenz-Datei** im Skills-Repo, CLAUDE.md hält nur einen **kompakten** Block + Verweis | CLAUDE.md kurz halten (lädt jeden Turn = Kosten). Tiefe lebt in `token-router.md`, das bei T2/T3 nachgeladen wird. |
| A3 | Verteilung über den **bestehenden Installer** (settings.json + CLAUDE.md-Block, idempotent mit Marker) | „Einmal, überall" ist schon gelöst — wir hängen uns an die vorhandene Mechanik. |
| A4 | **Native** Hebel statt `claude-code-router` | Max-Abo, gleiche Modellfamilie, kein Proxy-Risiko (`RESEARCH.md` §4). |
| A5 | Default-Model **Sonnet 4.6**, Default-Effort **xhigh** | Spart Kontingent, behält Qualität; Opus/max/ultracode bewusst ad-hoc. |
| A6 | Verifikations-Gates **unangetastet** | Qualität & Anti-Halluzination dürfen nicht Teil der Sparmaßnahme sein. |

---

## 3. Phasen-Plan (so führe ich es nach deiner Freigabe aus)

> Jede Phase = ein kleiner, in sich abgeschlossener Edit + Verifikation. Reihenfolge so, dass jederzeit ein konsistenter Zustand vorliegt.

### Phase 1 — Single Source of Truth anlegen
- **Datei:** `token-discipline/token-router.md` (aus `token-router.draft.md` finalisiert).
- Inhalt: die vollständige Triage-Rubrik (Tiers, Modell-pro-Rolle, „nie an Verifikation sparen", STOP-bei-kein-Wachstum, Transparenz-Zeile).
- **Akzeptanz:** Datei existiert, deckt T0–T3 + Modell-Matrix + Eskalations-Trigger ab.

### Phase 2 — Always-On-Block für CLAUDE.md
- **Was:** kompakter Block (≈25–35 Zeilen) mit eigenem Marker `<!-- token-discipline:do-not-remove -->`, der (a) die 4 Tiers in Kurzform nennt, (b) Default Sonnet/xhigh, ultracode=opt-in festschreibt, (c) auf `token-router.md` für Details verweist, (d) die Transparenz-Zeile fordert.
- **Wo:** wird vom Installer in `~/.claude/CLAUDE.md` eingefügt (wie der bestehende skills-sync-Block).
- **Akzeptanz:** Block idempotent (zweiter Lauf dupliziert nicht); Wortlaut von dir abgenommen.

### Phase 3 — Installer erweitern (`install.ps1` + `install.sh`)
- **3a settings.json:** Default-Model + Default-Effort idempotent setzen — **nur wenn noch nicht vom User gesetzt** (kein Überschreiben einer bewussten Wahl). Exakten Effort-Schlüssel vorher verifizieren (`RESEARCH.md` §1 Warnung).
- **3b CLAUDE.md:** den Token-Discipline-Block (Phase 2) idempotent anhängen, analog zum bestehenden Marker-Mechanismus.
- **Akzeptanz:** beide Skripte idempotent; Trockenlauf auf diesem Gerät zeigt korrektes settings.json + CLAUDE.md; bestehende User-Settings bleiben respektiert.

### Phase 4 — Skill-Härtung gegen ultracode-Override
- **feature-delivery / feature-testing / gameboy-gate:** je eine knappe „Lean-Default / Präzedenz"-Notiz:
  - „Ohne **explizite** Eskalation (User tippt `ultracode`/„Workflow"/„erschöpfend") gilt der Lean-Default aus `token-router.md`: minimale Kopfzahl, Recon=Haiku. `ultracode` darf die Tier-Logik **nicht** still auf Maximum ziehen."
  - feature-delivery hat schon §1.3b (Instruktions-Präzedenz) — dort einhängen, nicht doppeln.
- **Akzeptanz:** jeder Skill verweist auf die SSoT; kein Logik-Duplikat; bestehende Tier-Tabellen bleiben die Quelle.

### Phase 5 — Recon-Modell real verdrahten
- In `multi-agent.md` (und den Fan-out-Prompt-Vorlagen) sicherstellen, dass die tatsächlichen `Agent`/`Explore`-Calls für Recon **`model: haiku`** mitgeben (heute beschreibt §1.6 es, die Call-Beispiele setzen es nicht überall).
- **Akzeptanz:** Recon-Fan-out-Vorlage enthält explizit das günstige Modell; Verifier-Vorlage explizit Opus.

### Phase 6 — Verifikation & Rollout
- **Lokaler Beweis:** einen trivialen + einen komplexen Test-Prompt mental/real durch die Triage laufen lassen → korrekte Tier-/Modell-Wahl, Transparenz-Zeile erscheint.
- **Idempotenz-Beweis:** Installer zweimal laufen lassen → keine Duplikate.
- **Commit + Push** aus `~/.claude/skills/` (ein fokussierter Commit pro Phase oder gebündelt, deine Wahl).
- **Verteilung:** auf einem zweiten Gerät `skills updaten` → Block + Settings landen automatisch.
- **Memory-Update:** `feedback_token_efficiency` ergänzen (Default-Effort xhigh dokumentieren).

---

## 4. Risiken & Gegenmaßnahmen

| Risiko | Gegenmaßnahme |
|---|---|
| Triage **unterschätzt** eine kritische Aufgabe (zu wenig Agenten → Bug rutscht durch) | NO-FAIL-Domänen (Auth/Payment/Rollen/PII/Migration) heben **automatisch** auf T2 — wie heute in den Skills. Verifikations-Gates bleiben. Im Zweifel eskaliert die Triage nach oben, nicht nach unten. |
| Installer **überschreibt** bewusste User-Settings | Nur setzen, wenn Schlüssel fehlt; vorhandene Werte nie überschreiben (wie der bestehende hooksPath-Check). |
| CLAUDE.md wird **zu lang** (Pro-Turn-Kosten) | Block kompakt halten; Tiefe in nachladbarer Referenz. |
| Falscher settings.json-Effort-Schlüssel | In der Ausführung verifizieren, bevor geschrieben wird (`RESEARCH.md` §1). Fallback: Doku-Hinweis „`/effort xhigh` einmal setzen + als Default speichern". |
| Doku-Drift (CLAUDE.md ≠ Skills) | Single Source of Truth (`token-router.md`); alle verweisen darauf statt zu kopieren. |

---

## 5. Was geliefert wurde (Ist-Stand)

| Artefakt | Zweck |
|---|---|
| `token-discipline/token-router.md` | Single Source of Truth: Triage-Tiers + Modell-pro-Rolle + Qualitäts-Boden |
| `hooks/ensure-context.sh` | schreibt den kompakten Triage-Block idempotent in `~/.claude/CLAUDE.md` (self-healing) |
| `install.sh` / `install.ps1` §2b | setzt Effort-Default `xhigh` (nur wenn ungesetzt) + verdrahtet den Context-Hook als 2. SessionStart-Eintrag (git-pull bleibt unangetastet) |
| `feature-delivery/references/multi-agent.md` | ULTRACODE-GUARD (§1) + konkrete Haiku/Opus-Verdrahtung der Agent-Calls (§1.6) |
| `feature-delivery/SKILL.md` §1.3b · `feature-testing/SKILL.md` §1.2 · `gameboy-gate/SKILL.md` | je ein Lean-Default-/ultracode-Guard-Hinweis mit Verweis auf die SSoT |

**Auf anderen Geräten aktivieren (Mac + Windows):** einmal die Installer-Zeile aus `RESEARCH.md` §3 ausführen — danach läuft der self-healing Hook bei jedem Session-Start automatisch, ohne weiteres Zutun. Settings.json-Änderungen (Hook + Effort) lassen sich nicht remote auf ein Gerät schieben, das den Installer nie ausführt — der einmalige Lauf pro Gerät ist unvermeidbar, danach ist es selbsttragend.
