#!/usr/bin/env bash
set -eou pipefail

sort -fo data/repos data/repos

cut -d'/' -f4-5 data/repos > tmp

while IFS="" read -r p || [ -n "$p" ]
do
  printf 'Indexing %s\n' "$p"
  JSON="$(curl -s https://api.github.com/repos/"$p"?"$RANDOM")"
  STARS="$(echo "$JSON" | jq .stargazers_count)"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 could not get the number of stars for $p"
    exit 1
  fi
  printf '%s %s\n' "$STARS" "$p" >> index
done < tmp

sort -nr index | cut -d' ' -f2 > sorted

while IFS="" read -r p || [ -n "$p" ]
do
  printf 'Processing %s\n' "$p"
  JSON="$(curl -s https://api.github.com/repos/"$p"?"$RANDOM")"
  NAME="$(echo "$JSON" | jq -r .name)"
  STARS="$(echo "$JSON" | jq .stargazers_count)"
  DESCRIPTION="$(echo "$JSON" | jq -r .description)"
  LINK="[$NAME](https://github.com/$p)"
  echo "$JSON"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 could not get the number of stars for $p"
    exit 1
  fi
  printf '### %s <sup>⭐️ x %s</sup>\n%s\n' "$LINK" "$STARS" "$DESCRIPTION" >> README.md
done < sorted
