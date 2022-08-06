#!/usr/bin/env bash
set -eou pipefail

cp src/header.md README.md

cut -d'/' -f4-5 src/repos > tmp

while IFS="" read -r p || [ -n "$p" ]
do
  printf '%s\n' "$p"
  JSON="$(curl -s https://api.github.com/repos/$p)"
  SORTED="$(echo $JSON | sort)"
  LINK="[$p](https://github.com/$p)"
  STARS="$(echo $JSON | jq .stargazers_count)"
  DESCRIPTION="$(echo $JSON | jq .description)"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 could not get the number of starts for $p"
    exit 1
  fi
  echo "### $LINK<br>$DESCRIPTION<br>(⭐️<sub>x</sub>$STARS)" >> README.md
done < tmp

cat src/footer.md >> README.md
