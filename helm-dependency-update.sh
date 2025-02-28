#!/bin/bash

set -e  # Exit script if any command fails

echo "🔄 Updating Helm dependencies per chart..."

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

    # Add the repo dynamically if missing
    if ! helm repo list | grep -q "$REPO_NAME"; then
        echo "📦 Adding Helm repo: $REPO_NAME -> $CHART_REPO"
        helm repo add "$REPO_NAME" "$CHART_REPO"
    fi

    # Update repo before fetching
    helm repo update >/dev/null 2>&1

done <<< "$CHARTS"

# Run `helm dependency update` to fetch dependencies
echo "📥 Running 'helm dependency update'..."
if ! helm dependency update; then
    echo "🚨 Failed to update dependencies"
    exit 1
else
    echo "✅ Helm dependencies updated successfully!"
fi
