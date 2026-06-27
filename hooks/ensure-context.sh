#!/bin/sh
# ============================================================================
# Token-Discipline context injector  —  Cem-Tas96/claude-skills
# ----------------------------------------------------------------------------
# Stellt sicher, dass der Always-On-Triage-Block in ~/.claude/CLAUDE.md steht,
# damit Claude bei JEDEM Prompt (in jedem Repo, auf jedem Geraet) zuerst
# risiko-proportional einschaetzt, wie viele Agenten + welches Modell noetig
# sind — statt per ultracode 50-100 Agenten zu faechern.
#
# Idempotent (Marker-basiert). FAIL-SAFE: bricht den Session-Start nie ab.
# Wird vom SessionStart-Hook aufgerufen (zweiter Eintrag, neben dem git-pull)
# und einmalig vom Installer. Detail-Regeln: skills/token-discipline/token-router.md
# ============================================================================
set -u
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
MARKER="<!-- token-discipline:do-not-remove -->"

# Datei anlegen falls sie fehlt (frisches Geraet)
[ -f "$CLAUDE_MD" ] || : > "$CLAUDE_MD" 2>/dev/null || exit 0

# Schon vorhanden -> nichts tun
if grep -qF "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
  exit 0
fi

cat >> "$CLAUDE_MD" <<'EOF'

## Token-Discipline — autonome Triage bei JEDEM Prompt

<!-- token-discipline:do-not-remove -->
Vor jeder substanziellen Antwort zuerst still einschaetzen ("Triage"). Volldetail: `~/.claude/skills/token-discipline/token-router.md`.

- **T0 Trivial** (Frage/Lookup/Mini-Edit/Status) → 0 Subagenten, inline.
- **T1 Standard** (Fix/Feature, schmaler Blast-Radius) → inline; Faecher nur wenn Blast-Radius real breit.
- **T2 Komplex/NO-FAIL** (Auth/Payment/Rollen/PII/Migration/cross-layer/multi-repo) → risiko-proportionaler Faecher; Subagenten-Modelle: Recon=Haiku, Impl=Sonnet, Verifier/Synthese=Opus.
- **T3** = NUR wenn der User explizit eskaliert (tippt `ultracode` / "nutze einen Workflow" / "sei erschoepfend").

Regeln:
- **`ultracode`/Workflows sind opt-in.** NIE automatisch einen Workflow oder 10+-Agenten-Faecher fuer T0/T1 starten. Auch in einer ultracode-Session: kein Workflow fuer triviale Arbeit.
- **Hauptmodell bleibt wie gewaehlt (Default Opus).** Gespart wird ueber Subagenten-Modelle (Haiku-Recon) und wenige Agenten — nicht ueber das Hauptmodell. Effort-Default `xhigh` (nicht `max`/`ultracode`).
- **Qualitaets-Boden nie kuerzen:** Anti-Halluzination (Citation + Source-Read), Writer≠Reviewer, STOP bei 3x kein Wachstum. Mehr Agenten kaufen Recall, nicht Praezision.
- **Transparenz:** bei T2/T3 eine Zeile vorab — `Triage: <Tier> · <n> Recon (Haiku) · Verifier (Opus) · Grund: …`.
EOF

exit 0
