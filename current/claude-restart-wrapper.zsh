# Claude Code /restart support.
#
# Source this file from ~/.zshrc and start Claude through `cc` or `claude`.

alias cc="claude code"

claude() {
  local restart_dir="${TMPDIR:-/tmp}/claude-code-restart"
  local restart_flag="${restart_dir}/$$.restart"
  local code marker sid
  local -a original_args
  original_args=("$@")

  mkdir -p "$restart_dir" 2>/dev/null
  rm -f "$restart_flag" 2>/dev/null

  while true; do
    CLAUDE_RESTART_FLAG="$restart_flag" command claude "$@"
    code=$?

    [[ -f "$restart_flag" ]] || return "$code"

    marker=$(sed -n '1p' "$restart_flag" 2>/dev/null)
    rm -f "$restart_flag" 2>/dev/null
    case "$marker" in
      resume:*)
        sid="${marker#resume:}"
        [[ -n "$sid" ]] || return "$code"
        set -- --resume "$sid"
        ;;
      fresh)
        set -- "${original_args[@]}"
        ;;
      *)
        return "$code"
        ;;
    esac
  done
}
