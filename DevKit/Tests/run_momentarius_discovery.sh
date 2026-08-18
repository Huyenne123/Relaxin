#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/build/Tests/MomentariusDiscovery"
mkdir -p "${OUT_DIR}"

HARNESS_C="${OUT_DIR}/momentarius_discovery_harness.c"
HARNESS_BIN="${OUT_DIR}/momentarius_discovery_harness"
CSV_PATH="${ROOT_DIR}/DevKit/device-maps/gpu_rvbar.csv"
DEVICE_NAME="${RELAXIN_MOMENTARIUS_DEVICE:-A12}"

cat > "${HARNESS_C}" <<'EOF'
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int parse_u64(const char *text, uint64_t *value) {
    char *end = NULL;
    unsigned long long parsed = 0;

    if (text == NULL || value == NULL || *text == '\0') {
        return -1;
    }

    errno = 0;
    parsed = strtoull(text, &end, 0);
    if (errno != 0 || end == text || *end != '\0') {
        return -1;
    }

    *value = (uint64_t)parsed;
    return 0;
}

static void trim_inplace(char *text) {
    char *start = text;
    char *end = NULL;

    if (text == NULL) {
        return;
    }

    while (*start == ' ' || *start == '\t' || *start == '\r' || *start == '\n') {
        start++;
    }

    if (start != text) {
        memmove(text, start, strlen(start) + 1);
    }

    end = text + strlen(text);
    while (end > text && (*(end - 1) == ' ' || *(end - 1) == '\t' || *(end - 1) == '\r' || *(end - 1) == '\n')) {
        end--;
    }
    *end = '\0';
}

static int device_map_lookup(const char *device_machine, uint64_t *rvbar_pa) {
    static const char *paths[] = {
        "DevKit/device-maps/gpu_rvbar.csv",
        "./DevKit/device-maps/gpu_rvbar.csv",
        "../DevKit/device-maps/gpu_rvbar.csv",
        NULL,
    };

    if (device_machine == NULL || rvbar_pa == NULL) {
        return -1;
    }

    *rvbar_pa = 0;
    for (size_t i = 0; paths[i] != NULL; ++i) {
        FILE *fp = fopen(paths[i], "r");
        char line[256];

        if (fp == NULL) {
            continue;
        }

        while (fgets(line, sizeof(line), fp) != NULL) {
            char *saveptr = NULL;
            char *device = NULL;
            char *cpufamily = NULL;
            char *pa_text = NULL;
            uint64_t pa = 0;

            trim_inplace(line);
            if (line[0] == '\0' || line[0] == '#') {
                continue;
            }

            device = strtok_r(line, ",", &saveptr);
            if (device == NULL) {
                continue;
            }
            if (strcmp(device, "device_machine") == 0) {
                continue;
            }

            cpufamily = strtok_r(NULL, ",", &saveptr);
            pa_text = strtok_r(NULL, ",", &saveptr);
            if (cpufamily == NULL || pa_text == NULL) {
                continue;
            }

            trim_inplace(device);
            trim_inplace(cpufamily);
            trim_inplace(pa_text);

            if (strcmp(device, device_machine) == 0 && parse_u64(pa_text, &pa) == 0 && pa != 0) {
                fclose(fp);
                *rvbar_pa = pa;
                return 0;
            }
        }
        fclose(fp);
    }

    return -1;
}

int main(void) {
    const char *device = getenv("RELAXIN_MOMENTARIUS_DEVICE");
    uint64_t rvbar_pa = 0;
    uint64_t text_pa = 0;

    if (device == NULL || device[0] == '\0') {
        puts("Momentarius discovery: no device-specific target configured; skipping safely.");
        return 0;
    }

    if (device_map_lookup(device, &rvbar_pa) != 0) {
        printf("Momentarius discovery: no RVBAR entry for %s in DevKit/device-maps/gpu_rvbar.csv; skipping safely.\n", device);
        return 0;
    }

    text_pa = rvbar_pa & 0xFFFFFFFFEULL;
    printf("Momentarius discovery: %s -> RVBAR %#llx, text_pa %#llx (read-only, no writes).\n",
           device,
           (unsigned long long)rvbar_pa,
           (unsigned long long)text_pa);
    return 0;
}
EOF

CC="${CC:-cc}"
"${CC}" -std=c11 -Wall -Wextra -Werror -DMOMENTARIUS_ENABLED=0 \
    -o "${HARNESS_BIN}" "${HARNESS_C}"

"${HARNESS_BIN}"
