#!/usr/bin/env bash
set -eou pipefail

sort -nr index | cut -d' ' -f2- > sorted

top=0
while IFS="" read -r JSON || [ -n "$JSON" ]
do
  NAME="$(echo "$JSON" | jq -r .name)"
  FULL_NAME="$(echo "$JSON" | jq -r .full_name)"
  STARS="$(echo "$JSON" | jq .stargazers_count)"
  FORKS="$(echo "$JSON" | jq .forks)"
  ISSUES="$(echo "$JSON" | jq .open_issues)"
  DESCRIPTION="$(echo "$JSON" | jq -r .description | awk '{$1=$1;print}')"
  UPDATED="$(echo "$JSON" | jq -r .pushed_at)"
  LICENSE="$(echo "$JSON" | jq -r .license.name)"
  LINK="[${NAME^}](https://github.com/$FULL_NAME)"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 could not get the number of stars for $FULL_NAME"
    echo "$JSON"
    exit 1
  fi

  ./build/card.sh "$LINK" "$DESCRIPTION" "$FULL_NAME" "$STARS" "$FORKS" "$ISSUES" "$LICENSE" >> CARD.md
  
  if [ "$top" -lt "5" ]; then
    ((top=top+1))
    cat CARD.md >> TOP.md
  fi;

  echo "$JSON" | jq -r '.topics[]' | while read i; do
    cat CARD.md >> "$i".topic
  done

  rm CARD.md

done < sorted
