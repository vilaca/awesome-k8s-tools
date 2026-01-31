#!/usr/bin/env bash
set -eou pipefail

# Check if GITHUB_TOKEN is set
if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "❌ Error: GITHUB_TOKEN environment variable is not set"
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

# Function to make API call with retry logic
fetch_repo_data() {
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
      echo "$json_data"
      return 0
    elif [ "$http_code" = "404" ]; then
      echo "⚠️  Warning: Repository $repo not found (404)" >&2
      return 1
    elif [ "$http_code" = "403" ]; then
      echo "⚠️  Warning: Rate limit or forbidden (403) for $repo" >&2
      check_rate_limit
      if [ $attempt -lt $max_retries ]; then
        echo "Retrying in ${retry_delay}s... (attempt $attempt/$max_retries)" >&2
        sleep $retry_delay
        retry_delay=$((retry_delay * 2))
        attempt=$((attempt + 1))
        continue
      fi
      return 1
    elif [ "$http_code" = "401" ]; then
      echo "❌ Error: Authentication failed (401). Check GITHUB_TOKEN validity." >&2
      exit 1
    else
      echo "⚠️  Warning: HTTP $http_code for $repo" >&2
      if [ $attempt -lt $max_retries ]; then
        echo "Retrying in ${retry_delay}s... (attempt $attempt/$max_retries)" >&2
        sleep $retry_delay
        retry_delay=$((retry_delay * 2))
        attempt=$((attempt + 1))
        continue
      fi
      return 1
    fi
  done

  echo "❌ Error: Failed to fetch data for $repo after $max_retries attempts" >&2
  return 1
}

# Check rate limit before starting
echo "🔍 Checking GitHub API rate limit..."
check_rate_limit

sort -fo data/repos data/repos

# Extract URLs and comments
# Format: owner/repo|comment (comment is optional)
awk '{
  # Split by # to separate URL from comment
  url = $1
  comment = ""
  hash_pos = index($0, "#")
  if (hash_pos > 0) {
    comment = substr($0, hash_pos + 1)
    # Trim leading/trailing whitespace from comment
    gsub(/^[ \t]+|[ \t]+$/, "", comment)
  }
  # Extract owner/repo from URL (after github.com/)
  # Remove https://github.com/ prefix
  gsub(/^https?:\/\/github\.com\//, "", url)
  # Remove any trailing slashes
  gsub(/\/$/, "", url)
  printf "%s|%s\n", url, comment
}' data/repos > tmp

echo "📥 Fetching data for $(wc -l < tmp | tr -d ' ') repositories..."
processed=0
failed=0

while IFS="|" read -r p comment || [ -n "$p" ]
do
  processed=$((processed + 1))

  # Check rate limit every 50 requests
  if [ $((processed % 50)) -eq 0 ]; then
    check_rate_limit
  fi

  JSON="$(fetch_repo_data "$p")"
  if [ $? -ne 0 ]; then
    failed=$((failed + 1))
    echo "⚠️  Skipping $p due to fetch error"
    continue
  fi

  STARS="$(echo "$JSON" | jq -r .stargazers_count)"
  if [ "${STARS}" = "null" ] || [ -z "${STARS}" ]; then
    echo "⚠️  Warning: Could not get star count for $p, skipping"
    failed=$((failed + 1))
    continue
  fi

  # Store stars, JSON, and comment separated by |
  printf '%s|%s|%s\n' "$STARS" "${JSON//[$'\t\r\n']}" "$comment" >> index

  # Progress indicator
  if [ $((processed % 100)) -eq 0 ]; then
    echo "✓ Processed $processed repositories..."
  fi
done < tmp

echo "✅ Complete: Processed $processed repositories ($failed failed)"

if [ $failed -gt 0 ]; then
  echo "⚠️  Warning: $failed repositories failed to fetch. Check logs above."
fi
