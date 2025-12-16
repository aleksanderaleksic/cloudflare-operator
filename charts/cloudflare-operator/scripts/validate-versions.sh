#!/bin/bash

# Script to validate version consistency across chart components
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

echo "Validating version consistency..."

# Read Chart.yaml
CHART_VERSION=$(grep "^version:" "$CHART_DIR/Chart.yaml" | awk '{print $2}')
APP_VERSION=$(grep "^appVersion:" "$CHART_DIR/Chart.yaml" | awk '{print $2}' | tr -d '"')

echo "Chart version: $CHART_VERSION"
echo "App version: $APP_VERSION"

# Validate Chart.yaml has required version fields
if [ -z "$CHART_VERSION" ]; then
    echo "✗ Chart version not found in Chart.yaml"
    exit 1
fi

if [ -z "$APP_VERSION" ]; then
    echo "✗ App version not found in Chart.yaml"
    exit 1
fi

echo "✓ Version fields found in Chart.yaml"

# Validate version format (semantic versioning)
validate_semver() {
    local version="$1"
    local name="$2"
    
    if [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$ ]]; then
        echo "✓ $name follows semantic versioning: $version"
    elif [[ $version == "latest" ]]; then
        echo "ℹ️  $name uses 'latest' tag: $version"
    else
        echo "⚠️  $name may not follow semantic versioning: $version"
    fi
}

validate_semver "$CHART_VERSION" "Chart version"
validate_semver "$APP_VERSION" "App version"

# Test templating with different version scenarios
echo ""
echo "Testing version templating scenarios..."

# Test 1: Default behavior (should use appVersion)
echo "1. Testing default image tag (should use appVersion)..."
OUTPUT=$(helm template test "$CHART_DIR" --set image.tag="" 2>/dev/null)
if echo "$OUTPUT" | grep -q "image: ghcr.io/adyanth/cloudflare-operator:$APP_VERSION"; then
    echo "✓ Default image tag uses appVersion correctly"
else
    echo "✗ Default image tag does not use appVersion"
    exit 1
fi

# Test 2: Custom tag override
echo "2. Testing custom image tag override..."
CUSTOM_TAG="v1.2.3"
OUTPUT=$(helm template test "$CHART_DIR" --set image.tag="$CUSTOM_TAG" 2>/dev/null)
if echo "$OUTPUT" | grep -q "image: ghcr.io/adyanth/cloudflare-operator:$CUSTOM_TAG"; then
    echo "✓ Custom image tag override works correctly"
else
    echo "✗ Custom image tag override failed"
    exit 1
fi

# Test 3: Empty appVersion should fail
echo "3. Testing empty appVersion validation..."
TEMP_CHART=$(mktemp -d)
cp -r "$CHART_DIR"/* "$TEMP_CHART/"
sed -i.bak 's/^appVersion:.*/appVersion: ""/' "$TEMP_CHART/Chart.yaml"

if helm template test "$TEMP_CHART" --set image.tag="" 2>/dev/null; then
    echo "✗ Empty appVersion should have failed validation"
    rm -rf "$TEMP_CHART"
    exit 1
else
    echo "✓ Empty appVersion correctly fails validation"
fi
rm -rf "$TEMP_CHART"

# Validate version references in templates
echo ""
echo "Checking version references in templates..."

# Check if any templates hardcode versions
HARDCODED_VERSIONS=$(grep -r "v[0-9]\+\.[0-9]\+\.[0-9]\+" "$CHART_DIR/templates/" || true)
if [ -n "$HARDCODED_VERSIONS" ]; then
    echo "⚠️  Found potential hardcoded versions in templates:"
    echo "$HARDCODED_VERSIONS"
    echo "Consider using template variables instead"
else
    echo "✓ No hardcoded versions found in templates"
fi

# Check for consistent labeling
echo ""
echo "Validating version labels..."
OUTPUT=$(helm template test "$CHART_DIR" 2>/dev/null)
VERSION_LABELS=$(echo "$OUTPUT" | grep "app.kubernetes.io/version" | head -5)
if [ -n "$VERSION_LABELS" ]; then
    echo "✓ Version labels found in generated resources:"
    echo "$VERSION_LABELS" | sed 's/^/  /'
else
    echo "⚠️  No version labels found in generated resources"
fi

echo ""
echo "✅ Version consistency validation completed!"