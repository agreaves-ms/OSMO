#!/usr/bin/env bash
set -euo pipefail

# Build and push arm64 images
# Run this script INSIDE the arm64 builder container (after start_arm64_builder.sh)

# Image targets - comment out or set SKIP_<name>=1 to skip specific images
SKIP_AGENT=${SKIP_AGENT:-}
SKIP_SERVICE=${SKIP_SERVICE:-}
SKIP_DELAYED_JOB_MONITOR=${SKIP_DELAYED_JOB_MONITOR:-}
SKIP_LOGGER=${SKIP_LOGGER:-}
SKIP_ROUTER=${SKIP_ROUTER:-}
SKIP_WORKER=${SKIP_WORKER:-}
SKIP_BACKEND_LISTENER=${SKIP_BACKEND_LISTENER:-}
SKIP_BACKEND_WORKER=${SKIP_BACKEND_WORKER:-}
SKIP_WEB_UI=${SKIP_WEB_UI:-}
SKIP_INIT=${SKIP_INIT:-}
SKIP_CLI=${SKIP_CLI:-}

targets=()

[ -n "$SKIP_AGENT" ] || targets+=("@osmo_workspace//src/service/agent:agent_service_push_arm64")
[ -n "$SKIP_SERVICE" ] || targets+=("@osmo_workspace//src/service/core:service_push_arm64")
[ -n "$SKIP_DELAYED_JOB_MONITOR" ] || targets+=("@osmo_workspace//src/service/delayed_job_monitor:delayed_job_monitor_push_arm64")
[ -n "$SKIP_LOGGER" ] || targets+=("@osmo_workspace//src/service/logger:logger_push_arm64")
[ -n "$SKIP_ROUTER" ] || targets+=("@osmo_workspace//src/service/router:router_push_arm64")
[ -n "$SKIP_WORKER" ] || targets+=("@osmo_workspace//src/service/worker:worker_push_arm64")
[ -n "$SKIP_BACKEND_LISTENER" ] || targets+=("@osmo_workspace//src/operator:backend_listener_push_arm64")
[ -n "$SKIP_BACKEND_WORKER" ] || targets+=("@osmo_workspace//src/operator:backend_worker_push_arm64")
[ -n "$SKIP_WEB_UI" ] || targets+=("@osmo_workspace//ui:web_ui_push_arm64")
[ -n "$SKIP_INIT" ] || targets+=("@osmo_workspace//src/runtime:init_push_arm64")
[ -n "$SKIP_CLI" ] || targets+=("@osmo_workspace//src/cli:cli_push_arm64")

if [ ${#targets[@]} -eq 0 ]; then
  echo "All targets skipped. Nothing to build."
  exit 0
fi

echo "Building and pushing ${#targets[@]} arm64 images..."
echo ""

for target in "${targets[@]}"; do
  echo "==> Building: ${target}"
  bazel run "${target}"
  echo ""
done

echo "All arm64 images built and pushed successfully."
