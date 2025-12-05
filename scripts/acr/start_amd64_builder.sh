#!/usr/bin/env bash
set -euo pipefail

DOCKER_CONFIG_DIR=".cache/docker"

bazel run --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 @osmo_workspace//run:builder_image_load_x86_64

docker run \
  --platform "linux/amd64" \
  --rm -it \
  -v "$(pwd)":/workspace -w /workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)/$DOCKER_CONFIG_DIR:/root/.docker:ro" \
  osmo-builder:latest-amd64

