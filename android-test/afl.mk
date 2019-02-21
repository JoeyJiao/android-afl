LOCAL_CLANG := true
LOCAL_CC := AFL_PATH=$(HOST_OUT)/afl AFL_CC=$(CLANG) $(HOST_OUT)/bin/afl-clang-fast
LOCAL_CXX := AFL_PATH=$(HOST_OUT)/afl AFL_CXX=$(CLANG_CXX) $(HOST_OUT)/bin/afl-clang-fast++
