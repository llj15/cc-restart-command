# Claude Code Restart Command

Private helper for a Claude Code `/restart` slash command that restarts the
current Claude Code process and resumes the same session when possible.

## What It Installs

- `~/.local/bin/claude-restart-current`
  - Finds the current Claude Code process in the parent process chain.
  - Writes a PID-scoped restart marker.
  - Terminates Claude so the shell wrapper can relaunch it.
- `~/.local/bin/claude-restart-prompt-hook`
  - Optional fast path for `UserPromptSubmit`.
  - Intercepts an exact `/restart` or `restart` prompt before the model thinks.
- `~/.claude/commands/restart.md`
  - Fallback slash command implementation.
- `~/.claude/claude-restart-wrapper.zsh`
  - Defines `claude()` and `cc`.
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
cc
```

## Behavior

- If the current session id is known, `/restart` resumes that same session.
- If the session is still empty and no session id exists, `/restart` starts fresh.
- It will not fall back to an old "latest" session unless the transcript was
  updated very recently.

## Notes

- macOS and zsh are assumed.
- `jq` is optional but recommended for the fast prompt hook.
- If Claude Code is already running from an older shell that did not source the
  wrapper, start a new shell or run `source ~/.zshrc` before launching `cc`.
