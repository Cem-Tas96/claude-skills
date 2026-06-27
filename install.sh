#!/usr/bin/env bash
# Claude Code skills installer / updater for macOS, Linux, and Windows-Git-Bash.
# Public repo — no auth needed. Auto-installs git via brew/apt/dnf/pacman if missing.
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.sh | bash
set -euo pipefail

REPO_SLUG="Cem-Tas96/claude-skills"
REPO_URL="https://github.com/${REPO_SLUG}.git"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS="$HOME/.claude/settings.json"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

say()  { printf '\033[36m→\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# 0. Ensure git is available (install via the platform's package manager if missing)
if ! command -v git >/dev/null 2>&1; then
  os="$(uname -s)"
  case "$os" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        say "Installing git via Homebrew..."
        brew install git
      else
        # macOS ships git via the Xcode Command Line Tools — trigger install
        say "Triggering Xcode Command Line Tools install (provides git)..."
        xcode-select --install || true
        die "Run the GUI installer that just opened, then re-run this one-liner."
      fi
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        say "Installing git via apt..."
        sudo apt-get update -qq && sudo apt-get install -y git
      elif command -v dnf >/dev/null 2>&1; then
        say "Installing git via dnf..."
        sudo dnf install -y git
      elif command -v pacman >/dev/null 2>&1; then
        say "Installing git via pacman..."
        sudo pacman -S --noconfirm git
      elif command -v apk >/dev/null 2>&1; then
        say "Installing git via apk..."
        sudo apk add --no-cache git
      else
        die "No supported package manager (apt/dnf/pacman/apk). Install git manually: https://git-scm.com/"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      die "On Windows Git-Bash, install Git for Windows manually: https://git-scm.com/download/win"
      ;;
    *)
      die "Unsupported OS: $os. Install git manually: https://git-scm.com/"
      ;;
  esac
fi

command -v git >/dev/null 2>&1 || die "git still not found after install attempt."
ok "git ready ($(git --version))"

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

# 1b. Global secret-scanning pre-commit hook — blocks credentials/keys in ANY repo
HOOKS_DIR="$SKILLS_DIR/hooks"
if [ -f "$HOOKS_DIR/pre-commit" ]; then
  chmod +x "$HOOKS_DIR/pre-commit" 2>/dev/null || true
  cur="$(git config --global --get core.hooksPath || true)"
  if [ -z "$cur" ] || [ "$cur" = "$HOOKS_DIR" ]; then
    git config --global core.hooksPath "$HOOKS_DIR"
    ok "Secret-Guard aktiv (global core.hooksPath -> $HOOKS_DIR)"
  else
    warn "core.hooksPath bereits gesetzt ($cur) — nicht überschrieben. Manuell: git config --global core.hooksPath \"$HOOKS_DIR\""
  fi
  DENY_DIR="$HOME/.config/git"; DENY="$DENY_DIR/secret-denylist.local.txt"
  if [ ! -f "$DENY" ]; then
    mkdir -p "$DENY_DIR"
    cat > "$DENY" <<'EOF'
# Persönliche Secret-Denylist — literal-Strings die NIE in einen Commit dürfen.
# Eine pro Zeile, # = Kommentar. Wird vom globalen pre-commit-Hook gelesen. Lokal, nie eingecheckt.
EOF
    ok "Denylist-Template angelegt: $DENY"
  fi
else
  warn "hooks/pre-commit noch nicht im Repo — Secret-Guard nach nächstem Pull aktiv."
fi

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

# 2b. Token-Discipline: effortLevel default + self-healing context hook (idempotent)
#     Holt den ultracode-„token cost is not a constraint"-Default auf risiko-proportional zurueck.
if command -v python3 >/dev/null 2>&1; then
  [ -f "$SETTINGS" ] || echo "{}" > "$SETTINGS"
  python3 - "$SETTINGS" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)
changed = False
# Effort-Default xhigh — nur setzen wenn der User keine bewusste Wahl hat (nie ueberschreiben)
if "effortLevel" not in cfg:
    cfg["effortLevel"] = "xhigh"
    changed = True
# Zweiter SessionStart-Eintrag: stellt den Triage-Block in CLAUDE.md sicher (laesst den git-pull unangetastet)
cfg.setdefault("hooks", {}).setdefault("SessionStart", [])
ctx_cmd = 'sh "$HOME/.claude/skills/hooks/ensure-context.sh" 2>/dev/null || true'
have = any("ensure-context.sh" in h.get("command", "")
           for entry in cfg["hooks"]["SessionStart"] for h in entry.get("hooks", []))
if not have:
    cfg["hooks"]["SessionStart"].append({"hooks": [{"type": "command", "command": ctx_cmd}]})
    changed = True
if changed:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2); f.write("\n")
print("td-updated" if changed else "td-exists")
PY
  # Jetzt einmalig anwenden (Block in CLAUDE.md schreiben), fail-safe
  sh "$SKILLS_DIR/hooks/ensure-context.sh" 2>/dev/null || true
  ok "Token-Discipline aktiv (effortLevel xhigh-Default + Triage-Context-Hook)"
else
  warn "python3 fehlt — Token-Discipline-Settings uebersprungen (Block via Hook beim naechsten Start)."
fi

# 3. Patch ~/.claude/CLAUDE.md — add natural-language trigger (idempotent)
MARKER="<!-- claude-skills-sync:do-not-remove -->"
if [ -f "$CLAUDE_MD" ] && grep -qF "$MARKER" "$CLAUDE_MD"; then
  : # already there
else
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
    [ -e "$rc_file" ] || touch "$rc_file"
    if grep -qF "$MARKER_BEGIN" "$rc_file" 2>/dev/null; then
      :
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
