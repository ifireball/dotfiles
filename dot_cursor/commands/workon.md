---
description: Open an existing ~/src clone or confirm-then-clone; move agent workspace to repo
argument-hint: "[repo URL or owner/repo]"
allowed-tools: [Read, Shell, CallMcpTool, AskQuestion]
---

# Work on repo in ~/src

The user invoked this command with: $ARGUMENTS

Follow skill **src-mirror-layout**.

## Steps

1. Run `~/.cursor/skills/src-mirror-layout/scripts/resolve-repo.sh "$ARGUMENTS"` and parse JSON.
2. If `exists` is true: **`move_agent_to_root`** to `path` immediately; run `git status -sb`. **Do not clone.**
3. If `exists` is false:
   - Tell the user the repo is not local; show `upstream_url` and `path`.
   - **Ask for explicit confirmation** before cloning (use AskQuestion when available).
   - If declined: stop.
   - If confirmed: `ghq get <upstream_url>`; verify; **`move_agent_to_root`**; `git remote -v`.
4. Do not fork unless the user also runs `/fork`.
