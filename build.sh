#!/bin/bash
set -e; shopt -s nullglob globstar extglob
trap 'error $LINENO $?' ERR

## utilities ##

error() {
  echo $'\e[31m'"Status code $2 on line $1: "$'\e[m'"$(sed "$1q;d" "$0")" >&2
  echo $'\e[1;91m'"Exiting due to failure"$'\e[m' >&2 exit "$2"
}

update() {
  local this="${1%%/}"
  local other="${2-$this}"
  test "${other%%/}" = "$other" \
    || other="$other$(basename "$this")"
  other="${other##/}" other="${other:-/}"
  mkdir -p "$TARGET/$(dirname "$other")"
  while read -r line; do count; echo "$line"; done \
    < <(cp -urvT "$this" "$TARGET/$other")
  find "$this" | while read -r file; do
    local fname="$TARGET/$other${file##$this}"
    # shellcheck disable=SC2015
    if [ -d "$fname" ]; then fname="$fname/"; fi
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
  if ! test -e "$rev" || ! diff -q .tmp "$rev" >/dev/null; then
    update .tmp "$1"
    count
  fi
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
    count
  fi
  echo "$other" >> .checked
  also_parents "${2-$1}"
  return $status
}

## ## ##

ENSURE_INSTALLED=(docker git pandoc tree flock)
toolage() {
  for ensuree in "${ENSURE_INSTALLED[@]}"; do
    path=$(which "$ensuree" 2>/dev/null || :)
    test "$path" || {
      echo $'\e[91m'"You don’t seem to have $ensuree installed."$'\e[m' >&2
      exit 42
    }
    echo -n "$path: "
    "$path" --version | head -n1
  done
}

populate_index() {
  echo "$TARGET/" > .checked
  find "$TARGET" | while read -r line; do
    test -d "$line" && line="${line%%/}/"
    echo "$line"
  done > .unchecked
}

git_info() {
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
}

auxiliary() {
  update www/ /
  update LICENSE /www/
  update nginx.conf /etc/nginx/conf.d/default.conf
}

nildb() {
  PREFIX="src/4/docs/nildb"
  TEMPLATE="src/4/docs/freetnil/build/templates/category.html"
  for file in "$PREFIX"/!(_*).yml "$PREFIX"/**/!(_*).yml; do
    target="www/4/docs/${file##$PREFIX/}" target="${target%%.yml}.html"
    if newer "$file" "$target" || newer "$TEMPLATE" "$target"; then
      ./src/4/docs/freetnil/build/scripts/convert-one.sh "$file" "$TARGET/$target" "$TEMPLATE" >/dev/null
    fi
  done
}

outdated_files() {
  echo "$TARGET"/www/SITEMAP.html >> .checked
  sort -ru < .unchecked > .unchecked~
  sort -ru < .checked   > .checked~
  diff .checked~ .unchecked~ | sed '/^>/!d;s/^> //' \
    | while read -r file; do
        echo "Removing $file"
        count
        rm "$file"
      done
}

sitemap() {
  test -e "$TARGET"/www/SITEMAP.html || echo > "$TARGET"/www/SITEMAP.html
  tree -ni --noreport target/www > .tmp
  tree=$(tree -nf --noreport target/www | paste -d'\t' - .tmp | sed '1d;s|── target/www/|── <a href="|;s|\t|">|;s|$|</a>|')
  echo "<pre>"$'\n'"$tree"$'\n'"</pre>" \
    | replace /www/SITEMAP.html
}

docker_image() {
  docker build -t ithkuil.place . >/dev/null
}

unleader() {
  if test "$leader" -o "$1"; then
    echo -n $'\r\e[K'
    leader=
  fi
}

leader() {
  if test ! "$leader" -o "$1"; then
    echo -n $'\e[7m'"["$'\e[1m'"$numtasks"$'\e[0;7m'" tasks left; "$'\e[1m'"$(cat .numfiles)"$'\e[0;7m'" files modified]"$'\e[m'
    leader=1
  fi
}

leader=
leaderify() {
  flock 42
  local fd="$1"; shift
  unleader
  echo "$@" >&"$fd"
  leader
  flock -u 42
}

section() {
  local ord="$1" task_name="$2" status=0; shift 2
  echo $'\e[1;97m'"$task_name"$'\e[m'

  mkfifo ".out-$ord" ".err-$ord"
  "$@" > ".out-$ord" 2> ".err-$ord" & local pid="$!"
  while read -r out; do leaderify 1 "$out";                     done < ".out-$ord" & local outer="$!"
  while read -r err; do leaderify 2 $'\e[31m'"$err"$'\e[m' >&2; done < ".err-$ord" & local errer="$!"

  wait "$pid" || status="$?"
  wait "$outer"; wait "$errer"
  rm ".out-$ord" ".err-$ord"
  unleader --force
  if test "$status" = 0; then
    echo $'\e[1;92m'"$task_name"$'\e[0;92m'" ✓"$'\e[m'
    echo
    (( numtasks-- ))
  else
    echo $'\e[1;91m'"$task_name"$'\e[0;91m'" ✗"$'\e[m'
    echo
    return "$status"
  fi
}

count() {
  echo >> .counter
}

counterer() {
  local numfiles=0
  echo 0 > .numfiles
  while test -p .counter; do
    while read -rt1; do
      (( numfiles++ ))
      echo "$numfiles" > .numfiles
    done < .counter
  done
}

numtasks=8
main() {
  cd "$(dirname "$0")" 
  TARGET="${1-target}" TARGET="${TARGET%%/}"
  rm -f .out-* .err-* .leader-lock .counter .{,un}checked{,~} .tmp .numfiles
  exec 42>.leader-lock
  mkfifo .counter; counterer &

  section 0 "Toolage" toolage
  mkdir -p "$TARGET"
  section 1 "Populate index" populate_index

  section 2 "Git info"  git_info
  section 3 "Auxiliary" auxiliary
  section 4 "NILDB"     nildb

  section 5 "Outdated files" outdated_files
  section 6 "Sitemap"        sitemap
  section 7 "Docker image"   docker_image

  rm .{,un}checked{,~} .leader-lock .counter
  echo $'\e[1;92m'"Done!"$'\e[m'" ($(cat .numfiles) files modified)"
  rm .numfiles
}

if ! main "$@"; then
  echo $'\e[1;91m'"Exiting due to failure"$'\e[m' >&2
  exit 1
fi
