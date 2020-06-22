#!/usr/bin/env bash

source .env.keystore
if [ -z "$KEYSTORE" ]; then
  echo "Please set KEYSTORE, KEY_ALIAS and APKSIGNER in .env.keystore"
  exit 1
fi
pushd android
./gradlew assemblePubRelease
popd
$APKSIGNER sign --ks $KEYSTORE --ks-key-alias $KEY_ALIAS --ks-pass stdin --key-pass stdin android/app/build/outputs/apk/pub/release/app-pub-release.apk