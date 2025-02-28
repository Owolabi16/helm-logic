#!/bin/bash

set -e  # Exit if any command fails

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

# Run helm dependency update
echo "📥 Running 'helm dependency update'..."
if ! helm dependency update; then
    echo "🚨 Failed to update dependencies"
    exit 1
else
    echo "✅ Helm dependencies updated successfully!"
fi

# Extract Helm dependencies (if they exist as .tgz files)
echo "📂 Extracting Helm dependencies..."
mkdir -p charts
for tgz in charts/*.tgz; do
    if [[ -f "$tgz" ]]; then
        tar -xzf "$tgz" -C charts/
        rm -f "$tgz"  # Remove the tarball after extraction
    fi
done

echo "✅ Dependencies extracted successfully!"
