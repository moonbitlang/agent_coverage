#!/usr/bin/env sh

find 'src' -type f -name '*.mbt' -print0 \
  | xargs -0 cat \
  | perl -nE 'say "$1" if (m/^.*\/\/.+@bundle-append\s+(.+)$/)' \
  | cat - ./target/js/release/build/main/main.js \
  > ./target/js/release/build/main/mainmod.js
