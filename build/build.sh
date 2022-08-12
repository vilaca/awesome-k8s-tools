#!/usr/bin/env bash
set -eou pipefail

rm -f tmp index sorted
cp resources/header.md README.md
./build/pull.sh
./build/generate.sh
cat resources/footer.md >> README.md
