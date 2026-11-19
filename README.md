# HP 15s-fr5009TU (`8086:46B3` rev `0C`) — WhateverXe Diagnostic Hub

Clean, privacy-sanitized **hardware, software, macOS (`WhateverXe 0.8.3` + `Graphics 0.4.4`), and Linux (`i915`)** diagnostic repository for **Intel Core i3-1215U (Alder Lake-U, VCS2-only `video = 4`)** on **macOS Sequoia 15.8.2**.

> **Live Issue Trackers:**
> - Upstream [`b00t0x/WhateverXe#169`](https://github.com/b00t0x/WhateverXe/issues/169)
> - Fork [`belugaa-01/WhateverXe-Patched#7`](https://github.com/belugaa-01/WhateverXe-Patched/issues/7)

---

## Current Status (`WhateverXe 0.8.3` RELEASE + `WhateverXe Graphics 0.4.4`)

| Component | Status | Verified Runtime Proof |
|---|---|---|
| Internal 6-bpc 1080p eDP Display | **WORKING** | `WEXDisplay13BootReady = Yes`, `boot-display check status = 1 (Ready)` |
| Native Framebuffer | **WORKING** | `N97FramebufferStartAccepted = Yes`, `1920x1080 Internal`, `1536 MB` |
| Panel Brightness Control | **WORKING** | `PNLF _UID = 19` (`\_SB.PC00.GFX0`), `WhateverXeBacklightProfile = "F19T07d0"` |
| Kexts, DVMT & Boot Args | **13 / 13 OK** | `Lilu 1.7.3`, `AMFIPass 1.4.1 Mod`, `WhateverXe 0.8.3`, `TGLCompat 0.8.1`, `60 MB` DVMT (`GMS 0xFE`) |
| Metal / Native Accelerator | **WORKING (Metal 2/3)** | `IntelAccelerator` active, `N97GTTopologyReady = Yes`, `N97NativeStartAllowed = Yes` via VCS2 admission (`-wex-adlp-allow-vcs2`) + HP PAVP fix |

---

## Breakthrough: Metal 2/3 Acceleration Achieved!

On 2026-11-19, full hardware Metal acceleration was achieved on this HP 15s-fr5009TU (`8086:46B3` rev `0x0C`)!

### The Working Solution:
1. **Base Engine**: Official **WhateverXe `0.8.3` RELEASE** + **WhateverXe Graphics `0.4.4`** (retains 6-bpc internal eDP display handoff and working backlight).
2. **VCS2 Admission**: Incorporated `@TrDiTu`'s VCS2-only topology admission logic (`-wex-adlp-allow-vcs2` admitting `fuses[4] = 0x000E00FB`, `video = 4`).
3. **HP BIOS PAVP Panic Fix**: Patched `PAVPCommandCallback` to take the "PAVP disabled" path, preventing the HP BIOS `NULL+0xB8` crash in `startGraphicsEngine()`.
4. **VCS2 Media Engine Routing**: Remapped media context params to VCS2 (`0x1D0000`, type 4, inst 2) and routed `wexVCSIRQ`.
5. **Source Code & CI Build**: Published at [`aurtxx/WhateverXe` (branch `vcs2-hp-pavp`)](https://github.com/aurtxx/WhateverXe/tree/vcs2-hp-pavp).

---

## Root Cause in One Glance

| Source | Slices / DSS / EUs / L3 | Video Engine Fuse / MMIO |
|---|---|---|
| **macOS `WhateverXe 0.8.3`** ([`gt_readout.txt`](./reports/hp-15s-46b3-vcs2/macos_wex_0.8.3_report/gt_readout.txt)) | `1` slice, `4` DSS (`8` subslices), **`64` EUs**, **`6` L3 banks** (`384 KiB` URB) | `fuses[4] = 0x000E00FB` → `video = 4` (**VCS2 only**), `enhance = 1` (`VECS0`) |
| **Linux `i915`** ([`i915_engine_info.txt`](./reports/hp-15s-46b3-vcs2/linux_i915_evidence/i915_engine_info.txt)) | `1` slice, `4` subslices, **`64` EUs** (`16` EU/DSS), Display `13.00` stepping `D0` | `rcs0 = 0x2000`, `bcs0 = 0x22000`, logical `vcs0` → **`0x001D0000` (physical VCS2)**, `vecs0 = 0x1C8000` |

`decodeADLPGT()` in `WhateverXe/kern_xelp_gt_resources.hpp` currently only admits `video == 1 || video == 5`. Because physical `VCS0` (`0x001C0000`) is fused off on this die, enabling Metal requires both `video == 4` admission and VCS2-only engine/interrupt routing.

---

## Direct Navigation

| Section | Path | Contents |
|---|---|---|
| **Hardware Profile** | [`docs/HARDWARE_PROFILE.md`](./docs/HARDWARE_PROFILE.md) | Full laptop, CPU, iGPU PCI/BAR/GGC, Display, Audio, NVMe & Linux `i915` breakdown |
| **Software & Sanitized EFI** | [`docs/SOFTWARE_AND_EFI.md`](./docs/SOFTWARE_AND_EFI.md) | macOS `15.8.2`, OpenCore `1.0.9`, exact kext load order, `boot-args`, `DeviceProperties`, `SSDT-PNLF` |
| **Diagnostic Timeline** | [`docs/DIAGNOSTIC_TIMELINE.md`](./docs/DIAGNOSTIC_TIMELINE.md) | Chronological summary of testing from `0.8.0` → `0.8.2` trace → clean `0.8.3 + 0.4.4` |
| **macOS `0.8.3` Report** | [`reports/hp-15s-46b3-vcs2/macos_wex_0.8.3_report/`](./reports/hp-15s-46b3-vcs2/macos_wex_0.8.3_report/) | `check_wex_setup_output.txt`, `gt_readout.txt`, `igpu_flags.txt`, `plugin_records.txt`, `pnlf.txt`, `kexts.txt`, `displays.txt`, `gpu_errors.txt` |
| **Linux `i915` Evidence** | [`reports/hp-15s-46b3-vcs2/linux_i915_evidence/`](./reports/hp-15s-46b3-vcs2/linux_i915_evidence/) | `i915_engine_info.txt`, `i915_sseu_status.txt`, `i915_dmesg.txt`, `lspci_00_02_0.txt`, `pci_sysfs.txt`, `drm_devices.txt` |
| **Sanitized OpenCore Files** | [`reports/hp-15s-46b3-vcs2/opencore_config_sanitized/`](./reports/hp-15s-46b3-vcs2/opencore_config_sanitized/) | `config_summary.md` & decompiled `SSDT-PNLF.dsl` |
| **Diagnostic Scripts** | [`scripts/`](./scripts/) | `check_wex_setup.sh` & `collect_wex_report.sh` (from `belugaa-01/WhateverXe-Patched`) |
| **Upstream Fork Archive** | [`upstream_belugaa/`](./upstream_belugaa/) | Original `belugaa-01/WhateverXe-Patched` README, CHANGELOG, patches (`0.1.0`, `0.2.0`), and example SSDT |

---

## Privacy & Security Guarantee
- **Zero private identifiers committed:** No SMBIOS `SystemSerialNumber`, `MLB`, `ROM`, `SystemUUID`, raw `config.plist`, MAC addresses, emails, or local user paths exist anywhere in this repository.
- `.gitignore` explicitly blocks `config.plist`, `config.plist.*`, `*.efi`, `EFI/`, and `*.zip` files from accidental commits.
