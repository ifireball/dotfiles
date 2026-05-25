---
name: clone-into-src
description: >-
  Checklist for cloning or syncing a repository into ~/src via ghq using the
  upstream HTTPS path. Use when the user asks to clone, get, or checkout a repo,
  or when /clone is invoked.
disable-model-invocation: true
---

# Clone into ~/src

Follow [src-mirror-layout](../src-mirror-layout/SKILL.md) for all path and remote rules.

## Checklist

- [ ] Run `~/.cursor/skills/src-mirror-layout/scripts/resolve-repo.sh '<ref>'`
- [ ] If `exists` is true: report `path`; optional `ghq get -u <upstream_url>`; skip clone
- [ ] If false: `ghq get <upstream_url>` (HTTPS only; never `ghq get -p`)
- [ ] Verify: directory under `$HOME/src/<host>/...` and `git remote -v`
- [ ] If fork needed: run `gh repo fork <upstream> --remote` from repo dir (GitHub) or see reference for GitLab
- [ ] `move_agent_to_root` to resolved `path` when working in Cursor

## Do not

- `git clone` into the agent workspace or `/tmp`
- Clone `ifireball/foo` into `~/src/github.com/ifireball/foo` when upstream is `other/foo`
