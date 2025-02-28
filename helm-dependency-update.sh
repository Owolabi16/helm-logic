#!/bin/bash

set -e  # Exit script if any command fails

echo "🔄 Updating Helm dependencies per chart..."

# Ensure Chart.yaml exists
if [[ -f "Chart.yaml" ]]; then
    CHART_FILE="Chart.yaml"
elif [[ -f "chart.yaml" ]]; then
    CHART_FILE="chart.yaml"
else
    echo "❌ Error: Chart.yaml not found! Ensure the script is running in the correct directory."
    exit 1
fi

# Read dependencies from the chart file
CHARTS=$(yq eval '.dependencies[] | .name + " " + .version + " " + .repository' "$CHART_FILE")

FAILING_CHARTS=()

while IFS= read -r chart_info; do
    CHART_NAME=$(echo "$chart_info" | awk '{print $1}')
    CHART_VERSION=$(echo "$chart_info" | awk '{print $2}')
    CHART_REPO=$(echo "$chart_info" | awk '{print $3}')

    if [[ -z "$CHART_NAME" || -z "$CHART_VERSION" || -z "$CHART_REPO" ]]; then
        echo "⚠️ Skipping invalid dependency entry: $chart_info"
        continue
    fi

    # Extract repo name from URL (e.g., "bitnami" from "https://charts.bitnami.com/bitnami")
    REPO_NAME=$(basename "$CHART_REPO")

    # Add the repo dynamically
    if ! helm repo list | grep -q "$REPO_NAME"; then
        echo "📦 Adding Helm repo: $REPO_NAME -> $CHART_REPO"
        helm repo add "$REPO_NAME" "$CHART_REPO"
    fi

    # Update repo before fetching
    helm repo update >/dev/null 2>&1

    echo "🔄 Updating dependency: $CHART_NAME (Version: $CHART_VERSION) from $CHART_REPO"
    
    if ! helm upgrade --install "$CHART_NAME" "$REPO_NAME/$CHART_NAME" --version "$CHART_VERSION"; then
        echo "🚨 Failed to update dependency: $CHART_NAME (Version: $CHART_VERSION)"
        FAILING_CHARTS+=("$CHART_NAME")
    else
        echo "✅ Successfully updated: $CHART_NAME (Version: $CHART_VERSION)"
    fi
done <<< "$CHARTS"

if [[ ${#FAILING_CHARTS[@]} -gt 0 ]]; then
    echo "🚨 The following dependencies failed to update: ${FAILING_CHARTS[*]}"
    exit 1
else
    echo "✅ All dependencies updated successfully!"
fi
