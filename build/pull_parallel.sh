#!/usr/bin/env bash
set -eou pipefail

# Parallel version of pull.sh using GNU parallel or xargs
# Can process 20 repos simultaneously instead of one at a time

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "❌ Error: GITHUB_TOKEN environment variable is not set"
  exit 1
fi

# Create temp directory for parallel outputs
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Function to fetch a single repo
fetch_one_repo() {
  local p="$1"
  local comment="$2"
  local line_num="$3"
  local max_retries=3
  local attempt=1

  while [ $attempt -le $max_retries ]; do
    response=$(curl -s -w "\n%{http_code}" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$p" 2>/dev/null)

    http_code=$(echo "$response" | tail -n1)
    json_data=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
      # Validate JSON
      if echo "$json_data" | jq -e . >/dev/null 2>&1; then
        STARS=$(echo "$json_data" | jq -r .stargazers_count)
        if [ "$STARS" != "null" ] && [ -n "$STARS" ]; then
          # Compress JSON to single line
          json_compressed=$(echo "$json_data" | jq -c .)
          # Write to individual file to avoid race conditions
          # Use ASCII Unit Separator (0x1F) as delimiter to avoid conflicts with pipe characters
          printf '%s\x1F%s\x1F%s\n' "$STARS" "$json_compressed" "$comment" > "$TEMP_DIR/$line_num"
          return 0
        fi
      fi
    elif [ "$http_code" = "404" ]; then
      echo "⚠️  404: $p" >&2
      return 1
    elif [ "$http_code" = "403" ]; then
      # Rate limit hit, wait and retry
      sleep 2
      attempt=$((attempt + 1))
      continue
    fi

    attempt=$((attempt + 1))
    sleep 1
  done

  echo "⚠️  Failed: $p after $max_retries attempts" >&2
  return 1
}

export -f fetch_one_repo
export GITHUB_TOKEN
export TEMP_DIR

sort -fo data/repos data/repos

# Extract URLs and comments with line numbers
awk '{
  url = $1
  comment = ""
  hash_pos = index($0, "#")
  if (hash_pos > 0) {
    comment = substr($0, hash_pos + 1)
    gsub(/^[ \t]+|[ \t]+$/, "", comment)
  }
  gsub(/^https?:\/\/github\.com\//, "", url)
  gsub(/\/$/, "", url)
  printf "%06d|%s|%s\n", NR, url, comment
}' data/repos > tmp

TOTAL=$(wc -l < tmp | tr -d ' ')
echo "📥 Fetching data for $TOTAL repositories in parallel..."

# Use xargs for parallelization
cat tmp | xargs -P 20 -I {} bash -c '
  IFS="|" read -r line_num repo comment <<< "{}"
  fetch_one_repo "$repo" "$comment" "$line_num"
' 2>&1 | grep -E "^(⚠️|❌)" | head -10 || true

echo "📝 Combining results..."
# Combine all results in correct order
for file in $(ls -1 "$TEMP_DIR" | sort -n); do
  cat "$TEMP_DIR/$file"
done > index

FETCHED=$(wc -l < index | tr -d ' ')
echo "✅ Complete: Fetched $FETCHED/$TOTAL repositories"

if [ "$FETCHED" -lt "$TOTAL" ]; then
  echo "⚠️  Warning: $((TOTAL - FETCHED)) repositories failed to fetch"
fi
