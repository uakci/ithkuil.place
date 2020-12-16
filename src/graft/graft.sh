#!/bin/bash
PANDOC="pandoc --trace --verbose --fail-if-warnings"

sed    "s/TITLE/$(sed -n '1{p;q}' "$1")/;
  s/DESCRIPTION/$(sed -n '2{p;q}' "$1")/;
      s/HEADING/$(sed -n '3{p;q}' "$1")/" \
  src/graft/prefix.html    > "$2"
sed '1,3d' "$1" | $PANDOC >> "$2"
cat src/graft/suffix.html >> "$2"
