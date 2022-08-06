#!/usr/bin/env bash
set -eou pipefail

cp src/header.md README.md

cut -d'/' -f4-5 src/repos > tmp

while IFS="" read -r p || [ -n "$p" ]
do
  printf '%s\n' "$p"
  JSON="$(curl https://api.github.com/repos/$p)"
  SORTED="$(echo $JSON | sort)"
  LINK="[$p](https://github.com/$p)"
  STARS="$(echo $JSON | jq .stargazers_count)"
  echo "- $LINK $STARS" >> README.md
done < tmp

cat src/footer.md >> README.md
