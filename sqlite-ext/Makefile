SDK      := $(shell xcrun --show-sdk-path)
CC       := clang
CFLAGS   := -fPIC -dynamiclib \
             -isysroot $(SDK) \
             -I/opt/homebrew/opt/sqlite/include \
             -std=c11 \
             -Wall -Wextra \
             -Wno-deprecated-declarations
LDFLAGS  := -framework CoreServices -undefined dynamic_lookup
TARGET   := build/htb_ext.dylib
INSTALL  := $(HOME)/.local/lib/htb_ext.dylib
LITECLI  := $(HOME)/.config/litecli/config

.PHONY: all clean install configure-litecli

all: $(TARGET)

$(TARGET): htb_ext.c | build
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

build:
	mkdir -p build

clean:
	rm -rf build

install: $(TARGET)
	mkdir -p $(HOME)/.local/lib
	cp $(TARGET) $(INSTALL)
	@echo "Installed to $(INSTALL)"

configure-litecli: install
	@if grep -q 'htb_ext' $(LITECLI) 2>/dev/null; then \
	    echo "litecli already configured"; \
	else \
	    printf '\n[startup_commands]\ncommands = ".load $(INSTALL)"\n' >> $(LITECLI); \
	    echo "Added startup_commands to $(LITECLI)"; \
	fi
