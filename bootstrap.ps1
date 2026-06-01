# Claude Code skills bootstrap for Windows.
# Public entry point: this file lives in a PUBLIC mirror repo so it can be fetched
# without auth. It installs gh CLI if missing, refreshes PATH so gh is callable in
# the current session, drives gh auth login if needed, then chains into install.ps1
# from the private skills repo.
#
# One-liner (for the colleague):
#   irm https://raw.githubusercontent.com/Cem-Tas96/claude-skills-installer/main/bootstrap.ps1 | iex

$ErrorActionPreference = "Stop"

$PrivateRepo = "Cem-Tas96/claude-skills"
$InstallerPath = "install.ps1"

function Say($msg)  { Write-Host "-> $msg" -ForegroundColor Cyan }
function OK($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[!] $msg"  -ForegroundColor Yellow }
function Die($msg)  { Write-Host "[X] $msg"  -ForegroundColor Red; exit 1 }

function Refresh-Path {
  $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user"
}

# 1. Ensure gh is available in the current session
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  # Maybe gh was installed in another session but our PATH is stale
  Refresh-Path
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Die "Neither gh nor winget found. Install gh manually: https://cli.github.com/"
  }
  Say "Installing GitHub CLI via winget..."
  winget install --id GitHub.cli --silent --accept-source-agreements --accept-package-agreements | Out-Null
  if ($LASTEXITCODE -ne 0) { Die "winget install failed. Install gh manually: https://cli.github.com/" }
  Refresh-Path
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Die "gh still not found after install. Close this terminal, open a new one, and re-run the one-liner."
}
OK "gh CLI ready ($(& gh --version | Select-Object -First 1))"

# 2. Ensure gh is authenticated
& gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
  Say "GitHub login required. Follow the prompts (GitHub.com -> HTTPS -> browser login)."
  & gh auth login
  if ($LASTEXITCODE -ne 0) { Die "gh auth login failed." }
}
& gh auth setup-git *> $null
OK "GitHub auth ready"

# 3. Fetch install.ps1 from the private repo and run it
Say "Fetching skills installer from private repo..."
$installer = & gh api "repos/$PrivateRepo/contents/$InstallerPath" -H "Accept: application/vnd.github.raw"
if ($LASTEXITCODE -ne 0 -or -not $installer) {
  Die "Failed to fetch $InstallerPath from $PrivateRepo. Check that your gh account has access."
}
Invoke-Expression ($installer -join "`n")
