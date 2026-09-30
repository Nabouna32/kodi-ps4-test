TITLE := Kodi PS4 GLES/Piglet POC
VERSION := 0.1
TITLE_ID := KODI00001
CONTENT_ID := IV0000-KODI00001_00-GLESPOC00000000

TOOLCHAIN := $(OO_PS4_TOOLCHAIN)
SAMPLE := $(TOOLCHAIN)/samples/piglet
COMMON := $(TOOLCHAIN)/samples/_common
BUILD := build

LIBS := -lc -lkernel -lc++ -lSceShellCoreUtil -lSceSysmodule -lSceSystemService -lScePigletv2VSH -lScePrecompiledShaders -lSceRtc
EXTRAFLAGS := -fexceptions -fcxx-exceptions
CFLAGS := --target=x86_64-pc-freebsd12-elf -fPIC -funwind-tables -c $(EXTRAFLAGS) -I$(COMMON) -I$(SAMPLE)/piglet -isysroot $(TOOLCHAIN) -isystem $(TOOLCHAIN)/include
CXXFLAGS := $(CFLAGS) -isystem $(TOOLCHAIN)/include/c++/v1
LDFLAGS := -m elf_x86_64 -pie --script $(TOOLCHAIN)/link.x --eh-frame-hdr -L$(TOOLCHAIN)/lib $(LIBS) $(TOOLCHAIN)/lib/crt1.o

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  CC := clang
  CXX := clang++
  LD := ld.lld
endif
ifeq ($(UNAME_S),Darwin)
  CC := /usr/local/opt/llvm/bin/clang
  CXX := /usr/local/opt/llvm/bin/clang++
  LD := /usr/local/opt/llvm/bin/ld.lld
endif

OBJ := $(BUILD)/main.o $(BUILD)/PigletApplication.o

all: $(BUILD)/kodi-ps4-gles-poc.elf

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/main.o: main.cpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -o $@ $<

$(BUILD)/PigletApplication.o: $(SAMPLE)/piglet/PigletApplication.cpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -o $@ $<

$(BUILD)/kodi-ps4-gles-poc.elf: $(OBJ)
	$(LD) $(OBJ) -o $@ $(LDFLAGS)

clean:
	rm -rf $(BUILD)

.PHONY: all clean
