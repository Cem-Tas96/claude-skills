# Claude Code skills installer / updater for Windows PowerShell.
# Public repo — no auth needed. Auto-installs git via winget if missing.
#
# One-liner:
#   irm https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$RepoSlug   = "Cem-Tas96/claude-skills"
$RepoUrl    = "https://github.com/$RepoSlug.git"
$ClaudeRoot = Join-Path $env:USERPROFILE ".claude"
$SkillsDir  = Join-Path $ClaudeRoot "skills"
$Settings   = Join-Path $ClaudeRoot "settings.json"
$ClaudeMd   = Join-Path $ClaudeRoot "CLAUDE.md"

function Say($msg)  { Write-Host "-> $msg" -ForegroundColor Cyan }
function OK($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[!] $msg"  -ForegroundColor Yellow }
function Die($msg)  { Write-Host "[X] $msg"  -ForegroundColor Red; exit 1 }

function Update-Path {
  $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user"
}

# 0. Ensure git is available in this session (install via winget if missing)
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Update-Path }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Die "Neither git nor winget found. Install Git manually: https://git-scm.com/download/win"
  }
  Say "Installing Git via winget..."
  winget install --id Git.Git --silent --accept-source-agreements --accept-package-agreements | Out-Null
  if ($LASTEXITCODE -ne 0) { Die "winget install failed. Install Git manually: https://git-scm.com/download/win" }
  Update-Path
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Die "git still not found after install. Close this terminal, open a new one, and re-run the one-liner."
}
OK "git ready ($(& git --version))"

# 1. Clone or pull skills repo
New-Item -ItemType Directory -Force -Path $ClaudeRoot | Out-Null

if (Test-Path (Join-Path $SkillsDir ".git")) {
  Say "Pulling latest skills..."
  & git -C $SkillsDir pull --quiet --rebase --autostash
} elseif ((Test-Path $SkillsDir) -and ((Get-ChildItem $SkillsDir -Force | Measure-Object).Count -gt 0)) {
  $backup = "$SkillsDir.bak.$([int64](Get-Date -UFormat %s))"
  Warn "Existing $SkillsDir backed up to $backup"
  Move-Item $SkillsDir $backup
  Say "Cloning skills repo..."
  & git clone --quiet $RepoUrl $SkillsDir
} else {
  if (Test-Path $SkillsDir) { Remove-Item -Recurse -Force $SkillsDir }
  Say "Cloning skills repo..."
  & git clone --quiet $RepoUrl $SkillsDir
}
OK "Skills at $SkillsDir"

# 1b. Global secret-scanning pre-commit hook — blocks credentials/keys in ANY repo
$HooksDir = Join-Path $SkillsDir "hooks"
if (Test-Path (Join-Path $HooksDir "pre-commit")) {
  $HooksPathCfg = ($HooksDir -replace '\\','/')
  $cur = (& git config --global --get core.hooksPath) 2>$null
  if ([string]::IsNullOrWhiteSpace($cur) -or $cur -eq $HooksPathCfg) {
    & git config --global core.hooksPath $HooksPathCfg
    OK "Secret-Guard aktiv (global core.hooksPath -> $HooksPathCfg)"
  } else {
    Warn "core.hooksPath bereits gesetzt ($cur) — nicht ueberschrieben. Manuell: git config --global core.hooksPath `"$HooksPathCfg`""
  }
  $DenyDir = Join-Path $env:USERPROFILE ".config\git"
  $Deny    = Join-Path $DenyDir "secret-denylist.local.txt"
  if (-not (Test-Path $Deny)) {
    New-Item -ItemType Directory -Force -Path $DenyDir | Out-Null
    @(
      "# Persoenliche Secret-Denylist — literal-Strings die NIE in einen Commit duerfen.",
      "# Eine pro Zeile, # = Kommentar. Wird vom globalen pre-commit-Hook gelesen. Lokal, nie eingecheckt."
    ) | Set-Content -Encoding UTF8 $Deny
    OK "Denylist-Template angelegt: $Deny"
  }
} else {
  Warn "hooks/pre-commit noch nicht im Repo — Secret-Guard nach naechstem Pull aktiv."
}

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

# 2b. Token-Discipline: effortLevel default + self-healing context hook (idempotent)
$cfg2 = Get-Content $Settings -Raw | ConvertFrom-Json -AsHashtable
$tdChanged = $false
if (-not $cfg2.ContainsKey("effortLevel")) { $cfg2["effortLevel"] = "xhigh"; $tdChanged = $true }
if (-not $cfg2.ContainsKey("hooks")) { $cfg2["hooks"] = @{} }
if (-not $cfg2["hooks"].ContainsKey("SessionStart")) { $cfg2["hooks"]["SessionStart"] = @() }
$haveCtx = $false
foreach ($entry in @($cfg2["hooks"]["SessionStart"])) {
  if ($entry.ContainsKey("hooks")) {
    foreach ($h in @($entry["hooks"])) {
      if ($h["command"] -match "ensure-context\.sh") { $haveCtx = $true }
    }
  }
}
if (-not $haveCtx) {
  $ctxCmd = 'sh "$HOME/.claude/skills/hooks/ensure-context.sh" 2>/dev/null || true'
  $cfg2["hooks"]["SessionStart"] = @($cfg2["hooks"]["SessionStart"]) + @{ hooks = @(@{ type = "command"; command = $ctxCmd }) }
  $tdChanged = $true
}
if ($tdChanged) { ($cfg2 | ConvertTo-Json -Depth 32) | Set-Content -Encoding UTF8 $Settings }
# Jetzt einmalig anwenden (Git for Windows liefert sh); fail-safe
try { & sh "$env:USERPROFILE/.claude/skills/hooks/ensure-context.sh" 2>$null } catch {}
OK "Token-Discipline aktiv (effortLevel xhigh-Default + Triage-Context-Hook)"

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
``~/.claude/skills/`` ist ein Git-Repo (https://github.com/Cem-Tas96/claude-skills, **public, read-only für Fremde**). Skills syncen automatisch via SessionStart-Hook.

**Natural-language Trigger** (wenn Cem das sagt, sofort ausführen — keine Rückfrage):

- "skills updaten" / "skills installieren" / "neuesten skill holen" / "<skill-name> installieren"
  → ``git -C ~/.claude/skills pull --rebase --autostash``
  → Dann dem User sagen: "Restart Claude Code (``/exit`` und neu starten), damit die Skill-Definitionen neu geladen werden."

- "skill <name> erstellen" / "neuen skill anlegen <name>"
  → Neuen Ordner ``~/.claude/skills/<name>/`` mit ``SKILL.md`` (YAML-Frontmatter + Inhalt) anlegen, dann committen+pushen aus ``~/.claude/skills/``.

**Auf neuem Gerät einrichten (Installer installiert git automatisch falls fehlend):**
- Windows PowerShell: ``irm https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.ps1 | iex``
- macOS/Linux/Git-Bash: ``curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills/main/install.sh | bash``
"@
  Add-Content -Path $ClaudeMd -Value $block -Encoding UTF8
  OK "Trigger-Block in $ClaudeMd eingefügt"
}

Write-Host ""
OK "Done."
Write-Host "  Restart Claude Code (or run /exit and reopen) to load the latest skills."
