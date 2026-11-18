# HP 15s-fr5009TU (`8086:46B3` rev `0C`, VCS2-Only) — Diagnostic Evidence Bundle

This directory contains the complete, privacy-sanitized raw outputs referenced in:
- Upstream issue: [`b00t0x/WhateverXe#169`](https://github.com/b00t0x/WhateverXe/issues/169)
- Fork issue: [`belugaa-01/WhateverXe-Patched#7`](https://github.com/belugaa-01/WhateverXe-Patched/issues/7)
- Repository overview & docs: [`../../README.md`](../../README.md)

## Quick File Index

### 1. macOS `WhateverXe 0.8.3` + `WhateverXe Graphics 0.4.4` ([`macos_wex_0.8.3_report/`](./macos_wex_0.8.3_report/))
- [`check_wex_setup_output.txt`](./macos_wex_0.8.3_report/check_wex_setup_output.txt) — `13 OK`, `4 FAIL` (all 4 from `N97GTTopologyReady = No`)
- [`gt_readout.txt`](./macos_wex_0.8.3_report/gt_readout.txt) — Raw `N97GTReadout` hex proving `fuses[4] = 0x000E00FB` (`video = 4`)
- [`igpu_flags.txt`](./macos_wex_0.8.3_report/igpu_flags.txt) — Full `IGPU` registry gate properties
- [`plugin_records.txt`](./macos_wex_0.8.3_report/plugin_records.txt) — `N97FBBootHandoffCheck`, `N97FBMailbox`, `N97NativeBootSource`
- [`pnlf.txt`](./macos_wex_0.8.3_report/pnlf.txt) — `PNLF _UID = 19` + `AppleIntelPanelA` (`F19T07d0`, brightness working)
- [`kexts.txt`](./macos_wex_0.8.3_report/kexts.txt) — Loaded `Lilu`, `AMFIPass`, `WhateverXe 0.8.3`, `TGLCompat 0.8.1`, `TGLGraphics*`
- [`displays.txt`](./macos_wex_0.8.3_report/displays.txt) — `system_profiler SPDisplaysDataType` (`1920x1080`, `1536 MB`, `Internal`)
- [`gpu_errors.txt`](./macos_wex_0.8.3_report/gpu_errors.txt) · [`os.txt`](./macos_wex_0.8.3_report/os.txt) · [`boot_args.txt`](./macos_wex_0.8.3_report/boot_args.txt) · [`packages.txt`](./macos_wex_0.8.3_report/packages.txt)

### 2. Native Linux `i915` Evidence ([`linux_i915_evidence/`](./linux_i915_evidence/))
- [`i915_engine_info.txt`](./linux_i915_evidence/i915_engine_info.txt) — Proves `rcs0 = 0x2000`, `bcs0 = 0x22000`, logical `vcs0` → **`0x001D0000` (physical VCS2)**, `vecs0 = 0x1C8000`
- [`i915_sseu_status.txt`](./linux_i915_evidence/i915_sseu_status.txt) — Proves `1` slice, `4` subslices, `64` EUs (`16` EU/subslice)
- [`i915_dmesg.txt`](./linux_i915_evidence/i915_dmesg.txt) — `alderlake_p (46b3)`, Display `13.00` stepping `D0`
- [`lspci_00_02_0.txt`](./linux_i915_evidence/lspci_00_02_0.txt) · [`pci_sysfs.txt`](./linux_i915_evidence/pci_sysfs.txt) · [`drm_devices.txt`](./linux_i915_evidence/drm_devices.txt)

### 3. Sanitized OpenCore Configuration ([`opencore_config_sanitized/`](./opencore_config_sanitized/))
- [`config_summary.md`](./opencore_config_sanitized/config_summary.md) — Privacy-sanitized OpenCore `1.0.9` config summary
- [`SSDT-PNLF.dsl`](./opencore_config_sanitized/SSDT-PNLF.dsl) — Decompiled `\_SB.PC00.GFX0` backlight SSDT (`_UID = 19`)
