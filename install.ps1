# Claude Code skills installer / updater for Windows PowerShell.
# Private repo — needs `gh` CLI authenticated (run `gh auth login` once).
# One-liner:
#   gh api repos/Cem-Tas96/claude-skills/contents/install.ps1 -H "Accept: application/vnd.github.raw" | iex

$ErrorActionPreference = "Stop"

$RepoSlug   = "Cem-Tas96/claude-skills"
$SkillsDir  = Join-Path $env:USERPROFILE ".claude\skills"
$Settings   = Join-Path $env:USERPROFILE ".claude\settings.json"
$ClaudeMd   = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"
$ClaudeRoot = Join-Path $env:USERPROFILE ".claude"

function Say($msg) { Write-Host "-> $msg" -ForegroundColor Cyan }
function OK ($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg){ Write-Host "[!] $msg" -ForegroundColor Yellow }
function Die ($msg){ Write-Host "[X] $msg" -ForegroundColor Red; exit 1 }

# 0. Preflight — gh CLI required because the repo is private
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Die "GitHub CLI (gh) not found. Install: https://cli.github.com/  then run: gh auth login"
}
& gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
  Die "gh is not logged in. Run: gh auth login  (choose GitHub.com -> HTTPS -> authenticate)"
}
& gh auth setup-git *> $null

# 1. Clone or pull skills repo
New-Item -ItemType Directory -Force -Path $ClaudeRoot | Out-Null

if (Test-Path (Join-Path $SkillsDir ".git")) {
  Say "Pulling latest skills..."
  git -C $SkillsDir pull --quiet --rebase --autostash
} elseif ((Test-Path $SkillsDir) -and ((Get-ChildItem $SkillsDir -Force | Measure-Object).Count -gt 0)) {
  $backup = "$SkillsDir.bak.$([int64](Get-Date -UFormat %s))"
  Warn "Existing $SkillsDir backed up to $backup"
  Move-Item $SkillsDir $backup
  Say "Cloning skills repo..."
  gh repo clone $RepoSlug $SkillsDir -- --quiet
} else {
  if (Test-Path $SkillsDir) { Remove-Item -Recurse -Force $SkillsDir }
  Say "Cloning skills repo..."
  gh repo clone $RepoSlug $SkillsDir -- --quiet
}
OK "Skills at $SkillsDir"

# 2. Patch settings.json — add SessionStart auto-pull hook (idempotent)
if (-not (Test-Path $Settings)) { '{}' | Set-Content -Encoding UTF8 $Settings }

$cfg = Get-Content $Settings -Raw | ConvertFrom-Json -AsHashtable
$hookCmd = 'git -C "$HOME/.claude/skills" pull --quiet --rebase --autostash 2>/dev/null || true'

if (-not $cfg.ContainsKey("hooks")) { $cfg["hooks"] = @{} }
if (-not $cfg["hooks"].ContainsKey("SessionStart")) { $cfg["hooks"]["SessionStart"] = @() }

$alreadyInstalled = $false
foreach ($entry in @($cfg["hooks"]["SessionStart"])) {
  if ($entry.ContainsKey("hooks")) {
    foreach ($h in @($entry["hooks"])) {
      if ($h["type"] -eq "command" -and $h["command"] -match "\.claude[/\\]skills" -and $h["command"] -match "pull") {
        $alreadyInstalled = $true
      }
    }
  }
}

if (-not $alreadyInstalled) {
  $newEntry = @{ hooks = @(@{ type = "command"; command = $hookCmd }) }
  $cfg["hooks"]["SessionStart"] = @($cfg["hooks"]["SessionStart"]) + $newEntry
  ($cfg | ConvertTo-Json -Depth 32) | Set-Content -Encoding UTF8 $Settings
  OK "SessionStart auto-pull hook in $Settings"
} else {
  OK "SessionStart hook already in $Settings"
}

# 3. Patch ~/.claude/CLAUDE.md — add natural-language trigger (idempotent)
$marker = "<!-- claude-skills-sync:do-not-remove -->"
$alreadyHas = $false
if (Test-Path $ClaudeMd) {
  $alreadyHas = (Get-Content $ClaudeMd -Raw -ErrorAction SilentlyContinue) -match [regex]::Escape($marker)
}

if (-not $alreadyHas) {
  $block = @"

## Claude Skills sync — Cem-Tas96/claude-skills

$marker
`~/.claude/skills/`` ist ein Git-Repo (https://github.com/Cem-Tas96/claude-skills, **privat**). Skills syncen automatisch via SessionStart-Hook.

**Natural-language Trigger** (wenn Cem das sagt, sofort ausführen — keine Rückfrage):

- "skills updaten" / "skills installieren" / "neuesten skill holen" / "<skill-name> installieren"
  → ``git -C ~/.claude/skills pull --rebase --autostash``
  → Dann dem User sagen: "Restart Claude Code (``/exit`` und neu starten), damit die Skill-Definitionen neu geladen werden."

- "skill <name> erstellen" / "neuen skill anlegen <name>"
  → Neuen Ordner ``~/.claude/skills/<name>/`` mit ``SKILL.md`` (YAML-Frontmatter + Inhalt) anlegen, dann committen+pushen aus ``~/.claude/skills/``.

**Auf neuem Gerät einrichten (privates Repo, braucht ``gh`` CLI + ``gh auth login``):**
``gh api repos/Cem-Tas96/claude-skills/contents/install.sh -H "Accept: application/vnd.github.raw" | bash``
(Windows PowerShell: ``gh api repos/Cem-Tas96/claude-skills/contents/install.ps1 -H "Accept: application/vnd.github.raw" | iex``)
"@
  Add-Content -Path $ClaudeMd -Value $block -Encoding UTF8
  OK "Trigger-Block in $ClaudeMd eingefügt"
}

Write-Host ""
OK "Done."
Write-Host "  Restart Claude Code (or run /exit and reopen) to load the latest skills."
