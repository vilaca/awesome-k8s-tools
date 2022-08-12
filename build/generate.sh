#!/usr/bin/env bash
set -eou pipefail

sort -fo data/repos data/repos

cut -d'/' -f4-5 data/repos > tmp

sort -nr index | cut -d' ' -f2- > sorted

cat sorted

while IFS="" read -r JSON || [ -n "$JSON" ]
do
  printf 'Processing %s\n' "$JSON"
  NAME="$(echo "$JSON" | jq -r .name)"
  FULL_NAME="$(echo "$JSON" | jq -r .full_name)"
  STARS="$(echo "$JSON" | jq .stargazers_count)"
  DESCRIPTION="$(echo "$JSON" | jq -r .description)"
  LINK="[$NAME^](https://github.com/$FULL_NAME)"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 could not get the number of stars for $FULL_NAME"
    exit 1
  fi
  printf '### %s <sup>⭐️ x %s</sup>\n%s\n' "$LINK" "$STARS" "$DESCRIPTION" >> README.md
done < sorted
