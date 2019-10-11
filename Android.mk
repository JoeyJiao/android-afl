LOCAL_PATH := $(call my-dir)

PROGNAME = afl
VERSION = $(shell grep '^\#define VERSION ' config.h | cut -d '"' -f2)

PREFIX ?= $(HOST_OUT)
BIN_PATH = $(PREFIX)/bin
HELPER_PATH = $(PREFIX)/afl
DOC_PATH = $(PREFIX)/share/doc/afl
MISC_PATH = $(PREFIX)/share/afl

common_CFLAGS ?= -O0 -funroll-loops
common_CFLAGS += -Wall -g -Wno-pointer-sign -Wno-pointer-arith \
	-Wno-sign-compare -Wno-unused-parameter \
	-Wno-unused-function -Wno-format -Wno-user-defined-warnings \
	-DAFL_PATH=\"$(HELPER_PATH)\" -DDOC_PATH=\"$(DOC_PATH)\" \
	-DBIN_PATH=\"$(BIN_PATH)\"

ifdef AFL_TRACE_PC
  common_CFLAGS    += -DUSE_TRACE_PC=1
endif

#################################afl-gcc#################################

include $(CLEAR_VARS)

ALL_TOOLS := \
	afl-g++ \
	afl-clang \
	afl-clang++ \

LOCAL_SRC_FILES := afl-gcc.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-gcc
LOCAL_POST_INSTALL_CMD := $(hide) $(foreach t,$(ALL_TOOLS),ln -sf afl-gcc $(BIN_PATH)/$(t);)
include $(BUILD_HOST_EXECUTABLE)

#################################afl-as#################################

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-as.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-as
LOCAL_MODULE_PATH := $(HELPER_PATH)
LOCAL_POST_INSTALL_CMD := $(hide) ln -sf afl-as $(LOCAL_MODULE_PATH)/as;
include $(BUILD_HOST_EXECUTABLE)

#################################afl-fuzz#################################

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-fuzz.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-fuzz
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-fuzz.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_LDLIBS := -ldl
LOCAL_MODULE := afl-fuzz
include $(BUILD_HOST_EXECUTABLE)

include $(CLEAR_VARS)

#################################afl-showmap#################################

LOCAL_SRC_FILES := afl-showmap.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-showmap
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-showmap.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-showmap
include $(BUILD_HOST_EXECUTABLE)

#################################afl-tmin#################################

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-tmin.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-tmin
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-tmin.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-tmin
include $(BUILD_HOST_EXECUTABLE)

#################################afl-analyze#################################

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-analyze.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-analyze
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-analyze.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-analyze
include $(BUILD_HOST_EXECUTABLE)

#################################afl-gotcpu#################################

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-gotcpu.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-gotcpu
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := afl-gotcpu.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-gotcpu
include $(BUILD_HOST_EXECUTABLE)

#################################afl-clang-fast#################################

include $(CLEAR_VARS)

LOCAL_SRC_FILES := llvm_mode/afl-clang-fast.c
LOCAL_CLANG := true
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-clang-fast
LOCAL_POST_INSTALL_CMD := $(hide) ln -sf afl-clang-fast $(BIN_PATH)/afl-clang-fast++;
include $(BUILD_HOST_EXECUTABLE)

#################################afl-llvm-pass.so#################################

include $(CLEAR_VARS)
LLVM_CONFIG := llvm-config
ifeq ($(USE_PREBUILT_LLVM_CONFIG), true)
LLVM_CONFIG_CXXFLAGS := -I/usr/lib/llvm-3.5/include  -DNDEBUG -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -g -O2 -fomit-frame-pointer -fvisibility-inlines-hidden -fno-exceptions -fPIC -Woverloaded-virtual -Wcast-qual 
else
LLVM_CONFIG_CXXFLAGS := $(shell $(LLVM_CONFIG) --cxxflags)
LLVM_CONFIG_LDFLAGS := $(shell $(LLVM_CONFIG) --ldflags)
endif

LOCAL_SRC_FILES := llvm_mode/afl-llvm-pass.cpp
LOCAL_C_INCLUDES += $(shell dirname $(dir $(CLANG)))/include
ifeq ($(AFL_TRACE_PC), true)
LOCAL_CPPFLAGS := -fno-rtti -fpic $(common_CFLAGS) -Wno-variadic-macros
else
LOCAL_CPPFLAGS := $(LLVM_CONFIG_CXXFLAGS) -fno-rtti -fpic $(common_CFLAGS) -Wno-variadic-macros
endif

LOCAL_MULTILIB := 64
LOCAL_ALLOW_UNDEFINED_SYMBOLS := true
LOCAL_MODULE := afl-llvm-pass
LOCAL_POST_INSTALL_CMD := $(hide) cp -f $(HOST_OUT)/lib64/afl-llvm-pass.so $(HELPER_PATH)/afl-llvm-pass.so;
include $(BUILD_HOST_SHARED_LIBRARY)

################################afl-llvm-rt#################################

include $(CLEAR_VARS)

LOCAL_SRC_FILES := llvm_mode/afl-llvm-rt.o.c
LOCAL_CLANG := true
LOCAL_MULTILIB := both
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-llvm-rt
ifeq ($(TARGET_2ND_ARCH),)
LOCAL_POST_INSTALL_CMD := $(hide) mkdir -p $(HELPER_PATH); \
	$(hide) cp -f $(TARGET_OUT_INTERMEDIATES)/SHARED_LIBRARIES/afl-llvm-rt_intermediates/llvm_mode/afl-llvm-rt.o.o $(HELPER_PATH)/afl-llvm-rt-32.o;
else
LOCAL_POST_INSTALL_CMD := $(hide) mkdir -p $(HELPER_PATH); \
	$(hide) cp -f $(TARGET_OUT_INTERMEDIATES)/SHARED_LIBRARIES/afl-llvm-rt_intermediates/llvm_mode/afl-llvm-rt.o.o $(HELPER_PATH)/afl-llvm-rt-64.o; \
	cp -f $(TARGET_OUT_INTERMEDIATES)_$(TARGET_2ND_ARCH)/SHARED_LIBRARIES/afl-llvm-rt_intermediates/llvm_mode/afl-llvm-rt.o.o $(HELPER_PATH)/afl-llvm-rt-32.o; \
	cp -f $(TARGET_OUT_INTERMEDIATES)/SHARED_LIBRARIES/afl-llvm-rt_intermediates/llvm_mode/afl-llvm-rt.o.o $(HELPER_PATH)/afl-llvm-rt.o;
endif
include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := llvm_mode/afl-llvm-rt.o.c
LOCAL_CLANG := true
LOCAL_MULTILIB := both
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MODULE := afl-llvm-rt.vendor
LOCAL_PROPRIETARY_MODULE := true
include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := llvm_mode/afl-llvm-rt.o.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MULTILIB := 64
LOCAL_MODULE := afl-llvm-rt
LOCAL_POST_INSTALL_CMD := $(hide) cp -f $(HOST_OUT_INTERMEDIATES)/SHARED_LIBRARIES/afl-llvm-rt_intermediates/llvm_mode/afl-llvm-rt.o.o $(HELPER_PATH)/afl-llvm-rt-host.o; \
	cp -f $(HOST_OUT_INTERMEDIATES)/SHARED_LIBRARIES/afl-llvm-rt_intermediates/llvm_mode/afl-llvm-rt.o.o $(HELPER_PATH)/afl-llvm-rt-host-64.o;

include $(BUILD_HOST_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := llvm_mode/afl-llvm-rt.o.c
LOCAL_CFLAGS := $(common_CFLAGS)
LOCAL_MULTILIB := 32
LOCAL_MODULE := afl-llvm-rt
LOCAL_POST_INSTALL_CMD := $(hide) cp -f $(HOST_OUT_INTERMEDIATES)32/SHARED_LIBRARIES/afl-llvm-rt_intermediates/llvm_mode/afl-llvm-rt.o.o $(HELPER_PATH)/afl-llvm-rt-host-32.o;

include $(BUILD_HOST_SHARED_LIBRARY)
