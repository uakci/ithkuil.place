#!/bin/bash
# $1: template
shopt -s nullglob globstar

capitalize() {
  sed -E 's/-/ /g;s/(^| )./\U&/g' <<< "$1"
}

tar --create --file all.tar.gz ./**/*.pdf
{
  sed -n '/%%%/q;p' "$1"
  for prefix in **/; do
    h=$(tr -cd / <<< "/$prefix" | wc -c)
    echo "<h$h>$(capitalize "$(basename "${prefix%/}")")</h$h>"
    [ -n "$(echo "$prefix"*?.?*)" ] || continue
    echo '<ul class=figure>'
    # shellcheck disable=sc2012
    ls -ard -- "$prefix"*?.?* | while read -r f; do
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
        version="${version:1}"
      fi
      pre="$(capitalize "$core") "
      link="$version"
      if [ "$core" = "$(basename "$prefix")" ]; then
        pre=
      fi
      if [ -z "$version" ]; then
        pre=
        link="$(capitalize "$core")"
      fi
      echo "  <li>$pre<a href=\"$f\">$link</a> (.$extension, $date)</li>"
      # echo "  <li>$pre<a href=\"$f\">$link</a> (.$extension, $date)</li>" >&2
    done
    echo "</ul>"
  done
  sed -n '/%%%/,$p' "$1" | sed -n '2,$p' -
} > index.html
