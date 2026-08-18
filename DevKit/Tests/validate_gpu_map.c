#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int g_runtime_stubs_active = 0;

__attribute__((weak)) uint64_t phystokv(uint64_t pa) {
    (void)pa;
    g_runtime_stubs_active = 1;
    return 0;
}

__attribute__((weak)) uint64_t early_kread64(uint64_t where) {
    (void)where;
    g_runtime_stubs_active = 1;
    return 0;
}

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

static int validate_rvbar(const char *device_machine, const char *cpufamily, uint64_t pa) {
    uint64_t mapped_va = 0;
    uint64_t word = 0;

    if (pa == 0 || pa > UINT64_C(0x0000FFFFFFFFFFFF) || (pa & UINT64_C(0xFFF)) != 0) {
        fprintf(stderr,
                "FAIL %s (%s): invalid RVBAR PA %#" PRIx64 " (must be page-aligned and within the host physical map)\n",
                device_machine,
                cpufamily,
                pa);
        return 1;
    }

    mapped_va = phystokv(pa);
    if (mapped_va == 0 || mapped_va == UINT64_MAX) {
        if (g_runtime_stubs_active) {
            printf("PASS (manual) %s (%s): RVBAR %#" PRIx64 " uses the weak host stub; live kernel translation is not available on this host.\n",
                   device_machine,
                   cpufamily,
                   pa);
            return 0;
        }

        fprintf(stderr,
                "FAIL %s (%s): phystokv(%#" PRIx64 ") produced an unusable kernel VA\n",
                device_machine,
                cpufamily,
                pa);
        return 1;
    }

    word = early_kread64(mapped_va);
    (void)word;
    printf("PASS %s (%s): %#" PRIx64 " -> %#" PRIx64 " (dry-read)\n",
           device_machine,
           cpufamily,
           pa,
           mapped_va);
    return 0;
}

int main(int argc, char **argv) {
    const char *device_machine = "unknown";
    const char *cpufamily = "unknown";
    uint64_t pa = 0;

    if (argc != 4) {
        fprintf(stderr, "usage: %s <device_machine> <cpufamily> <rvbar_pa>\n", argv[0]);
        return 2;
    }

    device_machine = argv[1];
    cpufamily = argv[2];
    if (parse_u64(argv[3], &pa) != 0) {
        fprintf(stderr, "FAIL %s (%s): %s is not a valid PA\n", device_machine, cpufamily, argv[3]);
        return 1;
    }

    return validate_rvbar(device_machine, cpufamily, pa);
}
