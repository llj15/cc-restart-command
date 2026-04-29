#!/usr/bin/env zsh

set -euo pipefail

repo_dir="${0:A:h}"
claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
bin_dir="$HOME/.local/bin"
zshrc="$HOME/.zshrc"
wrapper="$claude_dir/claude-restart-wrapper.zsh"

mkdir -p "$bin_dir" "$claude_dir/commands"

install -m 755 "$repo_dir/current/bin/claude-restart-current" "$bin_dir/claude-restart-current"
install -m 755 "$repo_dir/current/bin/claude-restart-prompt-hook" "$bin_dir/claude-restart-prompt-hook"
install -m 644 "$repo_dir/current/commands/restart.md" "$claude_dir/commands/restart.md"
install -m 644 "$repo_dir/current/claude-restart-wrapper.zsh" "$wrapper"

if [[ ! -f "$zshrc" ]]; then
  : > "$zshrc"
fi

if ! grep -q 'claude-restart-wrapper.zsh' "$zshrc" 2>/dev/null; then
  {
    print ''
    print '# Claude Code /restart support'
    print '[[ -r "$HOME/.claude/claude-restart-wrapper.zsh" ]] && source "$HOME/.claude/claude-restart-wrapper.zsh"'
  } >> "$zshrc"
fi

for settings in \
  "$claude_dir/settings.json" \
  "$claude_dir/settings.json.api-mode" \
  "$claude_dir/settings.json.enterprise-mode"
do
  if [[ -f "$settings" ]]; then
    python3 "$repo_dir/scripts/merge-userprompt-hook.py" \
      "$settings" \
      "$bin_dir/claude-restart-prompt-hook"
  fi
done

print "Installed Claude Code /restart support."
print "Run: source ~/.zshrc"
print "Then start Claude Code with: cc"
