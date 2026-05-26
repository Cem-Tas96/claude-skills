# Claude Code Skills — Cem

Personal skills for Claude Code, synced across all my machines (macOS + Windows).

Lives at `~/.claude/skills/` so every Claude Code session in every project picks them up automatically.

## First-time setup on a new machine

### macOS / Linux
```bash
# 1. Make sure ~/.claude exists (start Claude Code once if not)
mkdir -p ~/.claude

# 2. If ~/.claude/skills already has files (e.g. from a fresh Claude Code install),
#    move them out of the way first:
[ -d ~/.claude/skills ] && mv ~/.claude/skills ~/.claude/skills.bak

# 3. Clone this repo into ~/.claude/skills
git clone git@github.com:Cem-Tas96/claude-skills.git ~/.claude/skills
# (or HTTPS: git clone https://github.com/Cem-Tas96/claude-skills.git ~/.claude/skills)

# 4. Add the auto-pull hook to ~/.claude/settings.json (see "Auto-update hook" below)
```

### Windows (PowerShell)
```powershell
# 1. Make sure %USERPROFILE%\.claude exists
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude" | Out-Null

# 2. Back up any existing skills folder
if (Test-Path "$env:USERPROFILE\.claude\skills") {
  Move-Item "$env:USERPROFILE\.claude\skills" "$env:USERPROFILE\.claude\skills.bak"
}

# 3. Clone this repo
git clone https://github.com/Cem-Tas96/claude-skills.git "$env:USERPROFILE\.claude\skills"

# 4. Add the auto-pull hook to %USERPROFILE%\.claude\settings.json (see below)
```

## Auto-update hook

Add this block to `~/.claude/settings.json` (or `%USERPROFILE%\.claude\settings.json` on Windows). It runs `git pull` silently every time a Claude Code session starts, so the newest skill version is always loaded.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "git -C \"$HOME/.claude/skills\" pull --quiet --rebase --autostash 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

> The `|| true` makes the hook fail-safe: no internet, merge conflict, whatever — Claude Code still starts.

On Windows the same command works inside Git Bash. If Claude Code on Windows uses PowerShell by default for hooks, swap to:

```json
"command": "git -C \"$env:USERPROFILE/.claude/skills\" pull --quiet --rebase --autostash; if (-not $?) { $LASTEXITCODE = 0 }"
```

## Editing skills

1. Edit `SKILL.md` (or files in `references/`) directly in `~/.claude/skills/<skill-name>/`.
2. Commit + push:
   ```bash
   git -C ~/.claude/skills add -A
   git -C ~/.claude/skills commit -m "feat(<skill>): <what changed>"
   git -C ~/.claude/skills push
   ```
3. Other machines pick it up at next Claude Code start (via the hook), or immediately with `git -C ~/.claude/skills pull`.

## Skills in this repo

- **feature-delivery** — Enterprise-grade implementation discipline: blast-radius mapping → state-table → symmetric rollout → security pass. Use before *and* during any non-trivial code change.
