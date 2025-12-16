#!/bin/bash

# Script to test Helm chart functionality
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

echo "Testing Helm chart functionality..."

# Test 1: Lint the chart
echo "1. Linting chart..."
helm lint "$CHART_DIR"
echo "✓ Chart linting passed"

# Test 2: Template with default values
echo "2. Templating with default values..."
helm template cloudflare-operator "$CHART_DIR" > /dev/null
echo "✓ Default templating passed"

# Test 3: Template with webhooks disabled
echo "3. Templating with webhooks disabled..."
helm template cloudflare-operator "$CHART_DIR" \
    --set features.webhooks.enabled=false \
    --set features.certManager.enabled=false > /dev/null
echo "✓ Webhooks disabled templating passed"

# Test 4: Template with metrics disabled
echo "4. Templating with metrics disabled..."
helm template cloudflare-operator "$CHART_DIR" \
    --set features.metrics.enabled=false > /dev/null
echo "✓ Metrics disabled templating passed"

# Test 5: Template with RBAC disabled (should fail validation)
echo "5. Testing RBAC validation..."
if helm template cloudflare-operator "$CHART_DIR" \
    --set features.rbac.create=false \
    --set features.crds.install=true 2>/dev/null; then
    echo "✗ RBAC validation failed - should have failed"
    exit 1
else
    echo "✓ RBAC validation passed - correctly failed"
fi

# Test 6: Template with custom image
echo "6. Templating with custom image..."
helm template cloudflare-operator "$CHART_DIR" \
    --set image.repository=custom/cloudflare-operator \
    --set image.tag=v1.0.0 > /dev/null
echo "✓ Custom image templating passed"

# Test 7: Template with network policies enabled
echo "7. Templating with network policies enabled..."
helm template cloudflare-operator "$CHART_DIR" \
    --set features.networkPolicy.enabled=true > /dev/null
echo "✓ Network policies templating passed"

echo ""
echo "✅ All chart tests passed successfully!"