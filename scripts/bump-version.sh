#!/bin/bash

# Script to bump the chart version in Chart.yaml to current date (yy.m.d) - escaping leading zeros
# Usage: ./scripts/bump-version.sh [auto|manual]

set -e

CHART_FILE="glauth/Chart.yaml"

if [ ! -f "$CHART_FILE" ]; then
    echo "Error: Chart.yaml not found at $CHART_FILE"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(grep "^version:" "$CHART_FILE" | awk '{print $2}')

echo "Current version: $CURRENT_VERSION"

# Generate new version based on current date (yy.m.d) - escaping leading zeros
YEAR=$(date +%y)
MONTH=$(date +%-m 2>/dev/null || date +%_m | tr -d ' ')
DAY=$(date +%-d 2>/dev/null || date +%_d | tr -d ' ')
NEW_VERSION="$YEAR.$MONTH.$DAY"

echo "New version (based on current date): $NEW_VERSION"

# Update Chart.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$CHART_FILE"
else
    # Linux
    sed -i "s/^version: .*/version: $NEW_VERSION/" "$CHART_FILE"
fi

echo "Updated $CHART_FILE with version $NEW_VERSION"
echo ""
echo "Next steps:"
echo "1. Commit the version change:"
echo "   git add $CHART_FILE"
echo "   git commit -m \"Bump chart version to $NEW_VERSION\""
echo "2. Push to trigger release:"
echo "   git push origin main" 