ROOT := $(abspath ../..)
SHELL := /bin/bash

.PHONY: all test-clearsword-discovery clean

all: test-clearsword-discovery

test-clearsword-discovery:
	@bash ./run_clearsword_discovery.sh

clean:
	@rm -rf "$(ROOT)/build/Tests/ClearSwordDiscovery"
BUILD := $(ROOT)/build/Tests/validate-gpu-map
TEST := $(BUILD)/validate_gpu_map

CC ?= cc
CFLAGS := -std=c11 -Wall -Wextra -Werror -g

.PHONY: all test clean validate_gpu_map

all: $(TEST)

$(TEST): validate_gpu_map.c
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

validate_gpu_map: $(TEST)

test: $(TEST)
	$(TEST) A12 0x07D34B9F 0x100000000

clean:
	rm -rf $(BUILD)
