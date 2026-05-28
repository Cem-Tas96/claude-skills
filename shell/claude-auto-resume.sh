# shellcheck shell=bash
# Claude Code — Auto-Resume Wrapper
# ---------------------------------------------------------------------------
# Verhalten: Wenn du `claude` interaktiv aufrufst und mit `/exit` raus gehst,
# startet automatisch `claude -c` (= continue last session). Endlos, bis du
# während des 2-Sekunden-Fensters Ctrl-C drückst.
#
# Loop greift NUR bei interaktiven Chat-Aufrufen:
#   - `claude`                (kein Arg)
#   - `claude -c`             (continue)
#   - `claude --continue`
#   - `claude --resume [id]`
# Alles andere (--help, --version, -p, config, mcp, install, ...) läuft normal
# einmal durch ohne Auto-Resume.
#
# Bypass für einen einzelnen Aufruf:  CLAUDE_NO_AUTO_RESUME=1 claude
# Komplett ausschalten:               in ~/.zshrc die source-Zeile rauskommentieren

claude() {
  # Non-interaktiv (Pipe / Script / nicht-TTY) → kein Wrapping
  if ! { [ -t 0 ] && [ -t 1 ] && [ -t 2 ]; }; then
    command claude "$@"
    return
  fi

  # Explizit deaktiviert
  if [ -n "${CLAUDE_NO_AUTO_RESUME:-}" ]; then
    command claude "$@"
    return
  fi

  # Loop nur bei interaktiven Chat-Aufrufen.
  local interactive=0
  case "${1:-}" in
    ""|-c|--continue|--resume) interactive=1 ;;
  esac

  if [ "$interactive" != "1" ]; then
    command claude "$@"
    return
  fi

  local first=1 rc
  while true; do
    if [ "$first" = "1" ]; then
      command claude "$@"
      first=0
    else
      command claude -c
    fi
    rc=$?

    # Non-zero exit → Fehler, keine Endlos-Loop
    if [ "$rc" -ne 0 ]; then
      return "$rc"
    fi

    # 2-Sekunden-Window: Ctrl-C → endgültig raus
    printf '\n\033[36m[claude]\033[0m /exit erkannt — auto-resume in 2s (Ctrl-C zum endgültig raus)…\n'
    sleep 2 || return 0
  done
}
