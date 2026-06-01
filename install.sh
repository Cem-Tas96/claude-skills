#!/usr/bin/env bash
# Claude Code skills installer / updater for macOS, Linux, and Windows-Git-Bash.
# Private repo — needs `gh` CLI authenticated (run `gh auth login` once).
#
# For first-time setup on a new machine, use the public bootstrap instead — it
# installs gh, drives auth login, then chains in here:
#   curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills-installer/main/bootstrap.sh | bash
#
# Direct one-liner (gh must already be installed + authenticated):
#   gh api repos/Cem-Tas96/claude-skills/contents/install.sh -H "Accept: application/vnd.github.raw" | bash
set -euo pipefail

REPO_SLUG="Cem-Tas96/claude-skills"
REPO_URL="https://github.com/${REPO_SLUG}.git"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS="$HOME/.claude/settings.json"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

say() { printf '\033[36m→\033[0m %s\n' "$*"; }
ok()  { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*" >&2; }
die() { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# 0. Preflight — gh CLI required because the repo is private
if ! command -v gh >/dev/null 2>&1; then
  die "GitHub CLI (gh) not found. Install it: https://cli.github.com/  then run: gh auth login"
fi
if ! gh auth status >/dev/null 2>&1; then
  die "gh is not logged in. Run: gh auth login  (choose GitHub.com → HTTPS → authenticate)"
fi
# Make sure git can clone/pull the private repo via gh's credential helper
gh auth setup-git >/dev/null 2>&1 || true

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
  gh repo clone "$REPO_SLUG" "$SKILLS_DIR" -- --quiet
else
  rm -rf "$SKILLS_DIR" 2>/dev/null || true
  say "Cloning skills repo..."
  gh repo clone "$REPO_SLUG" "$SKILLS_DIR" -- --quiet
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
`~/.claude/skills/` ist ein Git-Repo (https://github.com/Cem-Tas96/claude-skills, **privat**). Skills syncen automatisch via SessionStart-Hook.

**Natural-language Trigger** (wenn Cem das sagt, sofort ausführen — keine Rückfrage):

- "skills updaten" / "skills installieren" / "neuesten skill holen" / "<skill-name> installieren"
  → `git -C ~/.claude/skills pull --rebase --autostash`
  → Dann dem User sagen: "Restart Claude Code (`/exit` und neu starten), damit die Skill-Definitionen neu geladen werden."

- "skill <name> erstellen" / "neuen skill anlegen <name>"
  → Neuen Ordner `~/.claude/skills/<name>/` mit `SKILL.md` (YAML-Frontmatter + Inhalt) anlegen, dann committen+pushen aus `~/.claude/skills/`.

**Auf neuem Gerät einrichten (privates Repo — Bootstrap installiert `gh` automatisch und startet `gh auth login`):**
- macOS/Linux/Git-Bash: `curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills-installer/main/bootstrap.sh | bash`
- Windows PowerShell: `irm https://raw.githubusercontent.com/Cem-Tas96/claude-skills-installer/main/bootstrap.ps1 | iex`
EOF
  ok "Trigger-Block in $CLAUDE_MD eingefügt"
fi

# 4. Install claude-auto-resume shell wrapper into zshrc + bashrc (idempotent)
WRAPPER="$SKILLS_DIR/shell/claude-auto-resume.sh"
MARKER_BEGIN="# >>> claude-auto-resume >>>"
MARKER_END="# <<< claude-auto-resume <<<"
SNIPPET="${MARKER_BEGIN}
# Auto-resume Claude Code on /exit (continues last session). Bypass: CLAUDE_NO_AUTO_RESUME=1 claude
[ -f \"\$HOME/.claude/skills/shell/claude-auto-resume.sh\" ] && . \"\$HOME/.claude/skills/shell/claude-auto-resume.sh\"
${MARKER_END}"

if [ -f "$WRAPPER" ]; then
  for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
    # Touch the rc-file if it doesn't exist yet (zsh ist Default auf macOS Sonoma+; bash auf vielen Linux)
    [ -e "$rc_file" ] || touch "$rc_file"
    if grep -qF "$MARKER_BEGIN" "$rc_file" 2>/dev/null; then
      : # block already there — keine Aktion
    else
      printf '\n%s\n' "$SNIPPET" >> "$rc_file"
      ok "claude-auto-resume in $(basename "$rc_file") eingefügt"
    fi
  done
else
  warn "Wrapper-Script $WRAPPER nicht im Repo — wird beim nächsten Pull verfügbar."
fi

echo ""
ok "Done."
echo "  Restart Claude Code (or run /exit and reopen) to load the latest skills."
echo "  Neue Shell-Sessions haben automatisches /exit → resume (Ctrl-C im 2s-Window = endgültig raus)."
