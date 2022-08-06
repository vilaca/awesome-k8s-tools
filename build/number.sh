#!/usr/bin/env bash
set -eou pipefail

if [ "$1" -gt "1000" ]; then
  echo "$(echo "scale=1; {$1/1000}" | bc)K"
else
  printf "%s\n" $1
fi

