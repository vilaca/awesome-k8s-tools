#!/usr/bin/env bash
set -eou pipefail

cp src/header.md README.md

cut -d'/' -f4-5 src/repos > tmp

while IFS="" read -r p || [ -n "$p" ]
do
  printf '%s\n' "$p"
  JSON="$(curl -s https://api.github.com/repos/$p)"
  SORTED="$(echo $JSON | sort)"
  NAME="$(echo $JSON | jq -r .name)"
  STARS="$(echo $JSON | jq .stargazers_count)"
  DESCRIPTION="$(echo $JSON | jq -r .description)"
  LINK="[$NAME](https://github.com/$p)"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 could not get the number of stars for $p"
    exit 1
  fi
  printf "### $LINK <sup>⭐️ x $STARS</sup>\n$DESCRIPTION\n" >> README.md
done < tmp

cat src/footer.md >> README.md
