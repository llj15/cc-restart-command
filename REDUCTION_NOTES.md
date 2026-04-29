# Reduction Notes

The current implementation is intentionally explicit:

- shell wrapper: relaunches Claude after the old process exits
- restart helper: finds and terminates the current Claude process
- prompt hook: fast path that bypasses model thinking and passes the exact session id
- slash command: fallback entry point

## Can It Be Only `restart.md`?

No, not if the goal is "restart in the same terminal and resume the same session".

A slash command runs in a child shell below Claude Code. That child can signal the
Claude parent, but once Claude exits there must be another process still alive to
start a new Claude process. The child process is not a reliable supervisor for the
terminal session, and a detached child would fight terminal ownership or open a
separate session. The stable supervisor is the parent shell wrapper.

`restart.md` alone can kill Claude, but it cannot reliably relaunch Claude in the
same terminal after Claude exits.

## What Can Be Reduced?

### 1. Merge the two bin scripts

`claude-restart-current` and `claude-restart-prompt-hook` can be one script:

- If stdin contains a `UserPromptSubmit` hook JSON with `/restart`, use its
  `session_id` and suppress continuation.
- Otherwise behave like the slash command helper.

This reduces installed bin files from 2 to 1.

### 2. Keep the wrapper, but source it as one file

The wrapper cannot disappear, but it can remain as a single sourced file:

- `~/.claude/claude-restart-wrapper.zsh`
- one line in `~/.zshrc`

Inlining it directly into `.zshrc` reduces one runtime file but makes updates and
uninstall harder. Keeping the sourced file is cleaner.

### 3. Keep the hook optional, but recommended

Without the `UserPromptSubmit` hook:

- `/restart` goes through the normal slash command path, so the model may think
  for a few seconds.
- Exact current session id is less reliable; the helper must use `lsof` or a
  recent transcript heuristic.

With the hook:

- prompt `/restart` is intercepted before model processing
- hook JSON provides the exact `session_id`

So the hook is not strictly required to restart, but it is required for the best
UX and most reliable same-session resume.

## Minimal Recommended Runtime

The practical minimum is:

1. `~/.local/bin/claude-restart`
2. `~/.claude/commands/restart.md`
3. `~/.claude/claude-restart-wrapper.zsh`
4. one `source` line in `~/.zshrc`
5. optional but recommended `UserPromptSubmit` settings entry

That means the implementation can be reduced by one script file, but not to only
the slash command.

## Suggested Next Refactor

Create a `minimal/` implementation with:

- `minimal/bin/claude-restart`
- `minimal/commands/restart.md`
- `minimal/claude-restart-wrapper.zsh`
- installer that points both the hook and slash command at the single script

After testing, make `minimal/` the default install path and keep `current/` as the
historical explicit version.
