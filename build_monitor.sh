#!/bin/bash

set -e

# Configuration
REPO_OWNER="nwchero"
REPO_NAME="BookReader-iOS"
GITHUB_TOKEN="${GITHUB_TOKEN:-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}"
WORKFLOW_FILE="build-ios.yml"

# Function to get latest workflow run
get_latest_run() {
    curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/workflows/${WORKFLOW_FILE}/runs?per_page=1"
}

# Get latest run
LATEST_RUN=$(get_latest_run)
echo "$LATEST_RUN"

# Parse status, conclusion, etc.
STATUS=$(echo "$LATEST_RUN" | grep -o '"status": "[^"]*"' | cut -d'"' -f4 | head -1)
CONCLUSION=$(echo "$LATEST_RUN" | grep -o '"conclusion": "[^"]*"' | cut -d'"' -f4 | head -1)
CREATED_AT=$(echo "$LATEST_RUN" | grep -o '"created_at": "[^"]*"' | cut -d'"' -f4 | head -1)
RUN_ID=$(echo "$LATEST_RUN" | grep -o '"id": [0-9]*' | cut -d' ' -f2 | head -1)
HTML_URL=$(echo "$LATEST_RUN" | grep -o '"html_url": "[^"]*"' | cut -d'"' -f4 | head -1)

echo "=== Build Monitor Results ==="
echo "Repository: ${REPO_OWNER}/${REPO_NAME}"
echo "Workflow: ${WORKFLOW_FILE}"
echo "Run ID: ${RUN_ID}"
echo "URL: ${HTML_URL}"
echo "Status: ${STATUS}"
echo "Conclusion: ${CONCLUSION}"
echo "Created at: ${CREATED_AT}"

# Calculate queue time if queued
if [ "$STATUS" = "queued" ]; then
    # Simple calculation for elapsed time
    CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "Current time: ${CURRENT_TIME}"
fi
