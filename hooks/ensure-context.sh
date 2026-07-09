#!/bin/sh
# ============================================================================
# Global-Rules context injector  —  Cem-Tas96/claude-skills
# ----------------------------------------------------------------------------
# Stellt sicher, dass die globalen Always-On-Regeln in ~/.claude/CLAUDE.md
# stehen — damit sie in JEDEM Repo, in JEDER Session, auf JEDEM Geraet gelten,
# ohne dass jemand Claude daran erinnern muss. Drei Bloecke, je Marker-guarded:
#   1. Claude Skills sync           <!-- claude-skills-sync:do-not-remove -->
#   2. Secrets — niemals committen  <!-- secrets-guard:do-not-remove -->
#   3. Token-Discipline / Triage    <!-- token-discipline:do-not-remove -->
#
# Idempotent (pro Block einzeln, Marker-basiert). FAIL-SAFE: bricht den
# Session-Start nie ab. Aufruf: SessionStart-Hook (settings.json) + Installer.
#
# WICHTIG: Dieses Repo ist PUBLIC. Hier stehen nur GENERISCHE Regel-Texte —
# KEINE internen Incident-Details, Kunden- oder Projektnamen. Die ausfuehrliche
# lokale Fassung (mit Anekdoten) lebt ausschliesslich in ~/.claude/CLAUDE.md.
# Detail-Regeln: skills/token-discipline/token-router.md
# ============================================================================
set -u
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

# Datei anlegen falls sie fehlt (frisches Geraet)
[ -f "$CLAUDE_MD" ] || : > "$CLAUDE_MD" 2>/dev/null || exit 0

# --- 1) Claude Skills sync -------------------------------------------------
if ! grep -qF "<!-- claude-skills-sync:do-not-remove -->" "$CLAUDE_MD" 2>/dev/null; then
cat >> "$CLAUDE_MD" <<'EOF'

## Claude Skills sync — Cem-Tas96/claude-skills

<!-- claude-skills-sync:do-not-remove -->
`~/.claude/skills/` ist ein Git-Repo (https://github.com/Cem-Tas96/claude-skills, **public, read-only für Fremde**). Skills syncen automatisch via SessionStart-Hook.

**Natural-language Trigger** (wenn Cem das sagt, sofort ausführen — keine Rückfrage):

- "skills updaten" / "skills installieren" / "neuesten skill holen" / "<skill-name> installieren"
  → `git -C ~/.claude/skills pull --rebase --autostash`
  → Dann dem User sagen: "Restart Claude Code (`/exit` und neu starten), damit die Skill-Definitionen neu geladen werden."

- "skill <name> erstellen" / "neuen skill anlegen <name>"
  → Neuen Ordner `~/.claude/skills/<name>/` mit `SKILL.md` (YAML-Frontmatter + Inhalt) anlegen, dann committen+pushen aus `~/.claude/skills/`.

**Auf neuem Gerät einrichten (Installer installiert git automatisch falls fehlend):**
- Windows PowerShell: `irm https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.ps1 | iex`
- macOS/Linux/Git-Bash: `curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.sh | bash`
EOF
fi

# --- 2) Secrets — niemals committen ---------------------------------------
if ! grep -qF "<!-- secrets-guard:do-not-remove -->" "$CLAUDE_MD" 2>/dev/null; then
cat >> "$CLAUDE_MD" <<'EOF'

## Secrets / sensible Daten — NIEMALS committen (HARTE Regel, gilt für ALLE Projekte)

<!-- secrets-guard:do-not-remove -->
**Feste, projektübergreifende Regel — keine Ausnahme, egal wie eilig:** Sensible Daten, wie man sie typischerweise in einer `.env`-Datei findet, werden **niemals committet**. Dazu zählen u. a. API-Keys, Tokens, Passwörter, DB-Credentials, SMTP-/Mail-Keys, Stripe-Keys, OAuth-Client-Secrets, Webhook-Secrets, private Schlüssel.

- **Erlaubt:** Für **lokale** (Integrations-)Tests dürfen die echten Werte aus der `.env` genutzt werden.
- **Pflicht:** Spätestens beim Committen IMMER aktiv prüfen, dass keine echten Secrets reingehen — lieber nachfragen / stoppen als committen.

**Vor jedem `git add` / `commit` konkret:**
- `git status` + `git diff --cached` checken; bei Secret-Verdacht **stoppen** und entfernen (`git restore --staged` / `git rm --cached`).
- Nicht nur an `.env` denken — Secrets leaken oft über **versteckte Vektoren**: eingecheckte DBs (H2/SQLite), Realm-/Config-Exports, Fixtures, Logs, generierte Dateien, Lock-Files.
- Sicherstellen, dass `.env` und secret-tragende Artefakte in `.gitignore` stehen.

**Warum so streng:** Ein einmal committeter Secret gilt als kompromittiert. Geleakte Keys werden von Scannern (z. B. GitHub ↔ SendGrid/Twilio) **automatisch revoked** → Produktionsausfall.
EOF
fi

# --- 3) Token-Discipline / Triage -----------------------------------------
if ! grep -qF "<!-- token-discipline:do-not-remove -->" "$CLAUDE_MD" 2>/dev/null; then
cat >> "$CLAUDE_MD" <<'EOF'

## Token-Discipline — autonome Triage bei JEDEM Prompt

<!-- token-discipline:do-not-remove -->
Vor jeder substanziellen Antwort zuerst still einschaetzen ("Triage"). Volldetail: `~/.claude/skills/token-discipline/token-router.md`.

- **T0 Trivial** (Frage/Lookup/Mini-Edit/Status) → 0 Subagenten, inline.
- **T1 Standard** (Fix/Feature, schmaler Blast-Radius) → inline; Faecher nur wenn Blast-Radius real breit.
- **T2 Komplex/NO-FAIL** (Auth/Payment/Rollen/PII/Migration/cross-layer/multi-repo) → risiko-proportionaler Faecher; Subagenten-Modelle: Recon=Haiku (explizit), Impl=Sonnet (explizit), Verifier/Synthese=**Top-Tier per Vererbung** (KEIN model-Parameter → erbt Hauptmodell; aktuell Fable 5, Fallback Opus).
- **T3** = NUR wenn der User explizit eskaliert (tippt `ultracode` / "nutze einen Workflow" / "sei erschoepfend").

Regeln:
- **`ultracode`/Workflows sind opt-in.** NIE automatisch einen Workflow oder 10+-Agenten-Faecher fuer T0/T1 starten. Auch in einer ultracode-Session: kein Workflow fuer triviale Arbeit.
- **Hauptmodell bleibt wie gewaehlt (Default: staerkstes verfuegbares Modell, aktuell Fable 5).** Gespart wird ueber Subagenten-Modelle (Haiku-Recon) und wenige Agenten — nicht ueber das Hauptmodell. Effort-Default `xhigh` (nicht `max`/`ultracode`).
- **Zukunftssicherheit:** Top-Tier NIE per Namen pinnen — Verifier/Synthese erben das Hauptmodell (model-Parameter weglassen); neues Top-Modell zieht automatisch mit. Top-Tier NIE fuer Recon/Scans/Impl-Helfer (Anti-Waste).
- **Qualitaets-Boden nie kuerzen:** Anti-Halluzination (Citation + Source-Read), Writer≠Reviewer, STOP bei 3x kein Wachstum. Mehr Agenten kaufen Recall, nicht Praezision.
- **Transparenz:** bei T2/T3 eine Zeile vorab — `Triage: <Tier> · <n> Recon (Haiku) · Verifier (Top-Tier/erbt Hauptmodell) · Grund: …`.
EOF
fi

exit 0
