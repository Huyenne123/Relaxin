ROOT := $(abspath ../..)
SHELL := /bin/bash

.PHONY: all test-clearsword-discovery clean

all: test-clearsword-discovery

test-clearsword-discovery:
	@bash ./run_clearsword_discovery.sh

clean:
	@rm -rf "$(ROOT)/build/Tests/ClearSwordDiscovery"
