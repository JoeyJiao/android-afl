LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := crash.c
LOCAL_CFLAGS := -static -g -O0
LOCAL_MODULE := afl-crash

ifeq ($(TEST_GCC_ARM), true)
export AFL_CC := $(TARGET_CC)
# expoet AFL_CXX := $(TARGET_CXX)
#export TARGET_TOOLCHAIN_PREFIX := ./prebuilts/clang/host/linux-x86/clang-4691093/bin/
export AFL_AS := $(TARGET_TOOLCHAIN_PREFIX)as
LOCAL_CLANG := false
LOCAL_CC := afl-gcc
# LOCAL_CXX := afl-g++
include $(BUILD_EXECUTABLE)
endif

ifeq ($(TEST_GCC_HOST), true)
export AFL_CC=$(HOST_CC)
# export AFL_CXX=$(HOST_CXX)
LOCAL_MULTILIB := 32
#export HOST_TOOLCHAIN_PREFIX := ./prebuilts/clang/host/linux-x86/clang-4691093/bin/
export AFL_AS=$(HOST_TOOLCHAIN_PREFIX)as
LOCAL_CLANG := true
LOCAL_CC := afl-gcc
# LOCAL_CXX := afl-g++
include $(BUILD_HOST_EXECUTABLE)
endif

ifeq ($(TEST_CLANG_ARM), true)
export AFL_AS=prebuilts/gcc/linux-x86/x86/x86_64-linux-android-4.9/x86_64-linux-android/bin/as
#export AFL_AS=prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/aarch64-linux-android/bin/as
LOCAL_CLANG := true
LOCAL_CC := AFL_CC=$(CLANG) afl-clang
LOCAL_CXX := AFL_CXX=$(CLANG_CXX) afl-clang++
LOCAL_FORCE_STATIC_EXECUTABLE := true
include $(BUILD_EXECUTABLE)
endif

ifeq ($(TEST_CLANG_HOST), true)
export AFL_CC=$(CLANG)
# export AFL_CXX=$(CLANG_CXX)
export AFL_AS=prebuilts/gcc/linux-x86/x86/x86_64-linux-android-4.9/x86_64-linux-android/bin/as
LOCAL_CLANG := true
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_CC := afl-clang
# LOCAL_CXX := afl-clang++
include $(BUILD_HOST_EXECUTABLE)
endif

ifeq ($(TEST_CLANG_FAST_ARM), true)
LOCAL_MULTILIB := 32
LOCAL_LDFLAGS := $(HOST_OUT)/afl/afl-llvm-rt-32.o
include android-afl/android-test/afl.mk
include $(BUILD_EXECUTABLE)
endif

ifeq ($(TEST_CLANG_FAST_AARCH64), true)
LOCAL_MULTILIB := 64
#LOCAL_LDFLAGS := $(HOST_OUT)/afl/afl-llvm-rt-64.o
include android-afl/android-test/afl.mk
include $(BUILD_EXECUTABLE)
endif

ifeq ($(TEST_CLANG_FAST_HOST), true)
LOCAL_MULTILIB := 64
LOCAL_LDFLAGS := $(HOST_OUT)/afl/afl-llvm-rt-host-64.o
include android-afl/android-test/afl.mk
include $(BUILD_HOST_EXECUTABLE)
endif

ifeq ($(TEST_CLANG_FAST_HOST_32), true)
LOCAL_MULTILIB := 32
LOCAL_LDFLAGS := $(HOST_OUT)/afl/afl-llvm-rt-host-32.o
include android-afl/android-test/afl.mk
include $(BUILD_HOST_EXECUTABLE)
endif
