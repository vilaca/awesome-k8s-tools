#!/usr/bin/env bash
set -eou pipefail

cp resources/header.md README.md

./source/generate.sh

cat resources/footer.md >> README.md
