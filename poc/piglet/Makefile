TITLE := Kodi PS4 Piglet POC
VERSION := 0.1
TITLE_ID := KPS400001
CONTENT_ID := IV0000-KPS400001_00-PIGLETPOC000000
LIBS := -lc -lkernel -lScePigletv2VSH -lSceSysmodule -lSceSystemService
TOOLCHAIN := $(OO_PS4_TOOLCHAIN)
INTDIR := x64/Debug
CXX := clang++
LD := ld.lld
CXXFLAGS := --target=x86_64-pc-freebsd12-elf -fPIC -funwind-tables -c -I$(TOOLCHAIN)/include -isystem $(TOOLCHAIN)/include/c++/v1 -isysroot $(TOOLCHAIN)
LDFLAGS := -m elf_x86_64 -pie --script $(TOOLCHAIN)/link.x --eh-frame-hdr -L$(TOOLCHAIN)/lib $(LIBS) $(TOOLCHAIN)/lib/crt1.o
all: eboot.bin
$(INTDIR):
	mkdir -p $@
$(INTDIR)/main.o: main.cpp | $(INTDIR)
	$(CXX) $(CXXFLAGS) -o $@ $<
eboot.bin: $(INTDIR)/main.o
	$(LD) $< -o $(INTDIR)/piglet-poc.elf $(LDFLAGS)
	$(TOOLCHAIN)/bin/linux/create-fself -in=$(INTDIR)/piglet-poc.elf -out=$(INTDIR)/piglet-poc.oelf --eboot "$@" --paid 0x3800000000000035
clean:
	rm -rf $(INTDIR) eboot.bin
