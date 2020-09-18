#!/bin/bash

source "$(dirname "$0")/crawl-sources"

crawl_one() {
  wget2 --max-threads=8 --mirror --page-requisites \
    --adjust-extension --convert-links --backup-converted --restrict-file-names=unix \
    --execute "robots=off" --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0" \
    --no-host-directories --cut-dirs "$2" --directory-prefix "$1" \
    --wait=0.4 --tries=3 --waitretry=120 \
    --cut-url-get-vars --cut-file-get-vars \
    "$3"
  status=$?
  if test $status = 8; then # -o $status = 3; then
    return 0
  fi
  return $status
}

BASE="$(realpath "$(dirname "$0")/../..")"
for tuple in "${MIRRORS[@]}"; do
  IFS=: read -r dir cut url <<< "$tuple"
  crawl_one "$BASE"/www/mirror/"$dir" "$cut" "$url" || exit $?
done

# --wait=5 --random-wait 
