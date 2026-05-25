---
name: src-mirror-layout
description: >-
  Resolves and clones git repositories under $HOME/src using URL-mirror paths via
  ghq (host/org/repo). Use before cloning, checking out, forking, locating source,
  github.com, gitlab.cee.redhat.com, ~/src, ghq, or when using /clone, /workon, /fork.
---

# src-mirror layout

## Layout

All clones live under `$HOME/src/<host>/<path-after-host>/` (ghq default). Example:

- `https://github.com/konflux-ci/project-controller` → `~/src/github.com/konflux-ci/project-controller`

## GitHub shorthand

Bare `owner/repo` means `https://github.com/owner/repo` (same as `ghq get owner/repo`). Only use an explicit host for non-GitHub (e.g. `gitlab.cee.redhat.com/konflux/infra`).

**Always parse via script** — do not reimplement URL logic:

```bash
~/.cursor/skills/src-mirror-layout/scripts/resolve-repo.sh '<ref>'
```

## Resolve workflow (mandatory)

1. Run `resolve-repo.sh` on the repo reference.
2. If `exists` is true: use `path`; optional `ghq get -u <upstream_url>` to sync.
3. If false: `ghq get <upstream_url>` or `ghq get <ghq_slug>` — **never** `-p` (SSH).
4. Never `git clone` into cwd, `/tmp`, or a fork-shaped path under `~/src/github.com/ifireball/...` for upstream work.

## Fork workflow

Forks are **remotes**, not separate directories.

**GitHub** (after clone at upstream path):

```bash
cd "$(resolve-repo.sh owner/repo | jq -r .path)"
gh repo fork <upstream-slug> --remote
```

Result: `upstream` = canonical, `origin` = your fork (`ifireball/...`). HTTPS only.

**GitLab:** when you have a personal fork, set `upstream` = canonical HTTPS and `origin` = fork HTTPS. See [reference.md](reference.md).

## Cursor workspace

After resolving or cloning, call MCP `move_agent_to_root` with the resolved `path` instead of cloning into an empty agent workspace.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/resolve-repo.sh` | Normalize ref → JSON (`path`, `exists`, `upstream_url`, `ghq_slug`) |
| `scripts/ensure-fork-remotes.sh` | GitHub: `gh repo fork --remote` in existing clone |
| `scripts/verify-src-mirror.sh` | Automated tests (`--host`, `--container`, `--all`) |

## Verification

```bash
~/.cursor/skills/src-mirror-layout/scripts/verify-src-mirror.sh --all
```

See [reference.md](reference.md) for edge cases and GitLab details.
