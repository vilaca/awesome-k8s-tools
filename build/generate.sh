#!/usr/bin/env bash
set -eou pipefail

# Clean up old sorted file
rm -f sorted

# Sort by stars (numeric reverse), keep the rest of the line
# Using ASCII Unit Separator (0x1F) as delimiter
sort -t$'\x1F' -k1 -nr index > sorted

# Initialize TOP.md (ensure it exists even if no valid entries)
> TOP.md

COUNTER=0

while IFS=$'\x1F' read -r STARS JSON COMMENT || [ -n "$JSON" ]
do
  # Validate JSON before processing
  if ! echo "$JSON" | jq -e . >/dev/null 2>&1; then
    echo "⚠️  Warning: Invalid JSON at line $((COUNTER+1)), skipping" >&2
    continue
  fi

  NAME="$(echo "$JSON" | jq -r .name)"
  FULL_NAME="$(echo "$JSON" | jq -r .full_name)"
  STARS_VAL="$(echo "$JSON" | jq .stargazers_count)"
  FORKS="$(echo "$JSON" | jq .forks)"
  ISSUES="$(echo "$JSON" | jq .open_issues)"
  DESCRIPTION="$(echo "$JSON" | jq -r .description | awk '{$1=$1;print}')"
  UPDATED="$(echo "$JSON" | jq -r .pushed_at)"
  LICENSE="$(echo "$JSON" | jq -r .license.name)"
  LINK="[${NAME^}](https://github.com/$FULL_NAME)"
  if [ "${STARS_VAL}" = "null" ]
  then
    echo "😱 could not get the number of stars for $FULL_NAME"
    echo "$JSON"
    exit 1
  fi
  if [ "${LICENSE}" = "null" ]
  then
    LICENSE="N.A."
  fi
  if [ "${DESCRIPTION}" = "null" ]
  then
    DESCRIPTION="No description in repo."
  fi
  ./build/card.sh "$LINK" "$DESCRIPTION" "$FULL_NAME" "$STARS_VAL" "$FORKS" "$ISSUES" "$LICENSE" "$((++COUNTER))" "$COMMENT" >> TOP.md
done < sorted
