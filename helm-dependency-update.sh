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

# Add repositories manually before updating
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add jaeger https://jaegertracing.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts

# Update repositories
helm repo update

# Read dependencies from the chart file
CHARTS=$(yq eval '.dependencies[] | .name + " " + .version + " " + .repository' "$CHART_FILE")

FAILING_CHARTS=()

while IFS= read -r chart_info; do
    CHART_NAME=$(echo "$chart_info" | awk '{print $1}')
    CHART_VERSION=$(echo "$chart_info" | awk '{print $2}')
    CHART_REPO=$(echo "$chart_info" | awk '{print $3}')

    echo "🔄 Updating dependency: $CHART_NAME (Version: $CHART_VERSION) from $CHART_REPO"
    
    if ! helm fetch "$CHART_NAME" --version "$CHART_VERSION" >/dev/null 2>&1; then
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
