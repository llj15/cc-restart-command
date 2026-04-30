#!/usr/bin/env zsh

set -uo pipefail

claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
bin_dir="$HOME/.local/bin"
zshrc="$HOME/.zshrc"

removed=0

# -- remove files -------------------------------------------------------------

remove_file() {
  local f=$1
  if [[ -f "$f" ]]; then
    rm -f "$f"
    print "  Removed ${f/$HOME/~}"
    (( removed++ ))
  fi
}

print "Removing Claude Code /restart support..."
print ""

remove_file "$bin_dir/claude-restart"
remove_file "$claude_dir/commands/restart.md"
remove_file "$claude_dir/claude-restart-wrapper.zsh"

# stale files from older installs
remove_file "$bin_dir/claude-restart-current"
remove_file "$bin_dir/claude-restart-prompt-hook"

# -- remove zshrc source line ------------------------------------------------

if [[ -f "$zshrc" ]] && grep -q 'claude-restart-wrapper.zsh' "$zshrc" 2>/dev/null; then
  sed -i '' '/claude-restart-wrapper\.zsh/d' "$zshrc"
  sed -i '' '/# Claude Code \/restart support/d' "$zshrc"
  # remove trailing blank lines left behind
  while [[ -f "$zshrc" ]] && [[ "$(tail -c 2 "$zshrc")" == $'\n\n' ]]; do
    sed -i '' '$ { /^$/d; }' "$zshrc"
  done
  print "  Cleaned ~/.zshrc"
  (( removed++ ))
fi

# -- remove hook from settings.json ------------------------------------------

remove_hook() {
  local f=$1
  [[ -f "$f" ]] || return 0
  command -v python3 >/dev/null 2>&1 || return 0

  python3 -c '
import json, sys
p = sys.argv[1]
try:
    data = json.loads(open(p).read())
except Exception:
    sys.exit(0)

hooks = data.get("hooks", {})
upt = hooks.get("UserPromptSubmit", [])
changed = False
for entry in upt:
    hs = entry.get("hooks", [])
    new_hs = [h for h in hs if not (isinstance(h, dict) and isinstance(h.get("command"), str) and "claude-restart" in h["command"])]
    if len(new_hs) != len(hs):
        entry["hooks"] = new_hs
        changed = True

if not changed:
    sys.exit(0)

# remove empty hook entries
upt[:] = [e for e in upt if e.get("hooks")]
if not upt:
    del hooks["UserPromptSubmit"]
if not hooks:
    del data["hooks"]

open(p, "w").write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
' "$f" && print "  Removed hook from ${f/$HOME/~}" && (( removed++ ))
}

remove_hook "$claude_dir/settings.json"
remove_hook "$claude_dir/settings.json.api-mode"
remove_hook "$claude_dir/settings.json.enterprise-mode"

# -- summary ------------------------------------------------------------------

print ""
if (( removed > 0 )); then
  print "Uninstalled ($removed items removed)."
  print "Run: source ~/.zshrc"
else
  print "Nothing to remove — not installed."
fi
