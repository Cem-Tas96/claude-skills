# Claude Code skills installer / updater for Windows PowerShell.
# One-liner: iex (iwr https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.ps1).Content

$ErrorActionPreference = "Stop"

$RepoUrl    = "https://github.com/Cem-Tas96/claude-skills.git"
$SkillsDir  = Join-Path $env:USERPROFILE ".claude\skills"
$Settings   = Join-Path $env:USERPROFILE ".claude\settings.json"
$ClaudeMd   = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"
$ClaudeRoot = Join-Path $env:USERPROFILE ".claude"

function Say($msg) { Write-Host "-> $msg" -ForegroundColor Cyan }
function OK ($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg){ Write-Host "[!] $msg" -ForegroundColor Yellow }

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
  git clone --quiet $RepoUrl $SkillsDir
} else {
  if (Test-Path $SkillsDir) { Remove-Item -Recurse -Force $SkillsDir }
  Say "Cloning skills repo..."
  git clone --quiet $RepoUrl $SkillsDir
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
`~/.claude/skills/` ist ein Git-Repo (https://github.com/Cem-Tas96/claude-skills). Skills syncen automatisch via SessionStart-Hook.

**Natural-language Trigger** (wenn Cem das sagt, sofort ausführen — keine Rückfrage):

- "skills updaten" / "skills installieren" / "neuesten skill holen" / "<skill-name> installieren"
  → ``git -C ~/.claude/skills pull --rebase --autostash``
  → Dann dem User sagen: "Restart Claude Code (``/exit`` und neu starten), damit die Skill-Definitionen neu geladen werden."

- "skill <name> erstellen" / "neuen skill anlegen <name>"
  → Neuen Ordner ``~/.claude/skills/<name>/`` mit ``SKILL.md`` (YAML-Frontmatter + Inhalt) anlegen, dann committen+pushen aus ``~/.claude/skills/``.

**Auf neuem Gerät einrichten:** ``curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.sh | bash``
(Windows PowerShell: ``iex (iwr https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.ps1).Content``)
"@
  Add-Content -Path $ClaudeMd -Value $block -Encoding UTF8
  OK "Trigger-Block in $ClaudeMd eingefügt"
}

Write-Host ""
OK "Done."
Write-Host "  Restart Claude Code (or run /exit and reopen) to load the latest skills."
