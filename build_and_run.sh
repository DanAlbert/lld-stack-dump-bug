#!/usr/bin/env bash

set -e

HERE=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

ANDROID_ABI=arm64-v8a
ANDROID_NATIVE_API_LEVEL=29

if [ -z "$ANDROID_NDK" ]; then
  >&2 echo "Must set ANDROID_NDK"
  exit 1
fi

function compile()
{
  printf '\nConfigure & Compile test applications ...\n\n'

  rm -rf $HERE/build-bfd
  mkdir "$HERE/build-bfd"

  cd "$HERE/build-bfd"

  cmake \
    -G Ninja \
    -DCMAKE_BUILD_TYPE:STRING=Debug \
    -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ANDROID_ABI \
    -DANDROID_PLATFORM=android-$ANDROID_NATIVE_API_LEVEL \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$HERE/bin \
    -DANDROID_LD=deprecated \
    "$HERE/application"

  cmake --build . -- -j1 -v

  rm -rf $HERE/build-lld
  mkdir "$HERE/build-lld"

  cd "$HERE/build-lld"

  cmake \
    -G Ninja \
    -DCMAKE_BUILD_TYPE:STRING=Debug \
    -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ANDROID_ABI \
    -DANDROID_PLATFORM=android-$ANDROID_NATIVE_API_LEVEL \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$HERE/bin \
    -DANDROID_LD=lld \
    "$HERE/application"

  cmake --build . -- -j1 -v

  printf '\nConfigure & Compile test applications DONE\n\n'
}

function run()
{
  printf '\nRun with & without LLD\n'

  adb logcat -c

  adb push $HERE/bin/application /data/local/tmp/
  adb push $HERE/bin/application-lld /data/local/tmp/

  set +e

  adb shell /data/local/tmp/application
  adb shell /data/local/tmp/application-lld

  set -e
}

function crash_dump()
{
  printf '\nCrash dumps:\n\n'
  adb logcat -d | $ANDROID_NDK/ndk-stack -sym $HERE/bin
}

compile
run
crash_dump
