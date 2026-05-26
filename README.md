# Claude Code Skills — Cem

Personal skills for Claude Code, synced across all my machines (macOS + Windows).

Lives at `~/.claude/skills/` so every Claude Code session in every project picks them up automatically.

## Install / update on a new machine — one command

### macOS / Linux / Windows-Git-Bash
```bash
curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.sh | bash
```

### Windows PowerShell
```powershell
iex (iwr https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.ps1).Content
```

That's it. The installer:
1. Clones (or pulls) `~/.claude/skills/`
2. Adds a SessionStart auto-pull hook to `~/.claude/settings.json` (idempotent — won't duplicate)
3. Appends a natural-language trigger block to `~/.claude/CLAUDE.md` so Claude in any project recognises `"skills updaten"` / `"<skill> installieren"` and runs the right command

After install: restart Claude Code (`/exit` and reopen) so the new skills load.

## Natural-language usage from inside any Claude Code session

Once installed, you can just *say* any of these to Claude in any project:

- **`"feature-delivery installieren"`** / **`"skills updaten"`** / **`"neuesten skill holen"`**
  → Claude runs `git -C ~/.claude/skills pull --rebase --autostash` and tells you to restart Claude Code.
- **`"neuen skill anlegen <name>"`** / **`"skill <name> erstellen"`**
  → Claude scaffolds `~/.claude/skills/<name>/SKILL.md` and commits+pushes.

## Editing skills

1. Edit `SKILL.md` (or files in `references/`) directly in `~/.claude/skills/<skill-name>/`.
2. Commit + push:
   ```bash
   git -C ~/.claude/skills add -A
   git -C ~/.claude/skills commit -m "feat(<skill>): <what changed>"
   git -C ~/.claude/skills push
   ```
3. Other machines pick it up at next Claude Code start (via the SessionStart hook), or immediately with `git -C ~/.claude/skills pull`.

## How the auto-pull hook works

Added to `~/.claude/settings.json` by the installer:

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

The `|| true` makes it fail-safe: no internet, merge conflict, whatever — Claude Code still starts.

## Skills in this repo

- **feature-delivery** — Enterprise-grade implementation discipline: blast-radius mapping → state-table → symmetric rollout → security pass. Use before *and* during any non-trivial code change.
