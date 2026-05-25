# src-mirror reference

## Input normalization

| Input | Upstream URL | Path under `~/src` |
|-------|--------------|-------------------|
| `konflux-ci/project-controller` | `https://github.com/konflux-ci/project-controller` | `github.com/konflux-ci/project-controller` |
| `https://github.com/org/repo` | (as given) | `github.com/org/repo` |
| `github.com/org/repo` | `https://github.com/org/repo` | `github.com/org/repo` |
| `gitlab.cee.redhat.com/konflux/infra` | `https://gitlab.cee.redhat.com/konflux/infra` | `gitlab.cee.redhat.com/konflux/infra` |

`resolve-repo.sh --discover-upstream` uses `gh api` to map a fork slug to its parent for **path** derivation only; the clone still lives under the upstream path.

## GitLab forks

`gh repo fork` does not apply. After cloning the canonical repo with `ghq get`:

```bash
git remote rename origin upstream   # if origin points at canonical
git remote add origin https://gitlab.cee.redhat.com/<your-namespace>/...
```

## Edge cases

- **Nested repos** under a parent (e.g. `stable-diffusion-webui/repositories/...`) are submodules/nested clones — not top-level `~/src` mirror paths.
- **Worktrees** (`.cursor/worktrees/`) are for isolated branches; long-lived clones stay in `~/src`.
- **Ambiguous `ghq list -e`**: script exits non-zero if multiple matches; disambiguate with full host path or URL.

## User rules fragment

Paste `~/.cursor/user-rules/src-mirror.txt` into **Cursor Settings → Rules for AI** (not auto-synced).

## Container / second machine

From chezmoi source root:

```bash
scripts/src-mirror-verify/run-container-verify.sh
```
