#!/usr/bin/env bash
set -eou pipefail

wc -l *topic \
  | sed '$d' \
  | grep -v docker \
  | grep -v go \
  | grep -v grafana \
  | grep -v hacktoberfest \
  | grep -v k8s \
  | grep -v kubectl \
  | grep -v kubernetes \
  | grep -v prometheus \
  | grep -v cloud-native \
  | grep -v cncf \
  | grep -v terraform \
  | grep -v metrics \
  | grep -v slack \
  | grep -v time-series \
  | grep -v notifications \
  | grep -v observability \
  | sort -nr \
  | head -n 20 \
  | sed -e 's/^[ \t]*//' \
  | cut -d' ' -f2 \
  | sort \
  >> topics

while IFS="" read -r FILE || [ -n "$FILE" ]
do
  echo "## 🧑‍💻 ${FILE^}" | cut -d'.' -f1 | tr '-' ' ' >> EXTRA.md
  cat "$FILE" >> EXTRA.md
  LINK="$(echo "$FILE" | cut -d'.' -f1)"
  echo "[[$(echo "$FILE" | cut -d'.' -f1 | tr '-' ' ')](https://github.com/vilaca/awesome-k8s-tools#-$LINK)]" >> NAV.md
done < topics

sort -fo NAV.md NAV.md

rm *.topic
rm topics

touch ALL.md

while IFS="" read -r FILE || [ -n "$FILE" ]
do
  if grep -q "$(echo "$FILE" | jq -r ".full_name")" EXTRA.md
  then
    continue
  fi

  if grep -q "$(echo "$FILE" | jq -r ".full_name")" TOP.md
  then
    continue
  fi
  
  if grep -q "$(echo "$FILE" | jq -r ".full_name")" ALL.md
  then
    continue
  fi
  
  NAME="$(echo "$FILE" | jq -r .name)"
  FULL_NAME="$(echo "$FILE" | jq -r .full_name)"
  STARS="$(echo "$FILE" | jq .stargazers_count)"
  FORKS="$(echo "$FILE" | jq .forks)"
  ISSUES="$(echo "$FILE" | jq .open_issues)"
  DESCRIPTION="$(echo "$FILE" | jq -r .description | awk '{$1=$1;print}')"
  LICENSE="$(echo "$FILE" | jq -r .license.name)"
  LINK="[${NAME^}](https://github.com/$FULL_NAME)"
  if [ "${STARS}" = "null" ]
  then
    echo "😱 could not get the number of stars for $FULL_NAME"
    echo "$FILE"
    exit 1
  fi

  ./build/card.sh "$LINK" "$DESCRIPTION" "$FULL_NAME" "$STARS" "$FORKS" "$ISSUES" "$LICENSE" >> ALL.md
  
done < sorted