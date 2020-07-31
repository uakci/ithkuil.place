#!/bin/busybox sh
set -e

apk add node npm

npm install
npm start

apk del node npm
