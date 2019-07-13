#!/bin/bash
set -e

CORES=$(cat /proc/cpuinfo | grep processor | wc -l)

usage() {
  echo "USAGE: $(basename $0) <Android Source Top directory>"
  echo
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

sudo apt install -y llvm-3.5
git clone https://github.com/JoeyJiao/android-afl

source build/envsetup.sh
lunch

cd build/soong
git apply android-afl/script/afl-for-soong-on-android-q.patch
cd -

cd android-afl
USE_PREBUILT_LLVM_CONFIG=true AFL_TRACE_PC=true mm -j${CORES}
cd -

TEST_CLANG_FAST_AARCH64=true make afl-crash
mv android-afl/android-test/Android.bp.bak android-afl/android-test/Android.bp
make afl-crash-bp
