#!/bin/sh
head -n1 /etc/apk/repositories | \
  sed 's#/[^/]*/main$#/edge/testing#' >> /etc/apk/repositories
apk add --no-cache bash nginx pandoc tree sed
