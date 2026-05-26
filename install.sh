#!/usr/bin/env bash
# Claude Code skills installer / updater for macOS, Linux, and Windows-Git-Bash.
# One-liner: curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.sh | bash
set -euo pipefail

REPO_URL="https://github.com/Cem-Tas96/claude-skills.git"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS="$HOME/.claude/settings.json"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

say() { printf '\033[36m→\033[0m %s\n' "$*"; }
ok()  { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*" >&2; }

# 1. Clone or pull skills repo
mkdir -p "$HOME/.claude"
if [ -d "$SKILLS_DIR/.git" ]; then
  say "Pulling latest skills..."
  git -C "$SKILLS_DIR" pull --quiet --rebase --autostash
elif [ -d "$SKILLS_DIR" ] && [ -n "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]; then
  BACKUP="${SKILLS_DIR}.bak.$(date +%s)"
  warn "Existing $SKILLS_DIR backed up to $BACKUP"
  mv "$SKILLS_DIR" "$BACKUP"
  say "Cloning skills repo..."
  git clone --quiet "$REPO_URL" "$SKILLS_DIR"
else
  rm -rf "$SKILLS_DIR" 2>/dev/null || true
  say "Cloning skills repo..."
  git clone --quiet "$REPO_URL" "$SKILLS_DIR"
fi
ok "Skills at $SKILLS_DIR"

# 2. Patch settings.json — add SessionStart auto-pull hook (idempotent)
if ! command -v python3 >/dev/null 2>&1; then
  warn "python3 not found — skipping settings.json patch."
  warn "Add this hook manually to $SETTINGS (see README.md in the repo)."
else
  [ -f "$SETTINGS" ] || echo "{}" > "$SETTINGS"
  python3 - "$SETTINGS" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)
hook_cmd = 'git -C "$HOME/.claude/skills" pull --quiet --rebase --autostash 2>/dev/null || true'
cfg.setdefault("hooks", {})
cfg["hooks"].setdefault("SessionStart", [])
for entry in cfg["hooks"]["SessionStart"]:
    for h in entry.get("hooks", []):
        if h.get("type") == "command" and ".claude/skills" in h.get("command", "") and "pull" in h.get("command", ""):
            print("hook-exists")
            sys.exit(0)
cfg["hooks"]["SessionStart"].append({
    "hooks": [{"type": "command", "command": hook_cmd}]
})
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print("hook-added")
PY
  ok "SessionStart auto-pull hook in $SETTINGS"
fi

# 3. Patch ~/.claude/CLAUDE.md — add natural-language trigger (idempotent)
MARKER="<!-- claude-skills-sync:do-not-remove -->"
if [ -f "$CLAUDE_MD" ] && grep -qF "$MARKER" "$CLAUDE_MD"; then
  : # already there
else
  cat >> "$CLAUDE_MD" <<'EOF'

## Claude Skills sync — Cem-Tas96/claude-skills

<!-- claude-skills-sync:do-not-remove -->
`~/.claude/skills/` ist ein Git-Repo (https://github.com/Cem-Tas96/claude-skills). Skills syncen automatisch via SessionStart-Hook.

**Natural-language Trigger** (wenn Cem das sagt, sofort ausführen — keine Rückfrage):

- "skills updaten" / "skills installieren" / "neuesten skill holen" / "<skill-name> installieren"
  → `git -C ~/.claude/skills pull --rebase --autostash`
  → Dann dem User sagen: "Restart Claude Code (`/exit` und neu starten), damit die Skill-Definitionen neu geladen werden."

- "skill <name> erstellen" / "neuen skill anlegen <name>"
  → Neuen Ordner `~/.claude/skills/<name>/` mit `SKILL.md` (YAML-Frontmatter + Inhalt) anlegen, dann committen+pushen aus `~/.claude/skills/`.

**Auf neuem Gerät einrichten:** `curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.sh | bash`
(Windows PowerShell: `iex (iwr https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.ps1).Content`)
EOF
  ok "Trigger-Block in $CLAUDE_MD eingefügt"
fi

echo ""
ok "Done."
echo "  Restart Claude Code (or run /exit and reopen) to load the latest skills."
