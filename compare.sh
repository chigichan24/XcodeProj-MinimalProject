#!/bin/bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

echo "################ Stock XcodeProj 9.11.0 ################"
(cd "$here/Stock" && swift run --quiet Stock)
echo
echo "################ Branch (support-package-traits) ################"
(cd "$here/Branch" && swift run --quiet Branch)
