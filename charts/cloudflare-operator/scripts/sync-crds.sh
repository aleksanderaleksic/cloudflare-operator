#!/bin/bash

# Script to sync CRDs from config/crd/bases to Helm chart templates
# This ensures the Helm chart always has the latest CRD definitions
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$CHART_DIR")")"
CRD_SOURCE_DIR="$ROOT_DIR/config/crd/bases"
CRD_DEST_DIR="$CHART_DIR/templates/crds"

echo "🔄 Syncing CRDs from config/crd/bases to Helm chart templates..."

# Check if source directory exists
if [ ! -d "$CRD_SOURCE_DIR" ]; then
    echo "❌ Error: Source CRD directory not found: $CRD_SOURCE_DIR"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$CRD_DEST_DIR"

# Process each CRD file
for source_file in "$CRD_SOURCE_DIR"/*.yaml; do
    if [ ! -f "$source_file" ]; then
        echo "⚠️  No CRD files found in $CRD_SOURCE_DIR"
        exit 0
    fi
    
    # Extract the CRD name from the filename
    filename=$(basename "$source_file")
    # Convert filename from networking.cfargotunnel.com_tunnels.yaml to tunnels.yaml
    dest_filename=$(echo "$filename" | sed 's/networking\.cfargotunnel\.com_//')
    dest_file="$CRD_DEST_DIR/$dest_filename"
    
    echo "  📄 Processing $filename -> $dest_filename"
    
    # Create the Helm-templated version
    {
        # Add Helm conditional wrapper
        echo "{{- if .Values.features.crds.install }}"
        
        # Read the source CRD and add Helm templating to metadata
        awk '
        BEGIN { in_metadata = 0; in_annotations = 0; annotations_done = 0; }
        
        # Print document separator
        /^---$/ { print; next }
        
        # Detect metadata section
        /^metadata:$/ {
            in_metadata = 1
            print
            next
        }
        
        # Detect annotations section within metadata
        in_metadata && /^  annotations:$/ {
            in_annotations = 1
            print
            next
        }
        
        # After annotations, add Helm includes
        in_annotations && /^  [a-z]/ && !annotations_done {
            print "    {{- include \"cloudflare-operator.certManager.caInjection\" . | nindent 4 }}"
            print "    {{- include \"cloudflare-operator.annotations\" . | nindent 4 }}"
            in_annotations = 0
            annotations_done = 1
        }
        
        # If no annotations section, add after metadata opening
        in_metadata && /^  [a-z]/ && annotations_done == 0 {
            print "  annotations:"
            print "    {{- include \"cloudflare-operator.certManager.caInjection\" . | nindent 4 }}"
            print "    {{- include \"cloudflare-operator.annotations\" . | nindent 4 }}"
            annotations_done = 1
        }
        
        # Add labels after annotations
        in_metadata && annotations_done == 1 && /^  name:/ {
            print "  labels:"
            print "    {{- include \"cloudflare-operator.labels\" . | nindent 4 }}"
            annotations_done = 2
        }
        
        # Print all other lines
        { print }
        
        # Exit metadata section when we see spec:
        /^spec:$/ { in_metadata = 0 }
        ' "$source_file"
        
        # Add closing conditional
        echo "{{- end }}"
    } > "$dest_file"
    
    echo "  ✅ Synced to $dest_file"
done

echo ""
echo "✅ CRD sync completed successfully!"
echo ""
echo "Synced files:"
for file in "$CRD_DEST_DIR"/*.yaml; do
    if [ -f "$file" ]; then
        echo "  - $(basename "$file")"
    fi
done
