#!/usr/bin/env bash
# Build and run second-machine verification for src-mirror (chezmoi + ghq in container).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_SOURCE="$(cd "${SCRIPT_DIR}/../.." && pwd)"
IMAGE_TAG="src-mirror-verify:local"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"

container_engine() {
  if command -v podman >/dev/null 2>&1; then
    echo podman
  elif command -v docker >/dev/null 2>&1; then
    echo docker
  else
    echo "Neither podman nor docker found" >&2
    exit 1
  fi
}

ENGINE="$(container_engine)"

echo "Building ${IMAGE_TAG} with ${ENGINE}..."
"${ENGINE}" build -t "${IMAGE_TAG}" -f "${DOCKERFILE}" "${SCRIPT_DIR}"

echo "Running container verification..."
# :Z relabels the mount for container SELinux (Fedora host).
"${ENGINE}" run --rm \
  -v "${CHEZMOI_SOURCE}:/chezmoi-source:ro,Z" \
  "${IMAGE_TAG}" \
  -lc '
    set -euo pipefail
    export HOME=/home/testuser
    mkdir -p "$HOME/src"
    git config --global user.email "test@example.com"
    git config --global user.name "test"
    mkdir -p "$HOME/src" "$HOME/.config/chezmoi"
    cat > "$HOME/.config/chezmoi/chezmoi.toml" <<'CHEZMOI'
sourceDir = "/chezmoi-source"

[script]
command = "true"
CHEZMOI
    # Skip .gitconfig in container (dot_gitconfig hardcodes host paths).
    chezmoi apply --force .cursor .config/ghq
    git config --global ghq.root "$HOME/src"
    chezmoi apply --force .cursor .config/ghq
    exec "$HOME/.cursor/skills/src-mirror-layout/scripts/verify-src-mirror.sh" --container-inner
  '

echo "Container verification passed."
