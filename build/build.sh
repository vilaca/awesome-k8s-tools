#!/usr/bin/env bash
set -eou pipefail

./build/pull.sh
./build/generate.sh

cat resources/header.md > README.md
cat TOP.md >> README.md
cat resources/footer.md >> README.md
rm -f tmp index sorted ALL.md TOP.md NEW.md EXTRA.md NAV.md
