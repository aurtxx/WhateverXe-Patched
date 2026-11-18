# WhateverXe Hardware Diagnostic Report — Alder Lake-U `8086:46B3` (rev `0C`) with VCS2-Only (`video = 4`)

Clean, privacy-sanitized **macOS (`WhateverXe 0.8.3` + `WhateverXe Graphics 0.4.4`)** and **Linux (`i915`)** hardware evidence for an **HP 15s-fr5009TU** laptop with an **Intel Core i3-1215U** (`8086:46B3` rev `0x0C`, subsystem `103C:8A20`).

## Executive Summary

- **Display & Backlight WORK on official `WhateverXe 0.8.3` + `WhateverXe Graphics 0.4.4`:**
  - `WEXDisplay13BootReady = Yes`
  - `N97FramebufferStartAccepted = Yes` (`1920x1080` internal 6-bpc eDP, `1536 MB`)
  - `PNLF _UID = 19`, `WhateverXeBacklightProfile = "F19T07d0"`, **panel brightness control works**.
- **Only remaining blocker for Metal / Native Accelerator:**
  - `N97GTTopologyReady = No` → `N97NativePreflight = No` → `N97NativeStartAllowed = No`.
  - Hardware fuse readout (`N97GTReadout`): `[0x1, 0x0F, 0x00, 0x44, 0x000E00FB]`
    - 1 slice, 4 DSS (8 native subslices), **64 EUs**, **6 L3 banks (384 KiB URB)**, `enhance = 1` (`VECS0`)
    - **`video = (~0x000E00FB) & 0xFF = 0x04` (VCS2-only — physical VCS0 is fused off on this die)**
  - `decodeADLPGT()` in `WhateverXe 0.8.3` (`WhateverXe/kern_xelp_gt_resources.hpp`) currently only accepts `video == 1 || video == 5`.
- **Cross-confirmed by Linux `i915` (`linux_i915_evidence/i915_engine_info.txt`):**
  - `rcs0` @ `0x00002000`
  - `bcs0` @ `0x00022000`
  - `vcs0` *(logical)* → **MMIO base `0x001D0000`** *(physical VCS2! Physical VCS0 `0x001C0000` does not exist)*
  - `vecs0` @ `0x001C8000`
  - SSEU: 1 slice (`0001`), 4 subslices, 16 EU/subslice, **64 EUs total**, Display `13.00` stepping `D0`.

## Repository Contents

| Folder / File | Contents |
|---|---|
| [`GITHUB_ISSUE_BODY.md`](./GITHUB_ISSUE_BODY.md) | Ready-to-file issue summary for `b00t0x/WhateverXe` |
| [`macos_wex_0.8.3_report/`](./macos_wex_0.8.3_report/) | Clean official `WhateverXe 0.8.3` + `Graphics 0.4.4` boot outputs (`gt_readout.txt`, `igpu_flags.txt`, `plugin_records.txt`, `pnlf.txt`, `kexts.txt`, `displays.txt`, `check_wex_setup_output.txt`) |
| [`linux_i915_evidence/`](./linux_i915_evidence/) | Native Linux `i915` debugfs & PCI dumps (`i915_engine_info.txt`, `i915_sseu_status.txt`, `i915_dmesg.txt`, `lspci_00_02_0.txt`, `pci_sysfs.txt`, `drm_devices.txt`) |
| [`opencore_config_sanitized/`](./opencore_config_sanitized/) | Privacy-sanitized OpenCore 1.0.9 config summary + decompiled `SSDT-PNLF.dsl` |
| [`wex_0.8.3_46b3_vcs2_report.zip`](./wex_0.8.3_46b3_vcs2_report.zip) | Sanitized ZIP bundle of `macos_wex_0.8.3_report/` |

## Privacy Notice
No SMBIOS serial numbers, MLB, ROM, SystemUUID, MAC addresses, or personal identifiers are included in this repository.
