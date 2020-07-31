#!/bin/bash
set -e
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
  docker run -d -p 127.0.0.1:9997:80/tcp --name ithkuil.place $1
}

remove_image() {
  if [ "$1" ]; then
    docker rmi "$1"
  fi
}

unplug() {
  docker stop ithkuil.place || :
  docker rm ithkuil.place
}

if [ ! -e ithkuil.place ]; then
  git clone https://github.com/uakci/ithkuil.place
  cd ithkuil.place
else
  cd ithkuil.place
  git pull --force
fi
old_image=$(docker images ithkuil.place:latest -q)

docker build -t ithkuil.place .
new_image=$(docker images ithkuil.place:latest -q)

if [ "$(docker ps -qaf name=/ithkuil.place)" ]; then
  unplug
fi
run_image $new_image
sleep 2

if [ ! "$(docker inspect ithkuil.place | jq -r '.[0].State.ExitCode')" = 0 ]; then
  unplug
  remove_image $new_image
  run_image $old_image
elif [ ! "$new_image" = "$old_image" ]; then
  remove_image $old_image
fi

rm "$lock"
