#!/usr/bin/env zsh

set -euo pipefail

repo_dir="${0:A:h}"
claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
bin_dir="$HOME/.local/bin"
zshrc="$HOME/.zshrc"
wrapper="$claude_dir/claude-restart-wrapper.zsh"
hook_command="$bin_dir/claude-restart --hook"

dry_run=0
[[ "${1:-}" == "--dry-run" ]] && dry_run=1

# -- preflight ---------------------------------------------------------------

preflight() {
  local ok=1

  if [[ "${SHELL##*/}" != "zsh" ]]; then
    print -P "%F{yellow}Warning:%f Default shell is $SHELL, not zsh."
    print "  The wrapper defines a zsh function; it will not work in other shells."
    if (( dry_run )); then
      ok=0
    else
      print -n "Continue anyway? [y/N] "
      read -r reply
      case "$reply" in
        y|Y|yes|YES) ;;
        *) return 1 ;;
      esac
    fi
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    print -P "%F{red}Error:%f python3 not found. It is needed to merge the settings.json hook."
    return 1
  fi

  return 0
}

# -- preview ------------------------------------------------------------------

preview() {
  local tag

  print ""
  print "The following changes will be made:"
  print ""

  tag="new"
  [[ -f "$bin_dir/claude-restart" ]] && tag="overwrite (backup)"
  print "  [file]  ~/.local/bin/claude-restart  ($tag)"

  tag="new"
  [[ -f "$claude_dir/commands/restart.md" ]] && tag="overwrite (backup)"
  print "  [file]  ~/.claude/commands/restart.md  ($tag)"

  tag="new"
  [[ -f "$wrapper" ]] && tag="overwrite (backup)"
  print "  [file]  ~/.claude/claude-restart-wrapper.zsh  ($tag)"

  if [[ -f "$zshrc" ]] && grep -q 'claude-restart-wrapper.zsh' "$zshrc" 2>/dev/null; then
    print "  [shell] ~/.zshrc  (already has source line, skip)"
  elif [[ -f "$zshrc" ]]; then
    print "  [shell] ~/.zshrc  (append source line)"
  else
    print "  [shell] ~/.zshrc  (create + append source line)"
  fi

  typeset -ga settings_files=()
  for settings in \
    "$claude_dir/settings.json" \
    "$claude_dir/settings.json.api-mode" \
    "$claude_dir/settings.json.enterprise-mode"
  do
    [[ -f "$settings" ]] && settings_files+=("$settings")
  done

  if (( $#settings_files > 0 )); then
    for f in $settings_files; do
      print "  [hook]  ${f/$HOME/~}  (register UserPromptSubmit hook, backup)"
    done
  else
    print "  [hook]  ~/.claude/settings.json  (create with UserPromptSubmit hook)"
  fi

  print ""
}

# -- confirm ------------------------------------------------------------------

confirm() {
  if [[ -n "${CLAUDE_RESTART_INSTALL_YES:-}" ]]; then
    return 0
  fi
  print -n "Proceed with all changes? [y/N] "
  read -r reply
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# -- backup + install ---------------------------------------------------------

backup_if_exists() {
  local target=$1 ts=$2
  if [[ -f "$target" ]]; then
    # remove old backups, keep only the new one
    rm -f "${target}".bak.* 2>/dev/null
    cp -p "$target" "${target}.bak.${ts}"
    print "  Backed up: ${target/$HOME/~}"
  fi
}

do_install() {
  local ts
  ts=$(date +%Y%m%d-%H%M%S)

  mkdir -p "$bin_dir" "$claude_dir/commands"

  # core files
  backup_if_exists "$bin_dir/claude-restart" "$ts"
  backup_if_exists "$claude_dir/commands/restart.md" "$ts"
  backup_if_exists "$wrapper" "$ts"

  install -m 755 "$repo_dir/current/bin/claude-restart" "$bin_dir/claude-restart"
  install -m 644 "$repo_dir/current/commands/restart.md" "$claude_dir/commands/restart.md"
  install -m 644 "$repo_dir/current/claude-restart-wrapper.zsh" "$wrapper"
  print "  Installed 3 files."

  # zshrc
  if [[ ! -f "$zshrc" ]]; then
    : > "$zshrc"
  fi
  if ! grep -q 'claude-restart-wrapper.zsh' "$zshrc" 2>/dev/null; then
    {
      print ''
      print '# Claude Code /restart support'
      print '[[ -r "$HOME/.claude/claude-restart-wrapper.zsh" ]] && source "$HOME/.claude/claude-restart-wrapper.zsh"'
    } >> "$zshrc"
    print "  Updated ~/.zshrc."
  else
    print "  ~/.zshrc already configured, skipped."
  fi

  # settings.json hook
  if (( $#settings_files == 0 )); then
    settings_files=("$claude_dir/settings.json")
  fi
  for f in $settings_files; do
    backup_if_exists "$f" "$ts"
    python3 "$repo_dir/scripts/merge-userprompt-hook.py" "$f" "$hook_command"
    print "  Registered hook in ${f/$HOME/~}."
  done

  # clean up stale binaries from previous two-script installs
  for stale in "$bin_dir/claude-restart-current" "$bin_dir/claude-restart-prompt-hook"; do
    [[ -f "$stale" ]] && rm -f "$stale" && print "  Removed stale: ${stale/$HOME/~}"
  done
}

# -- main ---------------------------------------------------------------------

preflight || exit 1
preview

if (( dry_run )); then
  print "Dry run complete. No changes were made."
  exit 0
fi

confirm || {
  print "Aborted. No changes were made."
  exit 1
}

print ""
do_install

print ""
print "Done. Next steps:"
print "  source ~/.zshrc"
print "  cc"
