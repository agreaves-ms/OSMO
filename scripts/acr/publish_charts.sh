#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  cat <<'USAGE'
Usage: scripts/acr/publish_charts.sh <acr-name>

Example:
  scripts/acr/publish_charts.sh acrosmorobotics001
USAGE
  exit 1
fi

ACR_NAME="$1"
REGISTRY_FQDN="${ACR_NAME}.azurecr.io"
OCI_PREFIX="oci://${REGISTRY_FQDN}/helm"
CHART_ROOT="deployments/charts"
# Package individual charts first, then umbrella charts with dependencies
CHARTS=(service router backend-operator web-ui)

for tool in az helm; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool" >&2
    exit 1
  fi
done

if ! az account show >/dev/null 2>&1; then
  echo "Run 'az login' before invoking this script." >&2
  exit 1
fi

echo "Authenticating to ${REGISTRY_FQDN}..."
ACR_TOKEN=$(az acr login --name "$ACR_NAME" --expose-token --output tsv --query accessToken)

# Use stdin to pass password securely
export HELM_EXPERIMENTAL_OCI=1
echo "$ACR_TOKEN" | helm registry login "$REGISTRY_FQDN" \
  --username 00000000-0000-0000-0000-000000000000 \
  --password-stdin

# Add common Helm repositories that charts might depend on
echo "Adding required Helm repositories..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update

for chart in "${CHARTS[@]}"; do
  CHART_DIR="${CHART_ROOT}/${chart}"
  if [ ! -d "$CHART_DIR" ]; then
    echo "Skipping missing chart directory: $CHART_DIR" >&2
    continue
  fi

  echo "Packaging ${chart} chart..."
  pushd "$CHART_DIR" >/dev/null

  # Clean up previous dist directory
  rm -rf dist/

  # Build dependencies (this will fetch and vendor them into charts/)
  if [ -f "Chart.yaml" ] && grep -q "^dependencies:" Chart.yaml; then
    echo "  Building dependencies for ${chart}..."
    helm dependency build
  fi

  mkdir -p dist
  helm package . --destination dist
  PACKAGE_FILE=$(find dist -maxdepth 1 -type f -name '*.tgz' | head -n1)
  if [ -z "$PACKAGE_FILE" ]; then
    echo "Failed to locate packaged chart for ${chart}" >&2
    exit 1
  fi
  echo "Pushing ${PACKAGE_FILE} to ${OCI_PREFIX}/${chart}..."
  helm push "$PACKAGE_FILE" "${OCI_PREFIX}"
  popd >/dev/null
done

echo "All charts pushed to ${OCI_PREFIX}."
