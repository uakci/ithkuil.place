#!/bin/bash
set -e; shopt -s nullglob globstar extglob
cd "$(dirname "$0")" 

trap 'error $LINENO $?' ERR

## utilities ##

error() {
  echo $'\e[31m'"Status code $2 on line $1: "$'\e[m'"$(sed "$1q;d" "$0")" >&2
  echo $'\e[1;91m'"Exiting due to failure"$'\e[m' >&2
  exit "$2"
}

update() {
  local this="${1%%/}"
  local other="${2-$this}"
  test "${other%%/}" = "$other" \
    || other="$other$(basename "$this")"
  other="${other##/}"
  other="${other:-/}"
  mkdir -p "$TARGET/$(dirname "$other")"
  cp -urvT "$this" "$TARGET/$other"
  find "$this" | while read -r file; do
    local fname="$TARGET/$other${file##$this}"
    # shellcheck disable=SC2015
    [ -d "$fname" ] && fname="$fname/" || :
    echo "$fname"
  done >> .checked
  also_parents "$other"
}

also_parents() {
  local it
  it="$(dirname "$1")"
  while test ! "$it" = .; do
    echo "$TARGET/$it/"
    it="$(dirname "$it")"
  done >> .checked
}

replace() {
  tee > .tmp
  local rev="$TARGET/${1##/}"
  # shellcheck disable=SC2015
  test -e "$rev" && diff -q .tmp "$rev" >/dev/null \
    || update .tmp "$1"
  rm .tmp
  echo "$rev" >> .checked
  also_parents "${1##/}"
}

newer() {
  local other="$TARGET/${2-$1}" status=0
  test "$1" -nt "$other" || status=$?
  if test $status = 0; then
    echo "Will build "$'\e[97m'"$other"$'\e[m'" from "$'\e[1;97m'"$1"$'\e[m'
    test -e "$other" || mkdir -p "$(dirname "$other")"
  fi
  echo "$other" >> .checked
  also_parents "${2-$1}"
  return $status
}

## ## ##

TARGET="${1-target}"
TARGET="${TARGET%%/}"

ENSURE_INSTALLED=(docker git pandoc tree)

echo $'\e[1;94m'"Toolage"$'\e[m'
for ensuree in ${ENSURE_INSTALLED[*]}; do
  path=$(which "$ensuree" 2>/dev/null || :)
  test "$path" || {
    echo $'\e[91m'"You don’t seem to have $ensuree installed."$'\e[m' >&2
    exit 42
  }
  echo -n "$path: "
  "$path" --version | head -n1
done
echo

mkdir -p "$TARGET"
echo "$TARGET/" > .checked
find "$TARGET" | while read -r line; do
  test -d "$line" && line="${line%%/}/"
  echo "$line"
done > .unchecked

mkdir -p "$TARGET/www/"

echo $'\e[1;94m'"Git info"$'\e[m'
{
  echo -n 'branch: '
  git branch --show-current
  echo -n 'commit: '
  git rev-parse HEAD
  echo -n 'status: '
  if test "$(git status --porcelain)"; then
    echo 'dirty'
  else
    echo 'clean'
  fi
} \
  | replace /www/REVISION > .tmp2
cat "$TARGET"/www/REVISION .tmp2
rm .tmp2
echo

echo $'\e[1;94m'"Auxiliary"$'\e[m'
update www/ /
update LICENSE /www/
update nginx.conf /etc/nginx/conf.d/default.conf
echo

echo $'\e[1;94m'"NILDB"$'\e[m'
PREFIX="src/4/docs/nildb"
TEMPLATE="src/4/docs/freetnil/build/templates/category.html"
for file in "$PREFIX"/!(_*).yml "$PREFIX"/**/!(_*).yml; do
  target="www/4/docs/${file##$PREFIX/}"
  target="${target%%.yml}.html"
  if newer "$file" "$target" || newer "$TEMPLATE" "$target"; then
    ./src/4/docs/freetnil/build/scripts/convert-one.sh "$file" "$TARGET/$target" "$TEMPLATE" >/dev/null
  fi
done
echo

echo $'\e[1;94m'"Outdated files"$'\e[m'
echo "$TARGET"/www/SITEMAP.html >> .checked
sort -ru < .unchecked > .unchecked~
sort -ru < .checked   > .checked~
diff .checked~ .unchecked~ | sed '/^>/!d;s/^> //' \
  | while read -r file; do
      echo "Removing $file"
      rm "$file"
    done
echo

echo $'\e[1;94m'"Sitemap"$'\e[m'
test -e "$TARGET"/www/SITEMAP.html || echo > "$TARGET"/www/SITEMAP.html
tree -ni --noreport target/www > .tmp
tree=$(tree -nf --noreport target/www | paste -d'\t' - .tmp | sed '1d;s|── target/www/|── <a href="|;s|\t|">|;s|$|</a>|')
echo "<pre>"$'\n'"$tree"$'\n'"</pre>" \
  | replace /www/SITEMAP.html
echo

rm .{,un}checked{,~}

echo $'\e[1;94m'"Docker image"$'\e[m'
docker build -t ithkuil.place . >/dev/null
echo

echo $'\e[1;92m'"Done!"$'\e[m'
