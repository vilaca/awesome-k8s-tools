#!/usr/bin/env bash
set -eou pipefail

printf '### %s ~ *%s*\n' "$1" "$2"
printf ' [⭐️](https://github.com/%s/stargazers) %s' "$3" "$(./build/number.sh $4)"
printf ' [🚀](https://github.com/%s/network/members) %s' "$3" "$(./build/number.sh $5)"
printf ' [💥](https://github.com/%s/issues) %s' "$3" "$(./build/number.sh $6)"
if [ "$7" != "null" ]
then
  printf ' 🪪  %s' "$7"
fi
if [ "$8" = "true" ]
then
  printf ' ⚠️ Archived'
fi
printf '\n\n\n'
