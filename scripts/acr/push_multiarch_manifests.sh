#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OSMO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Push multi-architecture manifests to ACR
# Run acr_docker_config_setup.sh first to set up Docker authentication

if [ "$#" -lt 2 ]; then
  cat <<'USAGE'
Usage: scripts/acr/push_multiarch_manifests.sh <acr-name> <image-tag> [image-names...]

Example:
  # Push all image manifests
  scripts/acr/push_multiarch_manifests.sh acrosmorobotics001 v2025.11.20

  # Push only specific image manifests
  scripts/acr/push_multiarch_manifests.sh acrosmorobotics001 v2025.11.20 agent service worker

Prerequisites:
  1. Run acr_docker_config_setup.sh first:
     ./scripts/acr/acr_docker_config_setup.sh acrosmorobotics001

  2. Ensure both amd64 and arm64 images are already pushed to ACR
USAGE
  exit 1
fi

ACR_NAME="$1"
IMAGE_TAG="$2"
shift 2

REGISTRY_FQDN="${ACR_NAME}.azurecr.io"
REGISTRY_PATH="${REGISTRY_FQDN}/osmo"
DOCKER_CONFIG_DIR="$(pwd)/.cache/docker"

# Default image names if none provided
DEFAULT_IMAGE_NAMES=(
  agent
  service
  delayed-job-monitor
  logger
  router
  worker
  backend-listener
  backend-worker
  web-ui
  init-container
  client
)

# Use provided image names or defaults
if [ $# -gt 0 ]; then
  IMAGE_NAMES=("$@")
else
  IMAGE_NAMES=("${DEFAULT_IMAGE_NAMES[@]}")
fi

# Verify docker config exists
if [ ! -f "$DOCKER_CONFIG_DIR/config.json" ]; then
  echo "Docker config not found. Run acr_docker_config_setup.sh first:" >&2
  echo "  ./scripts/acr/acr_docker_config_setup.sh $ACR_NAME" >&2
  exit 1
fi

# Clear manifest cache to ensure fresh pulls from registry
# Docker caches manifest references locally, which can cause stale manifests
# to be pushed even when new images exist in the registry
echo "Clearing Docker manifest cache to ensure fresh registry pulls..."
rm -rf "$DOCKER_CONFIG_DIR/manifests" ~/.docker/manifests 2>/dev/null || true

echo "Creating multi-architecture manifests for ${#IMAGE_NAMES[@]} images..."
echo "  Registry: ${REGISTRY_PATH}"
echo "  Tag: ${IMAGE_TAG}"
echo "  Images: ${IMAGE_NAMES[*]}"
echo ""

DOCKER_CONFIG="${DOCKER_CONFIG_DIR}"
export DOCKER_CONFIG

cd "${OSMO_ROOT}"

bazel run @osmo_workspace//run:push_multiarch_manifests -- \
  --registry_path "$REGISTRY_PATH" \
  --tag "$IMAGE_TAG" \
  --amend \
  --images "${IMAGE_NAMES[@]}"

echo ""
echo "Multi-arch manifests pushed to ${REGISTRY_PATH} with tag ${IMAGE_TAG}."
