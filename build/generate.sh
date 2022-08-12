#!/usr/bin/env bash
set -eou pipefail

sort -fo data/repos data/repos

cut -d'/' -f4-5 data/repos > tmp

sort -nr index | cut -d' ' -f2- > sorted

while IFS="" read -r JSON || [ -n "$JSON" ]
do
  printf 'Processing %s\n' "$JSON"
  NAME="$(echo "$JSON" | jq -r .name)"
  FULL_NAME="$(echo "$JSON" | jq -r .full_name)"
  STARS="$(echo "$JSON" | jq .stargazers_count)"
  FORKS="$(echo "$JSON" | jq .forks)"
  ISSUES="$(echo "$JSON" | jq .open_issues)"
  DESCRIPTION="$(echo "$JSON" | jq -r .description)"
  LINK="[${NAME^}](https://github.com/$FULL_NAME)"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 could not get the number of stars for $FULL_NAME"
    exit 1
  fi
  printf '### %s\n' "$LINK" >> README.md
  printf '#### %s\n' "$DESCRIPTION" >> README.md
  printf '###### [%s ⭐️](https://api.github.com/repos/%s/stargazers),' "$STARS" "$FULL_NAME" >> README.md
  printf ' [%s 🚀](https://api.github.com/repos/%s/forks),' "$FORKS" "$FULL_NAME" >> README.md
  printf ' [%s 💥](https://api.github.com/repos/%s/issues)\n\n' "$ISSUES" "$FULL_NAME" >> README.md
done < sorted
