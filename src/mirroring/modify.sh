#!/bin/bash
set -e; shopt -s nullglob globstar

cp -rulfT mirror mirror-mod
for f in mirror-mod/**/*.{htm,html}; do
  rm "$f"
  sed 's/<link [^>]*>//;/<style/,/<\/style>/d;/<head>/a <link rel="stylesheet" href="/common.css">' \
    < mirror/"${f##mirror-mod/}" > "$f"
done
