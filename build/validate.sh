#!/usr/bin/env bash
set -eou pipefail

echo "🔍 Validating repository list..."
echo ""

# Check for duplicates
echo "Checking for duplicate entries..."
if awk 'a[$0]++{exit 1}' data/repos; then
  echo "✅ No duplicates found"
else
  echo "❌ Duplicate entries found in data/repos"
  exit 1
fi

echo ""

# Check for archived repositories if GITHUB_TOKEN is available
if [ -n "${GITHUB_TOKEN:-}" ]; then
  echo "Checking for archived repositories..."
  ./build/check_archived.sh
else
  echo "⚠️  Skipping archived repository check (GITHUB_TOKEN not set)"
fi

echo ""
echo "✅ Validation complete!"
