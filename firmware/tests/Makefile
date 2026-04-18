# Host-side firmware unit tests. Run with `make` (or `make -C firmware/tests`
# from the repo root). Each test program is built standalone and is
# considered passing if it returns exit code 0.

CC      ?= cc
CFLAGS  ?= -std=c99 -Wall -Wextra -Wpedantic -Werror -O0 -g
BUILD   := build

TESTS := test_config_math test_battery test_lcd_format

.PHONY: all run clean

all: run

run: $(addprefix $(BUILD)/, $(TESTS))
	@status=0; \
	for t in $(TESTS); do \
	    echo "--- running $$t ---"; \
	    if ! $(BUILD)/$$t; then status=1; fi; \
	done; \
	if [ $$status -ne 0 ]; then \
	    echo "TESTS FAILED"; exit 1; \
	else \
	    echo "ALL TESTS PASSED"; \
	fi

$(BUILD)/%: %.c harness.h | $(BUILD)
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
