#!/usr/bin/env bash
set -eou pipefail

cp resources/header.md README.md
./build/pull.sh
./build/generate.sh
./build/generate-extra.sh
echo "<div align=\"center\">" >> README.md
cat NAV.md >> README.md
echo "</div>" >> README.md
printf "\n"
echo "## 🎉 Top 5" >> README.md
cat TOP.md >> README.md
cat EXTRA.md >> README.md
echo "## ⭐️ Misc" >> README.md
cat ALL.md >> README.md
cat resources/footer.md >> README.md
rm -f tmp index sorted ALL.md TOP.md NEW.md EXTRA.md NAV.md
