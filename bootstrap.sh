#!/usr/bin/env bash
# Claude Code skills bootstrap for macOS, Linux, and Git-Bash on Windows.
# Public entry point: this file lives in a PUBLIC mirror repo so it can be fetched
# without auth. It installs gh CLI if missing, drives gh auth login if needed,
# then chains into install.sh from the private skills repo.
#
# One-liner (for the colleague):
#   curl -fsSL https://raw.githubusercontent.com/Cem-Tas96/claude-skills-installer/main/bootstrap.sh | bash

set -euo pipefail

PRIVATE_REPO="Cem-Tas96/claude-skills"
INSTALLER_PATH="install.sh"

say()  { printf '\033[36m->\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[X]\033[0m %s\n' "$*" >&2; exit 1; }

# 1. Install gh if missing
if ! command -v gh >/dev/null 2>&1; then
  os="$(uname -s)"
  case "$os" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        say "Installing GitHub CLI via Homebrew..."
        brew install gh
      else
        die "Homebrew not found. Install gh manually: https://cli.github.com/"
      fi
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        say "Installing GitHub CLI via apt..."
        # Official GitHub CLI apt source (https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
        type -p curl >/dev/null || sudo apt-get install -y curl
        sudo mkdir -p -m 755 /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
          | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
          | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update
        sudo apt-get install -y gh
      elif command -v dnf >/dev/null 2>&1; then
        say "Installing GitHub CLI via dnf..."
        sudo dnf install -y 'dnf-command(config-manager)'
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo dnf install -y gh
      elif command -v pacman >/dev/null 2>&1; then
        say "Installing GitHub CLI via pacman..."
        sudo pacman -S --noconfirm github-cli
      else
        die "No supported package manager (apt/dnf/pacman). Install gh manually: https://cli.github.com/"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      die "On Windows Git-Bash, install gh via winget first: winget install GitHub.cli"
      ;;
    *)
      die "Unsupported OS: $os. Install gh manually: https://cli.github.com/"
      ;;
  esac
fi

command -v gh >/dev/null 2>&1 || die "gh still not found after install attempt."
ok "gh CLI ready ($(gh --version | head -n 1))"

# 2. Ensure gh is authenticated
if ! gh auth status >/dev/null 2>&1; then
  say "GitHub login required. Follow the prompts (GitHub.com -> HTTPS -> browser login)."
  gh auth login
fi
gh auth setup-git >/dev/null 2>&1 || true
ok "GitHub auth ready"

# 3. Fetch install.sh from the private repo and run it
say "Fetching skills installer from private repo..."
INSTALLER="$(gh api "repos/$PRIVATE_REPO/contents/$INSTALLER_PATH" -H "Accept: application/vnd.github.raw")" \
  || die "Failed to fetch $INSTALLER_PATH from $PRIVATE_REPO. Check that your gh account has access."

bash -c "$INSTALLER"
