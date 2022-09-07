#!/usr/bin/env bash
shopt -s globstar nullglob

for f in **/*.orig; do
  mv "$f" "${f%%.orig}"
done

mkdir assets
for f in **/*.{jpg,JPG,png,PNG,gif,GIF,mp3,MP3}; do
  mv "$f" assets
done

for f in **/*.htm{,l}; do
  file "$f" | grep -qF 'Non-ISO extended-ASCII text' && {
    iconv -f latin1 -t utf8 < "$f" > "$f.iconv"
    mv "$f.iconv" "$f"
  }
  sed -i 's/iso-8859-1/utf-8/gi' "$f"
done

while IFS=' ' read -r subdir cutdir _baselink; do
  i=0; cutexp='https?://'; while (( i++ < cutdir )); do cutexp+='[^/"]*/'; done
  for f in "$subdir"/*.htm{,l}; do
    # shellcheck disable=SC2016
    sed -Ei '
      s`="'"${cutexp}"'`="`g
      s`="([^"]*/)?([^"/]*.(jpg|gif|png|mp3))"`="../assets/\2"`gi
      s`</head>`<link rel=stylesheet href=/common.css>&`i
    ' "$f"
  done
done < sources
