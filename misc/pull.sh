#!/bin/bash
set -e

NAME=ithkuil.place
REPO=https://github.com/uakci/ithkuil.place
FLAGS="-p 127.0.0.1:9997:80/tcp"

self="$(realpath "$0")"
lock="$(dirname "$self")/pull.lock"

error() {
  echo error on line $1: "$(sed $1q\;d $self)" >&2
  rm "$lock"
  exit $2
}

trap 'error $LINENO $?' ERR

if [ -e "$lock" ]; then
  echo waiting for process $(cat "$lock") to finish…
  while [ -e "$lock" ]; do sleep 1; done
fi
echo $$ > "$lock"

run_image() {
  docker run -d $FLAGS --name "$NAME" $1
}

remove_image() {
  [ "$1" ] && docker rmi "$1"
}

unplug() {
  docker stop "$NAME" || :
  docker rm "$NAME"
}

if [ ! -e "$NAME" ]; then
  git clone "$REPO"
  cd "$NAME"
  git submodule update --init --recursive
else
  cd "$NAME"
  git pull --ff-only
  git submodule update --recursive --remote
fi
old_image=$(docker images "$NAME":latest -q)

./build.sh
docker build -t "$NAME" .
new_image=$(docker images "$NAME":latest -q)

[ "$(docker ps -qaf name=/"$NAME")" ] && unplug
run_image $new_image
sleep 2

if [ ! "$(docker inspect "$NAME" | jq -r '.[0].State.ExitCode')" = 0 ]; then
  unplug
  remove_image $new_image
  run_image $old_image
elif [ ! "$new_image" = "$old_image" ]; then
  remove_image $old_image
fi

rm "$lock"
