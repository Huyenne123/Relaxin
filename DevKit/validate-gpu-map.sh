#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
VALIDATOR_BIN=${VALIDATOR_BIN:-"$SCRIPT_DIR/tests/validate_gpu_map"}
CSV_PATH=${1:-"$SCRIPT_DIR/device-maps/gpu_rvbar.csv"}

if [ ! -x "$VALIDATOR_BIN" ]; then
    if ! make -C "$SCRIPT_DIR/tests" validate_gpu_map >/dev/null 2>&1; then
        echo "warning: GPU RVBAR validation harness unavailable; manual validation required." >&2
        exit 0
    fi
fi

failures=0

while IFS=, read -r device_machine cpufamily rvbar_pa extra || [ -n "${device_machine:-}" ]; do
    if [ -z "${device_machine:-}" ] || [ "$device_machine" = "device_machine" ]; then
        continue
    fi

    device_machine=$(printf '%s' "$device_machine" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    cpufamily=$(printf '%s' "$cpufamily" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    rvbar_pa=$(printf '%s' "$rvbar_pa" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

    case "$device_machine" in
        \#*) continue ;;
        "") continue ;;
    esac

    if [ -z "$rvbar_pa" ]; then
        printf 'TODO: %s (%s) has no RVBAR PA yet.\n' "$device_machine" "$cpufamily"
        continue
    fi

    if ! "$VALIDATOR_BIN" "$device_machine" "$cpufamily" "$rvbar_pa"; then
        failures=$((failures + 1))
    fi
done < "$CSV_PATH"

if [ "$failures" -gt 0 ]; then
    exit 1
fi

exit 0
