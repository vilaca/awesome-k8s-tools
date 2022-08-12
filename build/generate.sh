#!/usr/bin/env bash
set -eou pipefail

sort -fo data/repos data/repos

cut -d'/' -f4-5 data/repos > tmp

bash --version

while IFS="" read -r p || [ -n "$p" ]
do
  printf 'Pulling %s\n' "$p"
  JSON="$(curl -s https://api.github.com/repos/"$p")"
  STARS="$(echo "$JSON" | jq .stargazers_count)"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 could not get the number of stars for $p"
    echo "$JSON"
    exit 1
  fi
  printf '%s %s\n' "$STARS" "${JSON//[$'\t\r\n']}"
  printf '%s %s\n' "$STARS" "${JSON//[$'\t\r\n']}" >> index
done < tmp

sort -nr index | cut -d' ' -f2 > sorted

cat sorted
