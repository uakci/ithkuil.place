#!/bin/bash
set -e; shopt -s extglob nullglob globstar

if [ ! -f /.dockerenv ]; then
  echo This script must be run in a container >&2
  exit 1
fi

head -n1 /etc/apk/repositories | \
  sed 's#/[^/]*/main$#/edge/testing#' >> /etc/apk/repositories
apk add --no-cache nginx pandoc tree
cd /src

PREFIX="src/4/docs/nildb"
for file in "$PREFIX"/!(_*).yml "$PREFIX"/**/!(_*).yml; do
  target="/www/4/docs/${file##$PREFIX/}" target="${target%%.yml}.html"
  mkdir -p "$(dirname "$target")"
  ./src/4/docs/freetnil/build/scripts/convert-one.sh "$file" "$target" \
    "src/4/docs/freetnil/build/templates/category.html"
done

cd /www
/src/mirroring/modify.sh

cd 4/archive
tar --create --file all.tar.gz *.pdf
{
  sed '/%%%/q' /src/4/archive/index.html.template
  for f in *.pdf; do
    echo "<li><a href="$f">"$f"</a></li>"
  done
  sed ',/%%%/d' /src/4/archive/index.html.template
} > index.html
cd /www

{
  echo -n "<pre>"
  tree -nf --noreport /www/ | paste -d'\t' - - | sed '1d;s|── /www/|── <a href="|;s|\t|">|;s|$|</a>|'
  echo "</pre>"
} > SITEMAP

rm -rf /src
apk del --no-cache pandoc tree bash
