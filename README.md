# Claude Code Restart Command

Private helper for a Claude Code `/restart` slash command that restarts the
current Claude Code process and resumes the same session when possible.

## What It Installs

- `~/.local/bin/claude-restart`
  - Single script handling both the slash-command path and `UserPromptSubmit`
    hook fast path (dispatched via `--hook`).
  - Finds the current Claude Code process in the parent process chain.
  - Looks up the session id from `~/.claude/sessions/<pid>.json`.
  - Writes a PID-scoped restart marker.
  - Terminates Claude so the shell wrapper can relaunch it.
- `~/.claude/commands/restart.md`
  - Fallback slash command implementation.
- `~/.claude/claude-restart-wrapper.zsh`
  - Defines `claude()` wrapper function.
  - Relaunches `claude --resume <session_id>` when the restart marker asks for it.

## Install

```sh
git clone git@github.com:Loukas922/claude-code-restart-command.git
cd claude-code-restart-command
./install.zsh
source ~/.zshrc
```

Start Claude Code through the wrapper:

```sh
claude
```

## Behavior

- If the current session id is known, `/restart` resumes that same session.
- If the session is still empty and no session id exists, `/restart` starts fresh.
- The hook only intercepts `/restart` — a bare `restart` is passed through to
  the model as a normal prompt.

## Debugging

Set `CLAUDE_RESTART_LOG` to enable hook tracing:

```sh
export CLAUDE_RESTART_LOG=/tmp/claude-restart.log
```

## Notes

- macOS and zsh are assumed.
- `jq` is optional but recommended for the fast prompt hook.
- If Claude Code is already running from an older shell that did not source the
  wrapper, start a new shell or run `source ~/.zshrc` before launching `claude`.
