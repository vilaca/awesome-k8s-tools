#!/usr/bin/env bash
set -eou pipefail

# Script to check for archived repositories in data/repos
# This script fetches repository information from GitHub API and checks if they are archived
# 
# Usage:
#   GITHUB_TOKEN=<token> ./build/check_archived.sh
#
# The script will:
# - Check all repositories in data/repos for archived status
# - Report which repositories are archived
# - Identify archived repos that are not yet marked in data/repos
# - Exit successfully (this is a reporting tool, not a blocking validation)

# Check if GITHUB_TOKEN is set
if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "❌ Error: GITHUB_TOKEN environment variable is not set"
  echo "Usage: GITHUB_TOKEN=<your_token> $0"
  exit 1
fi

# Function to check rate limit
check_rate_limit() {
  local rate_limit_json
  rate_limit_json="$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/rate_limit)"
  local remaining
  remaining="$(echo "$rate_limit_json" | jq -r '.rate.remaining')"
  local reset_time
  reset_time="$(echo "$rate_limit_json" | jq -r '.rate.reset')"

  if [ "$remaining" -lt 10 ]; then
    echo "⚠️  Warning: Only $remaining API calls remaining"
    echo "Rate limit resets at: $(date -r "$reset_time" 2>/dev/null || date -d "@$reset_time" 2>/dev/null || echo "unknown")"
    if [ "$remaining" -eq 0 ]; then
      echo "❌ Error: GitHub API rate limit exceeded. Please wait until rate limit resets."
      exit 1
    fi
  fi
}

# Function to check if a repository is archived
check_archived_status() {
  local repo="$1"
  local max_retries=3
  local retry_delay=2
  local attempt=1

  while [ $attempt -le $max_retries ]; do
    local response
    local http_code

    # Make API call and capture both response and HTTP status
    response=$(curl -s -w "\n%{http_code}" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$repo")

    http_code=$(echo "$response" | tail -n1)
    local json_data
    json_data=$(echo "$response" | sed '$d')

    # Check HTTP status code
    if [ "$http_code" = "200" ]; then
      # Extract archived status from JSON
      local is_archived
      is_archived=$(echo "$json_data" | jq -r '.archived')
      echo "$is_archived"
      return 0
    elif [ "$http_code" = "404" ]; then
      echo "not_found"
      return 0
    elif [ "$http_code" = "403" ]; then
      if [ $attempt -lt $max_retries ]; then
        sleep $retry_delay
        retry_delay=$((retry_delay * 2))
        attempt=$((attempt + 1))
        continue
      fi
      echo "error"
      return 1
    else
      if [ $attempt -lt $max_retries ]; then
        sleep $retry_delay
        retry_delay=$((retry_delay * 2))
        attempt=$((attempt + 1))
        continue
      fi
      echo "error"
      return 1
    fi
  done

  echo "error"
  return 1
}

# Check rate limit before starting
echo "🔍 Checking GitHub API rate limit..."
check_rate_limit

echo "📋 Checking for archived repositories..."
echo ""

# Extract URLs from data/repos
# Remove https://github.com/ prefix and any trailing slashes
awk '{
  url = $1
  gsub(/^https?:\/\/github\.com\//, "", url)
  gsub(/\/$/, "", url)
  # Only print the owner/repo part before any comment
  if (url ~ /^[^#]+/) {
    split(url, parts, "#")
    print parts[1]
  }
}' data/repos | sort -u > /tmp/repos_to_check.txt

total_repos=$(wc -l < /tmp/repos_to_check.txt | tr -d ' ')
echo "Found $total_repos repositories to check"
echo ""

processed=0
archived_count=0
not_found_count=0
error_count=0

# Store results
> /tmp/archived_repos.txt
> /tmp/not_found_repos.txt

while read -r repo || [ -n "$repo" ]
do
  # Skip empty lines
  [ -z "$repo" ] && continue
  
  processed=$((processed + 1))

  # Check rate limit every 50 requests
  if [ $((processed % 50)) -eq 0 ]; then
    check_rate_limit
    echo "✓ Processed $processed/$total_repos repositories..."
  fi

  status=$(check_archived_status "$repo")
  
  if [ "$status" = "true" ]; then
    echo "💀 ARCHIVED: $repo"
    echo "$repo" >> /tmp/archived_repos.txt
    archived_count=$((archived_count + 1))
  elif [ "$status" = "not_found" ]; then
    echo "❌ NOT FOUND: $repo"
    echo "$repo" >> /tmp/not_found_repos.txt
    not_found_count=$((not_found_count + 1))
  elif [ "$status" = "error" ]; then
    echo "⚠️  ERROR: $repo"
    error_count=$((error_count + 1))
  fi

  # Small delay to avoid rate limiting
  sleep 0.1
done < /tmp/repos_to_check.txt

echo ""
echo "=========================================="
echo "Summary:"
echo "=========================================="
echo "Total repositories checked: $processed"
echo "Archived repositories: $archived_count"
echo "Not found repositories: $not_found_count"
echo "Errors: $error_count"
echo ""

if [ $archived_count -gt 0 ]; then
  echo "💀 Archived repositories found:"
  echo ""
  # Compare with what's already marked in data/repos
  while read -r archived_repo; do
    # Check if this repo already has an archived comment in data/repos
    if grep -q "github.com/$archived_repo.*#.*Archived\|Archived.*github.com/$archived_repo" data/repos; then
      echo "  ✓ $archived_repo (already marked)"
    else
      echo "  ⚠️  $archived_repo (NOT marked in data/repos)"
    fi
  done < /tmp/archived_repos.txt
  echo ""
fi

if [ $not_found_count -gt 0 ]; then
  echo "❌ Not found repositories:"
  cat /tmp/not_found_repos.txt
  echo ""
fi

# Clean up
rm -f /tmp/repos_to_check.txt /tmp/archived_repos.txt /tmp/not_found_repos.txt

echo "✅ Check complete!"

# Return success - this is a reporting tool, not a blocking validation
exit 0
