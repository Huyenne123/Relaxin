ROOT := $(abspath ../..)
SHELL := /bin/bash

.PHONY: all test-clearsword-discovery test-momentarius-discovery clean validate_gpu_map

all: test-clearsword-discovery test-momentarius-discovery

test-clearsword-discovery:
	@bash ./run_clearsword_discovery.sh

test-momentarius-discovery:
	@bash ./run_momentarius_discovery.sh

clean:
	@rm -rf "$(ROOT)/build/Tests/ClearSwordDiscovery" "$(ROOT)/build/Tests/MomentariusDiscovery" "$(ROOT)/build/Tests/validate-gpu-map"

BUILD := $(ROOT)/build/Tests/validate-gpu-map
TEST := $(BUILD)/validate_gpu_map

CC ?= cc
CFLAGS := -std=c11 -Wall -Wextra -Werror -g

all: $(TEST)

$(TEST): validate_gpu_map.c
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

validate_gpu_map: $(TEST)

test: $(TEST)
	$(TEST) A12 0x07D34B9F 0x100000000
