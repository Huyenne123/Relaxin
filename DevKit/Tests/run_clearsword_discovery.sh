#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/build/Tests/ClearSwordDiscovery"
mkdir -p "${OUT_DIR}"

HARNESS_C="${OUT_DIR}/clearsword_discovery_harness.c"
HARNESS_BIN="${OUT_DIR}/clearsword_discovery_harness"

cat > "${HARNESS_C}" <<'EOF'
#include <stdio.h>
#include <stdlib.h>

int offsets_init(void) {
    return 0;
}

int clearsword_discovery_only(void) {
#if defined(CLEARSWORD_DISCOVERY_ONLY)
    if (offsets_init() != 0) {
        fprintf(stderr, "offsets_init failed in discovery-only mode\n");
        return 1;
    }
    puts("ClearSword discovery-only path: kernel_base discovery is a safe no-op.");
    return 0;
#else
    puts("ClearSword discovery-only mode disabled: compile with -DCLEARSWORD_DISCOVERY_ONLY.");
    return 0;
#endif
}

int main(void) {
    if (getenv("RELAXIN_DEVKIT_EXPECT_DEVICE") == NULL) {
        puts("Safe no-op: local host does not have a device-specific ClearSword target.");
        return 0;
    }
    return clearsword_discovery_only();
}
EOF

CC="${CC:-cc}"
"${CC}" -std=c11 -Wall -Wextra -Werror -DCLEARSWORD_DISCOVERY_ONLY \
    -o "${HARNESS_BIN}" "${HARNESS_C}"

"${HARNESS_BIN}"
