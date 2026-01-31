#!/usr/bin/env bash
set -eou pipefail

printf '### %s - %s' "$8" "$1"
printf ' [⭐️](https://github.com/%s/stargazers) %s' "$3" "$(./build/number.sh $4)"
printf ' [🚀](https://github.com/%s/network/members) %s' "$3" "$(./build/number.sh $5)"
printf ' [💥](https://github.com/%s/issues) %s' "$3" "$(./build/number.sh $6)"
printf ' 🪪  %s' "$7"

# Add comment if it exists (9th parameter)
if [ $# -ge 9 ] && [ -n "$9" ]; then
  printf ' %s' "$9"
fi
printf '\n'

printf '*%s*\n\n' "$2"
