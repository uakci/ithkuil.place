#!/bin/bash
set -e

NAME=ithkuil.place
REPO=https://github.com/uakci/ithkuil.place

self="$(realpath "$0")"
lock="$(dirname "$self")/pull.lock"

if [ -e "$lock" ]; then
  echo waiting for process $(cat "$lock") to finish…
  while [ -e "$lock" ]; do sleep 1; done
fi
echo $$ > "$lock"
trap 'error $LINENO $?' ERR

error() {
  echo error on line $1: "$(sed $1q\;d $self)" >&2
  rm "$lock"
  exit $2
}

run_image() {
  docker run -d -p 127.0.0.1:9997:80/tcp --name "$NAME" $1
}

remove_image() {
  if [ "$1" ]; then
    docker rmi "$1"
  fi
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

docker build -t "$NAME" .
new_image=$(docker images "$NAME":latest -q)

if [ "$(docker ps -qaf name=/ithkuil.place)" ]; then
  unplug
fi
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
