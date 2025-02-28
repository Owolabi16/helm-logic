#!/bin/bash

set -e  # Exit script if any command fails

echo "Updating Helm dependencies per chart....."

# Read dependencies from Chart.yaml
CHARTS=$(yq eval '.dependencies[] | .name + " " + .version' Chart.yaml)

FAILING_CHARTS=()

while IFS= read -r chart_info; do
    CHART_NAME=$(echo "$chart_info" | awk '{print $1}')
    CHART_VERSION=$(echo "$chart_info" | awk '{print $2}')
    
    echo "🔄 Updating dependency: $CHART_NAME (Version: $CHART_VERSION)"
    if ! helm repo add temp-repo "$(yq eval ".dependencies[] | select(.name == \"$CHART_NAME\") | .repository" Chart.yaml)" >/dev/null 2>&1; then
        echo "⚠️ Failed to add repo for $CHART_NAME"
        FAILING_CHARTS+=($CHART_NAME)
        continue
    fi
    
    if ! helm fetch temp-repo/$CHART_NAME --version $CHART_VERSION >/dev/null 2>&1; then
        echo "🚨 Failed to update dependency: $CHART_NAME (Version: $CHART_VERSION)"
        FAILING_CHARTS+=($CHART_NAME)
    else
        echo "✅ Successfully updated: $CHART_NAME (Version: $CHART_VERSION)"
    fi

done <<< "$CHARTS"

if [[ ${#FAILING_CHARTS[@]} -gt 0 ]]; then
    echo "🚨 Failing dependencies: ${FAILING_CHARTS[*]}"
    exit 1
else
    echo "✅ All dependencies updated successfully!"
fi
