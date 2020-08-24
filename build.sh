#!/bin/sh
# This script builds everything that Needs To Be Built™.
set -e

if [ ! -f /.dockerenv ]; then
  echo This script must be run in a container >&2
  exit 1
fi

# add ‘testing’ branch
head -n1 /etc/apk/repositories | \
  sed 's#/[^/]*/main$#/edge/testing#' >> /etc/apk/repositories
PACKAGES="pandoc bash"
apk add $PACKAGES

## NILDB
cd /src/4/docs/nildb
for dir in . */; do
  ../freetnil/build/scripts/convert-yaml-docs.sh "$dir" ../"$dir" \
    ../freetnil/build/templates/category.html
done
cd ..
rm -r nildb freetnil

apk del $PACKAGES
