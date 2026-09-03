#!/bin/sh
# Runs every hedgehog property for this refactoring, in both languages.
# Each NN-*/ directory holds Before + After + Spec in Scala 3 and Haskell;
# Spec generates inputs and asserts Before and After agree on all of them.
# The shared/ directory (Scala object Optics, Haskell module Optics) holds
# the optic building blocks; it is compiled in, never shown on the page.
#
# Needs: scala-cli (https://scala-cli.virtuslab.org) and either ghc with
# hedgehog on the package path, or docker (the image is built on first use).
set -eu
cd "$(dirname "$0")"
SHARED="$(pwd)/shared"

if command -v ghc >/dev/null 2>&1 && ghc-pkg list hedgehog 2>/dev/null | grep -q hedgehog; then
  hs() { runghc -i"$1" -i"$SHARED" "$1/Spec.hs"; }
else
  docker image inspect cp-hedgehog >/dev/null 2>&1 || \
    printf 'FROM haskell:9.8-slim\nRUN cabal update && cabal install --lib hedgehog\n' | docker build -t cp-hedgehog -
  hs() { docker run --rm -v "$PWD:/w" -v "$SHARED:/shared" -w /w cp-hedgehog runghc -i"$1" -i/shared "$1/Spec.hs"; }
fi

for d in [0-9][0-9]-*/; do
  d=${d%/}
  echo "== $d (scala)"
  scala-cli run "$d" --main-class spec "$SHARED"
  echo "== $d (haskell)"; hs "$d"
done
echo "all properties passed"
