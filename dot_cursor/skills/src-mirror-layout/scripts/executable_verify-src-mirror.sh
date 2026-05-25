#!/usr/bin/env bash
# Automated verification for src-mirror layout (host and container).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVE="${SCRIPT_DIR}/resolve-repo.sh"
PASS=0
FAIL=0
SKIP=0

usage() {
  cat <<'EOF'
Usage: verify-src-mirror.sh [--host|--container|--container-inner|--all] [--live-clone] [--use-real-src]

  --host             Run host tests (default)
  --container        Build/run container second-machine tests
  --container-inner  In-container tests only (called by run-container-verify.sh)
  --all              Host + container
  --live-clone       Run ghq get octocat/Hello-World in isolated GHQ_ROOT
  --use-real-src     Use real ~/src for H3/H9 instead of skipping when missing
EOF
}

log_pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
log_fail() { echo "FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
log_skip() { echo "SKIP: $*"; SKIP=$((SKIP + 1)); }

json_field() {
  local json="$1" field="$2"
  printf '%s' "$json" | sed -n "s/.*\"${field}\":\"\([^\"]*\)\".*/\1/p" | head -1
}

json_bool() {
  local json="$1" field="$2"
  if printf '%s' "$json" | grep -q "\"${field}\":true"; then
    return 0
  fi
  return 1
}

assert_eq() {
  local got="$1" want="$2" msg="$3"
  if [[ "$got" == "$want" ]]; then
    log_pass "$msg"
  else
    log_fail "$msg (got '$got', want '$want')"
  fi
}

require_cmd() {
  local c="$1"
  if command -v "$c" >/dev/null 2>&1; then
    return 0
  fi
  log_fail "required command not found: $c"
  return 1
}

run_host_tests() {
  echo "=== Host tests ==="
  require_cmd ghq || return
  require_cmd git || return
  [[ -x "$RESOLVE" ]] || { log_fail "resolve-repo.sh not executable: $RESOLVE"; return; }

  # H1 GitHub shorthand
  local j
  j="$("$RESOLVE" konflux-ci/project-controller)"
  assert_eq "$(json_field "$j" upstream_url)" "https://github.com/konflux-ci/project-controller" "H1 upstream_url GitHub shorthand"
  assert_eq "$(json_field "$j" host)" "github.com" "H1 host github.com"

  # H2 GitLab explicit
  j="$("$RESOLVE" gitlab.cee.redhat.com/konflux/infra)"
  assert_eq "$(json_field "$j" upstream_url)" "https://gitlab.cee.redhat.com/konflux/infra" "H2 GitLab upstream_url"
  assert_eq "$(json_field "$j" host)" "gitlab.cee.redhat.com" "H2 GitLab host"

  # H4 missing repo
  j="$("$RESOLVE" "fake-org/fake-repo-$$")"
  if json_bool "$j" exists; then
    log_fail "H4 fake repo should not exist"
  else
    log_pass "H4 fake repo exists=false"
  fi
  assert_eq "$(json_field "$j" upstream_url)" "https://github.com/fake-org/fake-repo-$$" "H4 fake upstream URL"

  # H6 ghq root
  local root want_root
  root="$(ghq root)"
  want_root="$(git config --global --get ghq.root 2>/dev/null || echo "${HOME}/src")"
  assert_eq "$root" "$want_root" "H6 ghq root matches git config"

  # H7 chezmoi-applied files
  local home="${HOME}"
  for f in \
    "${home}/.cursor/commands/clone.md" \
    "${home}/.cursor/commands/fork.md" \
    "${home}/.cursor/commands/workon.md" \
    "${home}/.cursor/skills/src-mirror-layout/SKILL.md" \
    "${home}/.cursor/skills/clone-into-src/SKILL.md" \
    "${home}/.config/ghq/config.yml"; do
    if [[ -f "$f" ]]; then
      log_pass "H7 exists: $f"
    else
      log_fail "H7 missing: $f"
    fi
  done

  # H8 command frontmatter
  for cmd in clone fork workon; do
    if grep -q '^description:' "${home}/.cursor/commands/${cmd}.md" 2>/dev/null && \
       grep -qE 'resolve-repo|src-mirror' "${home}/.cursor/commands/${cmd}.md" 2>/dev/null; then
      log_pass "H8 command ${cmd}.md frontmatter"
    else
      log_fail "H8 command ${cmd}.md missing description or skill ref"
    fi
  done

  # H3 existing clone
  local use_real=false
  [[ "${USE_REAL_SRC:-}" == "1" ]] && use_real=true
  j="$("$RESOLVE" konflux-ci/project-controller)"
  if json_bool "$j" exists; then
    local p
    p="$(json_field "$j" path)"
    if [[ -d "${p}/.git" ]]; then
      log_pass "H3 konflux-ci/project-controller exists with .git"
    else
      log_fail "H3 path missing .git: $p"
    fi
  elif $use_real; then
    log_fail "H3 expected konflux-ci/project-controller locally"
  else
    log_skip "H3 konflux-ci/project-controller not cloned (use --use-real-src to require)"
  fi

  # H9 fork remotes read-only
  local pc="${home}/src/github.com/konflux-ci/project-controller"
  if [[ -d "${pc}/.git" ]]; then
    local ou uu
    ou="$(git -C "$pc" remote get-url origin 2>/dev/null || true)"
    uu="$(git -C "$pc" remote get-url upstream 2>/dev/null || true)"
    if [[ "$ou" == *ifireball* ]] && [[ "$uu" == *konflux-ci* ]]; then
      log_pass "H9 project-controller fork remotes"
    else
      log_fail "H9 remotes (origin=$ou upstream=$uu)"
    fi
  else
    log_skip "H9 project-controller not present"
  fi

  # H10 live clone in temp GHQ_ROOT
  if [[ "${LIVE_CLONE:-}" == "1" ]]; then
    local tmp
    tmp="$(mktemp -d)"
    (
      export GIT_CONFIG_GLOBAL="${tmp}/gitconfig"
      git config --global ghq.root "$tmp/src"
      mkdir -p "$tmp/src"
      ghq get https://github.com/octocat/Hello-World
      if [[ -d "$tmp/src/github.com/octocat/Hello-World/.git" ]]; then
        echo "H10 clone ok"
      else
        echo "H10 clone failed" >&2
        exit 1
      fi
      ghq get https://github.com/octocat/Hello-World
      count="$(find "$tmp/src/github.com/octocat" -name .git -type d | wc -l)"
      [[ "$count" -eq 1 ]] || { echo "H10 duplicate clones"; exit 1; }
      ghq rm https://github.com/octocat/Hello-World 2>/dev/null || rm -rf "$tmp/src/github.com/octocat/Hello-World"
    ) && log_pass "H10 live clone in temp GHQ_ROOT" || log_fail "H10 live clone"
    rm -rf "$tmp"
  else
    log_skip "H10 live clone (use --live-clone)"
  fi
}

run_container_inner_tests() {
  echo "=== Container inner tests ==="
  require_cmd ghq || return
  require_cmd chezmoi || return
  [[ -x "$RESOLVE" ]] || { log_fail "resolve-repo.sh missing"; return; }

  local home="${HOME}"
  for f in \
    "${home}/.cursor/commands/clone.md" \
    "${home}/.config/ghq/config.yml"; do
    [[ -f "$f" ]] && log_pass "C0 exists $f" || log_fail "C0 missing $f"
  done

  local j
  j="$("$RESOLVE" konflux-ci/project-controller)"
  assert_eq "$(json_field "$j" upstream_url)" "https://github.com/konflux-ci/project-controller" "C-H1 GitHub shorthand"
  if json_bool "$j" exists; then
    log_fail "C fresh home should not have konflux-ci/project-controller"
  else
    log_pass "C-H4 not exists on fresh home"
  fi

  root="$(ghq root)"
  want_root="$(git config --global --get ghq.root 2>/dev/null || echo "${home}/src")"
  if [[ "$root" == "$want_root" ]]; then
    log_pass "C-H6 ghq root matches git config ($root)"
  else
    log_fail "C-H6 ghq root (got $root, want $want_root)"
  fi

  log_skip "C1 chezmoi idempotent (verified in container entry script)"

  if ghq get octocat/Hello-World; then
    if [[ -d "${home}/src/github.com/octocat/Hello-World/.git" ]]; then
      log_pass "C2 ghq get shorthand clone"
    else
      log_fail "C2 clone path missing"
    fi
    ghq get octocat/Hello-World
    if [[ "$(find "${home}/src/github.com/octocat" -name .git -type d | wc -l)" -eq 1 ]]; then
      log_pass "C3 idempotent ghq get"
    else
      log_fail "C3 duplicate clone dirs"
    fi
    ghq rm octocat/Hello-World 2>/dev/null || rm -rf "${home}/src/github.com/octocat/Hello-World"
  else
    log_fail "C2 ghq get (network?)"
  fi
}

MODE="host"
LIVE_CLONE=""
USE_REAL_SRC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) MODE="host" ;;
    --container) MODE="container" ;;
    --container-inner) MODE="container-inner" ;;
    --all) MODE="all" ;;
    --live-clone) LIVE_CLONE=1 ;;
    --use-real-src) USE_REAL_SRC=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

case "$MODE" in
  host) run_host_tests ;;
  container-inner) run_container_inner_tests ;;
  container)
    CHEZMOI_SOURCE="${CHEZMOI_SOURCE:-${HOME}/.local/share/chezmoi}"
    RUNNER="${CHEZMOI_SOURCE}/scripts/src-mirror-verify/run-container-verify.sh"
    if [[ -x "$RUNNER" ]]; then
      exec "$RUNNER"
    else
      log_fail "container runner not found: $RUNNER"
    fi
    ;;
  all)
    run_host_tests
    CHEZMOI_SOURCE="${CHEZMOI_SOURCE:-${HOME}/.local/share/chezmoi}"
    if [[ -x "${CHEZMOI_SOURCE}/scripts/src-mirror-verify/run-container-verify.sh" ]]; then
      "${CHEZMOI_SOURCE}/scripts/src-mirror-verify/run-container-verify.sh" || FAIL=$((FAIL + 1))
    else
      log_skip "container runner missing"
    fi
    ;;
esac

echo ""
echo "=== Summary: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped ==="
[[ "$FAIL" -eq 0 ]]
