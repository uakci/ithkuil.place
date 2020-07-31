#!/bin/busybox sh
set -e

apk add nodejs npm

npm install
npm start

apk del nodejs npm
