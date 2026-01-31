#!/usr/bin/env bash
set -eou pipefail

# Simple test script to check archived status of a single repository
# Usage: ./check_archived_simple.sh owner/repo

if [ $# -lt 1 ]; then
  echo "Usage: $0 owner/repo"
  exit 1
fi

repo="$1"

# Fetch repo data without authentication (works for public repos with lower rate limit)
response=$(curl -s -w "\n%{http_code}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$repo")

http_code=$(echo "$response" | tail -n1)
json_data=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
  is_archived=$(echo "$json_data" | jq -r '.archived')
  name=$(echo "$json_data" | jq -r '.full_name')
  stars=$(echo "$json_data" | jq -r '.stargazers_count')
  
  if [ "$is_archived" = "true" ]; then
    echo "💀 ARCHIVED: $name (⭐ $stars)"
  else
    echo "✓ ACTIVE: $name (⭐ $stars)"
  fi
else
  echo "❌ Error: HTTP $http_code for $repo"
  exit 1
fi
