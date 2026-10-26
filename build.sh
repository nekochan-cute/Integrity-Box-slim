#!/bin/sh
# usage: sh build.sh [--gradle]
set -e
cd "$(dirname "$0")"

if [ "$1" = "--gradle" ]; then
    (cd PlayIntegrityFork && sh gradlew --no-daemon assembleRelease)
fi
if [ ! -f PlayIntegrityFork/module/classes.dex ]; then
    echo "PlayIntegrityFork is not built, run: sh build.sh --gradle"
    exit 1
fi

ZIP=Integrity-Box-Slim-$(grep '^version=' module/module.prop | cut -d= -f2).zip
rm -rf out/module out/$ZIP
mkdir -p out/module
cp -R PlayIntegrityFork/module/. module/. out/module/
cp LICENSE out/module/
(cd out/module && zip -qr9 ../$ZIP .)
echo out/$ZIP
