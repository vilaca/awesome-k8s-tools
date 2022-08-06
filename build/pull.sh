#!/usr/bin/env bash
set -eou pipefail

sort -fo data/repos data/repos
cut -d'/' -f4-5 data/repos > tmp

while IFS="" read -r p || [ -n "$p" ]
do
  JSON="$(curl -s https://api.github.com/repos/"$p")"
  STARS="$(echo "$JSON" | jq .stargazers_count)"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 Could not get the number of stars for $p"
    echo "$JSON"
    exit 1
  fi
  printf '%s %s\n' "$STARS" "${JSON//[$'\t\r\n']}" >> index
done < tmp
