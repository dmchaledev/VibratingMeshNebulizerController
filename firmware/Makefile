# Makefile for the Nimbus Nebulizer Controller firmware.
#
# Targets:
#   all       (default)  build firmware/build/nebulizer.hex
#   program              flash via MPLAB Snap (override PROGRAMMER=pickit4|pickit5)
#   clean                delete build/
#   test                 build and run host-side unit tests (firmware/tests/)
#
# Override anything from the command line, e.g.:
#   make CC=/opt/microchip/xc8/v2.46/bin/xc8-cc PROGRAMMER=pickit5

DEVICE      ?= 16F1713
CC          ?= xc8-cc
OPT         ?= -O1
CFLAGS      ?= -mcpu=$(DEVICE) $(OPT) -Wall
PROGRAMMER  ?= snap
MDB         ?= mdb.sh

SRC_DIR     := src
BUILD_DIR   := build
TARGET      := $(BUILD_DIR)/nebulizer.hex

SOURCES     := $(wildcard $(SRC_DIR)/*.c)
HEADERS     := $(wildcard $(SRC_DIR)/*.h)

.PHONY: all clean program test help

all: $(TARGET)

$(TARGET): $(SOURCES) $(HEADERS) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $(SOURCES)

$(BUILD_DIR):
	mkdir -p $@

program: $(TARGET)
	$(MDB) -e "device PIC$(DEVICE); hwtool $(PROGRAMMER); program $(TARGET); quit"

clean:
	rm -rf $(BUILD_DIR)

test:
	$(MAKE) -C tests

help:
	@echo "Targets: all (default), program, clean, test"
	@echo "Variables: DEVICE=$(DEVICE) CC=$(CC) PROGRAMMER=$(PROGRAMMER)"
