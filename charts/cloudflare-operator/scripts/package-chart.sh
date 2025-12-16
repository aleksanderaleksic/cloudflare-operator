#!/bin/bash

# Script to package and validate Helm chart
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$CHART_DIR")")"

echo "Packaging and validating Helm chart..."

# Create output directory
OUTPUT_DIR="$ROOT_DIR/dist"
mkdir -p "$OUTPUT_DIR"

# Step 1: Lint the chart
echo "1. Linting chart..."
helm lint "$CHART_DIR"
echo "✓ Chart linting passed"

# Step 2: Run chart tests
echo "2. Running chart tests..."
"$SCRIPT_DIR/test-chart.sh"
echo "✓ Chart tests passed"

# Step 3: Run version validation
echo "3. Validating versions..."
"$SCRIPT_DIR/validate-versions.sh"
echo "✓ Version validation passed"

# Step 4: Template validation
echo "4. Validating template generation..."
TEMP_OUTPUT=$(mktemp)
helm template cloudflare-operator "$CHART_DIR" > "$TEMP_OUTPUT"

# Check for required resources
REQUIRED_RESOURCES=(
    "kind: Deployment"
    "kind: ServiceAccount"
    "kind: ClusterRole"
    "kind: ClusterRoleBinding"
    "kind: CustomResourceDefinition"
)

for resource in "${REQUIRED_RESOURCES[@]}"; do
    if grep -q "$resource" "$TEMP_OUTPUT"; then
        echo "✓ Found $resource in template output"
    else
        echo "✗ Missing $resource in template output"
        rm -f "$TEMP_OUTPUT"
        exit 1
    fi
done

rm -f "$TEMP_OUTPUT"
echo "✓ Template validation passed"

# Step 5: Package the chart
echo "5. Packaging chart..."
CHART_VERSION=$(grep "^version:" "$CHART_DIR/Chart.yaml" | awk '{print $2}')
PACKAGE_NAME="cloudflare-operator-${CHART_VERSION}.tgz"

helm package "$CHART_DIR" --destination "$OUTPUT_DIR"
echo "✓ Chart packaged as $OUTPUT_DIR/$PACKAGE_NAME"

# Step 6: Verify package
echo "6. Verifying package..."
if [ -f "$OUTPUT_DIR/$PACKAGE_NAME" ]; then
    echo "✓ Package file exists"
    
    # Extract and verify contents
    TEMP_DIR=$(mktemp -d)
    tar -xzf "$OUTPUT_DIR/$PACKAGE_NAME" -C "$TEMP_DIR"
    
    if [ -f "$TEMP_DIR/cloudflare-operator/Chart.yaml" ]; then
        echo "✓ Package contains Chart.yaml"
    else
        echo "✗ Package missing Chart.yaml"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    if [ -f "$TEMP_DIR/cloudflare-operator/values.yaml" ]; then
        echo "✓ Package contains values.yaml"
    else
        echo "✗ Package missing values.yaml"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    TEMPLATE_COUNT=$(find "$TEMP_DIR/cloudflare-operator/templates" -name "*.yaml" | wc -l)
    if [ "$TEMPLATE_COUNT" -gt 10 ]; then
        echo "✓ Package contains $TEMPLATE_COUNT template files"
    else
        echo "✗ Package contains insufficient template files ($TEMPLATE_COUNT)"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    rm -rf "$TEMP_DIR"
else
    echo "✗ Package file not created"
    exit 1
fi

# Step 7: Test installation from package (optional)
echo "7. Testing package installation (dry-run)..."
if kubectl cluster-info > /dev/null 2>&1; then
    helm install test-release "$OUTPUT_DIR/$PACKAGE_NAME" --dry-run > /dev/null
    echo "✓ Package installation test passed"
else
    echo "ℹ️  Skipping installation test (no Kubernetes cluster available)"
fi

# Step 8: Generate package info
echo "8. Generating package information..."
PACKAGE_SIZE=$(du -h "$OUTPUT_DIR/$PACKAGE_NAME" | cut -f1)
PACKAGE_SHA256=$(shasum -a 256 "$OUTPUT_DIR/$PACKAGE_NAME" | cut -d' ' -f1)

cat > "$OUTPUT_DIR/package-info.txt" << EOF
Cloudflare Operator Helm Chart Package Information
================================================

Package: $PACKAGE_NAME
Version: $CHART_VERSION
Size: $PACKAGE_SIZE
SHA256: $PACKAGE_SHA256
Created: $(date)

Installation:
  helm install cloudflare-operator $PACKAGE_NAME

Verification:
  echo "$PACKAGE_SHA256  $PACKAGE_NAME" | shasum -a 256 -c
EOF

echo "✓ Package information saved to $OUTPUT_DIR/package-info.txt"

echo ""
echo "✅ Chart packaging and validation completed successfully!"
echo "📦 Package: $OUTPUT_DIR/$PACKAGE_NAME"
echo "📄 Info: $OUTPUT_DIR/package-info.txt"
echo ""
echo "To install the packaged chart:"
echo "  helm install cloudflare-operator $OUTPUT_DIR/$PACKAGE_NAME"