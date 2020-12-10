#!/bin/bash
set -e; shopt -s extglob nullglob globstar

if [ ! -f /.dockerenv ]; then
  echo This script must be run in a container >&2
  exit 1
fi

PREFIX="/src/4/docs/nildb"
for file in "$PREFIX"/**/!(_*).yml; do
  target="/www/4/docs/${file##$PREFIX/}" target="${target%%.yml}.html"
  mkdir -p "$(dirname "$target")"
  /src/4/docs/freetnil/build/scripts/convert-one.sh "$file" "$target" \
    /src/4/docs/freetnil/build/templates/category.html
done

cd /www
/src/mirroring/modify.sh

capitalize() {
  sed -E 's/-/ /g;s/(^| )./\U&/g' <<< "$1"
}

cd 4/archive
tar --create --file all.tar.gz ./**/*.pdf
{
  sed -n '/%%%/q;p' /src/4/archive/index.html.template
  for prefix in **/; do
    ls "$prefix"*.* >&- || continue
    echo "<h2>$(capitalize "$(basename "${prefix%/}")")</h2>"
    echo "<ul class=figure>"
    for f in "$prefix"*.*; do
      core="${f##$prefix}"
      extension="${core##*.}"
      core="${core%%.$extension}"
      date="${core: -10}"
      core="${core%%-$date}"
      versionless="${core%%-v[0-9]*}"
      version=
      if [ ! "$versionless" = "$core" ]; then
        version="${core##$versionless}"
        core="${core%%$version}"
        version=" ${version:1}"
      fi
      echo "  <li><a href=\"$f\">$(capitalize "$core")$version</a> (.$extension, $date)</li>"
      echo "  <li><a href=\"$f\">$(capitalize "$core")$version</a> (.$extension, $date)</li>" >&2
    done
    echo "</ul>"
  done
  sed -n '/%%%/,$p' /src/4/archive/index.html.template | \
    sed -n '2,$p' -
} > index.html
cd /www

tree -H "" . > SITEMAP.html
