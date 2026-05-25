---
description: Add GitHub fork remotes (origin=fork, upstream=canonical) in existing ~/src clone
argument-hint: "[owner/repo or repo path]"
allowed-tools: [Read, Shell]
---

# Fork remotes (not a second clone)

The user invoked this command with: $ARGUMENTS

Follow skill **src-mirror-layout**.

## Steps

1. Resolve repo: if `$ARGUMENTS` is set, run `resolve-repo.sh "$ARGUMENTS"`; else use git cwd if under `~/src`.
2. Require clone under `$HOME/src` with `.git`.
3. **GitHub:** `cd <path>` then `gh repo fork <upstream-slug> --remote` (or `ensure-fork-remotes.sh <path> <slug>`).
4. **GitLab** (personal fork exists): set `upstream` = canonical HTTPS, `origin` = fork HTTPS per reference.md.
5. Verify `git remote -v`. Do **not** create `~/src/github.com/ifireball/...` for upstream repos.
