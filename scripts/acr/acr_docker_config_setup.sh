#!/usr/bin/env bash
set -euo pipefail

ACR_NAME="$1"
DOCKER_CONFIG_DIR=".cache/docker"
REGISTRY_FQDN="${ACR_NAME}.azurecr.io"

setup_acr_auth() {
  echo "Setting up ACR authentication for ${REGISTRY_FQDN}..."
  local token
  token=$(az acr login --name "$ACR_NAME" --expose-token --output tsv --query accessToken)

  mkdir -p "$DOCKER_CONFIG_DIR"
  cat > "$DOCKER_CONFIG_DIR/config.json" <<EOF
{
  "auths": {
    "${REGISTRY_FQDN}": {
      "auth": "$(echo -n "00000000-0000-0000-0000-000000000000:${token}" | base64)"
    }
  }
}
EOF
}

setup_acr_auth
