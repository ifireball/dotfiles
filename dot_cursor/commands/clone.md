---
description: Clone or sync a repo into ~/src via ghq (upstream HTTPS path), then move agent workspace
argument-hint: "[repo URL or owner/repo]"
allowed-tools: [Read, Shell, CallMcpTool]
---

# Clone into ~/src

The user invoked this command with: $ARGUMENTS

Follow skills **src-mirror-layout** and **clone-into-src**.

## Steps

1. Run `~/.cursor/skills/src-mirror-layout/scripts/resolve-repo.sh "$ARGUMENTS"` and parse JSON.
2. If `exists` is true: report `path`; optional `ghq get -u <upstream_url>`; then **`move_agent_to_root`** to `path`.
3. If `exists` is false: `ghq get <upstream_url>` (never `-p`); verify directory; **`move_agent_to_root`** to `path`.
4. Print `git remote -v` (expect `origin` → upstream until `/fork` is run).

Do not ask for confirmation — `/clone` is explicit clone intent.
