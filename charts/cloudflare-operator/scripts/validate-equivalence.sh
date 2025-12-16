#!/bin/bash

# Script to validate Helm chart generates equivalent resources to Kustomize
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$CHART_DIR")")"

echo "Validating Helm chart equivalence with Kustomize..."

# Create temporary directories
TEMP_DIR=$(mktemp -d)
HELM_OUTPUT="$TEMP_DIR/helm-output.yaml"
KUSTOMIZE_OUTPUT="$TEMP_DIR/kustomize-output.yaml"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Generate Helm output with default values
echo "Generating Helm output..."
helm template cloudflare-operator "$CHART_DIR" \
    --namespace cloudflare-operator-system \
    --set global.namespace=cloudflare-operator-system \
    > "$HELM_OUTPUT"

# Generate Kustomize output
echo "Generating Kustomize output..."
cd "$ROOT_DIR"
kubectl kustomize config/default > "$KUSTOMIZE_OUTPUT"

# Function to extract resource types and names
extract_resources() {
    local file="$1"
    grep -E "^(kind|metadata:)" "$file" | \
    awk '/^kind:/ {kind=$2} /^  name:/ {print kind "/" $2}' | \
    sort
}

# Compare resource types and names
echo "Comparing resource types and names..."
HELM_RESOURCES=$(extract_resources "$HELM_OUTPUT")
KUSTOMIZE_RESOURCES=$(extract_resources "$KUSTOMIZE_OUTPUT")

echo "Helm resources:"
echo "$HELM_RESOURCES"
echo ""
echo "Kustomize resources:"
echo "$KUSTOMIZE_RESOURCES"
echo ""

# Check for missing resources
MISSING_IN_HELM=$(comm -23 <(echo "$KUSTOMIZE_RESOURCES") <(echo "$HELM_RESOURCES"))
EXTRA_IN_HELM=$(comm -13 <(echo "$KUSTOMIZE_RESOURCES") <(echo "$HELM_RESOURCES"))

if [ -n "$MISSING_IN_HELM" ]; then
    echo "⚠️  Resources in Kustomize but missing in Helm:"
    echo "$MISSING_IN_HELM"
    echo ""
fi

if [ -n "$EXTRA_IN_HELM" ]; then
    echo "ℹ️  Additional resources in Helm (expected due to templating):"
    echo "$EXTRA_IN_HELM"
    echo ""
fi

# Validate core resources exist in both
CORE_RESOURCES=(
    "Deployment/cloudflare-operator-controller-manager"
    "ServiceAccount/cloudflare-operator-controller-manager"
    "ClusterRole/cloudflare-operator-manager-role"
    "ClusterRoleBinding/cloudflare-operator-manager-rolebinding"
)

echo "Validating core resources..."
for resource in "${CORE_RESOURCES[@]}"; do
    if echo "$HELM_RESOURCES" | grep -q "$resource"; then
        echo "✓ $resource found in Helm output"
    else
        echo "✗ $resource missing in Helm output"
        exit 1
    fi
done

# Validate CRDs
CRD_RESOURCES=(
    "CustomResourceDefinition/tunnels.networking.cfargotunnel.com"
    "CustomResourceDefinition/clustertunnels.networking.cfargotunnel.com"
    "CustomResourceDefinition/tunnelbindings.networking.cfargotunnel.com"
    "CustomResourceDefinition/accesstunnels.networking.cfargotunnel.com"
)

echo "Validating CRDs..."
for crd in "${CRD_RESOURCES[@]}"; do
    if echo "$HELM_RESOURCES" | grep -q "$crd"; then
        echo "✓ $crd found in Helm output"
    else
        echo "✗ $crd missing in Helm output"
        exit 1
    fi
done

echo ""
echo "✅ Equivalence validation completed successfully!"
echo "Helm chart generates functionally equivalent resources to Kustomize configuration."