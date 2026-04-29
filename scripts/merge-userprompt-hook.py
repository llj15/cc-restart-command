#!/usr/bin/env python3

import json
import sys
from pathlib import Path

STALE_SUFFIXES = ("claude-restart-prompt-hook", "claude-restart-current")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: merge-userprompt-hook.py SETTINGS_JSON HOOK_COMMAND", file=sys.stderr)
        return 2

    settings_path = Path(sys.argv[1]).expanduser()
    hook_command = str(Path(sys.argv[2]).expanduser())
    hook = {"type": "command", "command": hook_command}

    if settings_path.exists():
        data = json.loads(settings_path.read_text())
    else:
        data = {}

    hooks = data.setdefault("hooks", {})
    user_prompt = hooks.setdefault("UserPromptSubmit", [])
    if not user_prompt:
        user_prompt.append({"hooks": []})

    first = user_prompt[0]
    first_hooks = first.setdefault("hooks", [])

    first_hooks[:] = [
        h for h in first_hooks
        if not (
            isinstance(h, dict)
            and isinstance(h.get("command"), str)
            and (
                h["command"] == hook_command
                or h["command"].rstrip().endswith(STALE_SUFFIXES)
            )
        )
    ]
    first_hooks.insert(0, hook)

    settings_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
