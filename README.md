# Claude Code Skills — Cem

Personal skills for Claude Code, synced across all my machines (macOS + Windows).

Lives at `~/.claude/skills/` so every Claude Code session in every project picks them up automatically.

## Install / update on a new machine — one command

> **Public repo** — kein Login/Token nötig. Der Installer installiert `git` automatisch (winget/brew/apt/dnf/pacman/apk), falls es fehlt.
>
> ⚠️ Auf **Windows** die PowerShell-Zeile nutzen, nicht die bash-Zeile: in PowerShell ist `bash` das (oft nicht installierte) WSL-bash → `execvpe(/bin/bash) failed`. Die bash-Zeile ist für macOS/Linux/**Git Bash**.

### macOS / Linux / Windows-Git-Bash
```bash
curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.sh | bash
```

### Windows PowerShell
```powershell
irm https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.ps1 | iex
```

> Hinweis: `... | iex` funktioniert mit `irm` (liefert **einen** String). `gh api ... | iex` bricht, weil `gh` zeilenweise ausgibt und PowerShell jede Zeile einzeln an `iex` schickt — falls du `gh` brauchst (z. B. wenn das Repo wieder privat wäre), `gh api ... | Out-String | iex` verwenden.

That's it. The installer:
1. Clones (or pulls) `~/.claude/skills/`
2. Sets a **global secret-scanning pre-commit hook** (`git config --global core.hooksPath …/hooks`) so Keys/Tokens/`.env`/Private-Keys nie in *irgendein* Repo committet werden — plus lokales Denylist-Template in `~/.config/git/secret-denylist.local.txt`
3. Adds a SessionStart auto-pull hook to `~/.claude/settings.json` (idempotent — won't duplicate)
4. Appends a natural-language trigger block to `~/.claude/CLAUDE.md` so Claude in any project recognises `"skills updaten"` / `"<skill> installieren"` and runs the right command

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

- **feature-delivery** — Enterprise-grade implementation discipline, run as an autonomous **Loop-Engine** (Loop Engineering): one goal in → the run self-prompts through blast-radius mapping → state-table → symmetric rollout → security pass, verifies with independent subagents (writer ≠ reviewer), remembers progress in a durable checkpoint, and keeps going until the Definition-of-Done is truly met. Uses the five loop building blocks (automation/worktrees/skills/connectors/subagents) risk-proportionally instead of hand-holding. Use before *and* during any non-trivial code change. See `feature-delivery/references/loop-engine.md`.
- **feature-testing** — Enterprise test automation for any new feature: change analysis → test strategy → implementation → auto-fix loop → quality gates → release. Orchestrated by feature-delivery's verification phase.
- **gameboy-gate** — Aufnahmeprüfung für Projekte, die auf dem „Gameboy"-Server (Hetzner CAX11, 4 GB RAM, 2 vCPU) deployt werden: berechnet RAM/CPU-Limits dynamisch aus dem aktuellen Server-Zustand, setzt sie persistent in Coolify, testet unter Last und gibt PASS/FAIL zurück. Server-spezifische Verbindungsdaten liegen lokal in `gameboy-gate/gameboy.local.md` (gitignored), nicht im Repo.
