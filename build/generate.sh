#!/usr/bin/env bash
set -eou pipefail

# Sort by stars (numeric reverse), keep the rest of the line
sort -t'|' -k1 -nr index > sorted

COUNTER=0

while IFS="|" read -r STARS JSON COMMENT || [ -n "$JSON" ]
do
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
