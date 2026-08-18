# GPU RVBAR device map

This directory stores the host-side RVBAR map used by the Momentarius and ClearSword porting flow. The CSV intentionally keeps the `rvbar_pa` field empty for rows whose live GPU mapping must still be measured on a target device.

## CSV format

`device_machine,cpufamily,rvbar_pa`

- `device_machine`: the device family or machine identifier (for example `A12`, `A15/M2`, or a live `uname -m`/`sysctl` machine string).
- `cpufamily`: the runtime `hw.cpufamily` value from the Relaxin target confirmation path.
- `rvbar_pa`: the physical address for the GPU RVBAR region. Leave blank when the value is not yet known and describe the source to fill it in.

## How to add entries

1. Confirm the exact device or SoC family in `RelaxinEngine/Stages/Preflight/RLXTargetConfirmationTask.m`.
2. Match it to the corresponding family key in `RelaxinEngine/KernelAccess/Exploit/Rocket/Profile/Platform.h` or `Vendor/Dopamine/BaseBin/XPF` metadata.
3. Record the device machine and CPU family in `gpu_rvbar.csv`.
4. Collect the live physical address from a target device using the same `phystokv` / `early_kread64` validation path used by the project.
5. Replace the blank `rvbar_pa` entry with the measured value once confirmed.

Known CPU-family values already used in the project:

- A12: `0x07D34B9F`
- A13: `0x462504D2`
- A14/M1: `0x1B588BB3`
- A15/M2: `0xDA33D83D`
- A16: `0x8765EDEA`
- A17: `0x2876F5B5`

## Validation flow

`DevKit/validate-gpu-map.sh` reads the CSV and skips rows whose `rvbar_pa` is empty. For each populated row it compiles or runs the harness in `DevKit/tests/validate_gpu_map.c`.

The harness exercises the same primitive wrappers used by Relaxin:

- `Vendor/Dopamine/BaseBin/libjailbreak/src/translation.h` exports `phystokv(uint64_t pa)`.
- `RelaxinEngine/KernelAccess/Exploit/Rocket/Internal/Compat.h` declares `early_kread64(uint64_t where)`.

The validation only performs a dry-read check and never writes to the target. It exits non-zero when a mapped PA is malformed, out of range, or translated to an inaccessible host address.

## Manual-testing note

This map is intended for manual validation on a supported, attached device. It should not be treated as a CI-only assertion, because the host environment usually does not expose the runtime kernel/GPU MMIO translation required to resolve the live RVBAR values.
