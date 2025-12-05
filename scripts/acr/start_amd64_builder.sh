#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OSMO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DOCKER_CONFIG_DIR="$(pwd)/.cache/docker"

cd "${OSMO_ROOT}"

bazel run --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 @osmo_workspace//run:builder_image_load_x86_64

docker run \
  --platform "linux/amd64" \
  --rm -it \
  -v "${OSMO_ROOT}":/workspace -w /workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${DOCKER_CONFIG_DIR}:/root/.docker:ro" \
  osmo-builder:latest-amd64

