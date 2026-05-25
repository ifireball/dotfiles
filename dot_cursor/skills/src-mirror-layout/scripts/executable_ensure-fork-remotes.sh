#!/usr/bin/env bash
# Ensure GitHub fork remotes: upstream = canonical, origin = personal fork (ifireball).
# Usage: ensure-fork-remotes.sh <repo-path> [upstream-slug]
set -euo pipefail

REPO_PATH="${1:?repo path required}"
UPSTREAM_SLUG="${2:-}"

if [[ ! -d "${REPO_PATH}/.git" ]]; then
  echo "Not a git repository: ${REPO_PATH}" >&2
  exit 1
fi

cd "$REPO_PATH"

if [[ -z "$UPSTREAM_SLUG" ]]; then
  origin_url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "$origin_url" ]]; then
    echo "No origin remote; pass upstream slug as second argument" >&2
    exit 1
  fi
  # Derive owner/repo from HTTPS URL
  if [[ "$origin_url" =~ github\.com[:/]([^/]+)/([^/]+) ]]; then
    UPSTREAM_SLUG="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    UPSTREAM_SLUG="${UPSTREAM_SLUG%.git}"
  else
    echo "Cannot derive upstream slug from origin URL: ${origin_url}" >&2
    exit 1
  fi
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI required for ensure-fork-remotes" >&2
  exit 1
fi

# If upstream already set, verify; else fork adds remotes
if git remote get-url upstream >/dev/null 2>&1; then
  echo "upstream already configured"
  git remote -v
  exit 0
fi

gh repo fork "$UPSTREAM_SLUG" --remote
git remote -v
