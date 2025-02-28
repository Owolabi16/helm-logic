#!/bin/bash

set -e  # Exit script if any command fails

echo "🔄 Updating Helm dependencies per chart..."

# Ensure the script runs in the correct directory
if [[ ! -f "Chart.yaml" ]]; then
    echo "❌ Error: Chart.yaml not found! Ensure the script is running in the correct directory."
    echo "📂 Current directory: $(pwd)"
    echo "📋 Listing files:"
    ls -lah
    exit 1
fi

# Read dependencies from Chart.yaml
CHARTS=$(yq eval '.dependencies[] | .name + " " + .version + " " + .repository' Chart.yaml)

FAILING_CHARTS=()

while IFS= read -r chart_info; do
    CHART_NAME=$(echo "$chart_info" | awk '{print $1}')
    CHART_VERSION=$(echo "$chart_info" | awk '{print $2}')
    CHART_REPO=$(echo "$chart_info" | awk '{print $3}')
    
    if [[ -z "$CHART_NAME" || -z "$CHART_VERSION" || -z "$CHART_REPO" ]]; then
        echo "⚠️ Skipping invalid entry: $chart_info"
        continue
    fi

    echo "🔄 Updating dependency: $CHART_NAME (Version: $CHART_VERSION) from $CHART_REPO"

    # Add Helm repo if not already added
    if ! helm repo list | grep -q "$CHART_REPO"; then
        if ! helm repo add temp-repo "$CHART_REPO" >/dev/null 2>&1; then
            echo "🚨 Failed to add repo for $CHART_NAME"
            FAILING_CHARTS+=("$CHART_NAME")
            continue
        fi
    fi

    # Fetch dependency
    if ! helm fetch temp-repo/$CHART_NAME --version $CHART_VERSION >/dev/null 2>&1; then
        echo "🚨 Failed to update dependency: $CHART_NAME (Version: $CHART_VERSION)"
        FAILING_CHARTS+=("$CHART_NAME")
    else
        echo "✅ Successfully updated: $CHART_NAME (Version: $CHART_VERSION)"
    fi

done <<< "$CHARTS"

# Display failing dependencies
if [[ ${#FAILING_CHARTS[@]} -gt 0 ]]; then
    echo "🚨 The following dependencies failed to update: ${FAILING_CHARTS[*]}"
    exit 1
else
    echo "✅ All dependencies updated successfully!"
fi
