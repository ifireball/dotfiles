#!/usr/bin/env bash
# Resolve a repository reference to ~/src mirror path and upstream HTTPS URL.
# Usage: resolve-repo.sh [--discover-upstream] <url|owner/repo|host/path>
set -euo pipefail

DISCOVER_UPSTREAM=false
if [[ "${1:-}" == "--discover-upstream" ]]; then
  DISCOVER_UPSTREAM=true
  shift
fi

if [[ $# -lt 1 ]] || [[ -z "${1:-}" ]]; then
  echo "Usage: $(basename "$0") [--discover-upstream] <url|owner/repo|host/path>" >&2
  exit 2
fi

raw_input="$1"
raw_input="${raw_input%.git}"
raw_input="${raw_input%/}"

# shellcheck disable=SC2034
KNOWN_HOSTS=(github.com gitlab.cee.redhat.com)

is_known_host() {
  local h="$1"
  local k
  for k in "${KNOWN_HOSTS[@]}"; do
    [[ "$h" == "$k" ]] && return 0
  done
  return 1
}

looks_like_host() {
  local seg="$1"
  [[ "$seg" == *.* ]] && is_known_host "$seg"
}

# Outputs: host, path_after_host, ghq_slug (for ghq list -e)
normalize() {
  local input="$1"
  local host="" path="" slug=""

  if [[ "$input" =~ ^git@([^:]+):(.+)$ ]]; then
    host="${BASH_REMATCH[1]}"
    path="${BASH_REMATCH[2]}"
    path="${path%.git}"
  elif [[ "$input" =~ ^https?://([^/]+)/(.+)$ ]]; then
    host="${BASH_REMATCH[1]}"
    path="${BASH_REMATCH[2]}"
  elif [[ "$input" == */* ]]; then
    local first="${input%%/*}"
    local rest="${input#*/}"
    if looks_like_host "$first"; then
      host="$first"
      path="$rest"
    else
      host="github.com"
      path="$input"
    fi
  else
    echo "Invalid repository reference: $input" >&2
    return 1
  fi

  path="${path%/}"
  path="${path%.git}"

  if [[ "$host" == "github.com" ]]; then
    slug="$path"
  else
    slug="${host}/${path}"
  fi

  printf '%s\n%s\n%s\n' "$host" "$path" "$slug"
}

mapfile -t parts < <(normalize "$raw_input") || exit 1
host="${parts[0]}"
path_after_host="${parts[1]}"
ghq_slug="${parts[2]}"

upstream_url="https://${host}/${path_after_host}"

# Optional: resolve fork slug to upstream for path derivation
if [[ "$DISCOVER_UPSTREAM" == true ]] && [[ "$host" == "github.com" ]] && command -v gh >/dev/null 2>&1; then
  owner="${path_after_host%%/*}"
  repo="${path_after_host#*/}"
  if [[ "$owner" != "$path_after_host" ]] && [[ -n "$repo" ]]; then
    parent="$(gh api "repos/${owner}/${repo}" --jq '.parent.full_name // empty' 2>/dev/null || true)"
    if [[ -n "$parent" ]]; then
      path_after_host="$parent"
      ghq_slug="$parent"
      upstream_url="https://github.com/${parent}"
    fi
  fi
fi

rel_path="${host}/${path_after_host}"
ghq_root="$(ghq root 2>/dev/null || git config --global --get ghq.root || echo "${HOME}/src")"
expected_path="${ghq_root}/${rel_path}"

# ghq list -e for canonical match
list_paths=()
while IFS= read -r line; do
  [[ -n "$line" ]] && list_paths+=("$line")
done < <(ghq list -e "$ghq_slug" -p 2>/dev/null || true)

if [[ ${#list_paths[@]} -gt 1 ]]; then
  echo "Ambiguous: multiple ghq matches for '${ghq_slug}':" >&2
  printf '  %s\n' "${list_paths[@]}" >&2
  exit 1
fi

exists=false
resolved_path="$expected_path"

if [[ ${#list_paths[@]} -eq 1 ]]; then
  resolved_path="${list_paths[0]}"
  if [[ "$resolved_path" != /* ]]; then
    resolved_path="${ghq_root}/${resolved_path}"
  fi
  if [[ -d "${resolved_path}/.git" ]]; then
    exists=true
  fi
elif [[ -d "${expected_path}/.git" ]]; then
  resolved_path="$expected_path"
  exists=true
fi

# JSON output (jq-free for container minimal env)
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

printf '{'
printf '"upstream_url":"%s",' "$(json_escape "$upstream_url")"
printf '"ghq_slug":"%s",' "$(json_escape "$ghq_slug")"
printf '"host":"%s",' "$(json_escape "$host")"
printf '"rel_path":"%s",' "$(json_escape "$rel_path")"
printf '"path":"%s",' "$(json_escape "$resolved_path")"
printf '"exists":%s' "$([[ "$exists" == true ]] && echo true || echo false)"
printf '}\n'
