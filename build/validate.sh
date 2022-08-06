#!/usr/bin/env bash
set -eou pipefail

awk 'a[$0]++{exit 1}' data/repos
exit $?
