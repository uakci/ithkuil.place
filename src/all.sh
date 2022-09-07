#!/usr/bin/env bash
set -e
shopt -s globstar nullglob

echo mirrors; cd /root/mirror
bash /tweak-mirrors.sh

echo archive; cd /root/4/archive
bash /gen-archive.sh /archive.md.template > index.md
cd /root/4/archive/latest
tar czhf ../latest.tar.gz ./*
zip -q ../latest.zip ./*

echo nildb; cd /root/4/docs/freetnil/build
for f in /root/4/docs/**/*.yml; do
  bash ./scripts/convert-one.sh "$f" "${f%%.yml}.html" ./templates/category.html >/dev/null
done

echo md
for f in /root/**/*.md; do
  bash /pandoc.sh "$f" > "${f%%.md}.html"
done

echo cleanup
rm /root/**/.git
