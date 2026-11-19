# Anywhere-Patched Hackintosh (AnywhereXe)

[![macOS Sequoia](https://img.shields.io/badge/macOS-Sequoia%2015.8.2-blue.svg)](https://www.apple.com/macos/)
[![Metal 2/3](https://img.shields.io/badge/Metal-2%20%2F%203%20Active-brightgreen.svg)](https://developer.apple.com/metal/)
[![Intel Xe-LP](https://img.shields.io/badge/iGPU-Intel%20UHD%20%2F%20Iris%20Xe-orange.svg)](https://www.intel.com/)
[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.9-purple.svg)](https://github.com/acidanthera/OpenCorePkg)
[![Evidence Release](https://img.shields.io/badge/Audit%20Proof-Release%20v1.1-success.svg)](https://github.com/aurtxx/WhateverXe-Patched/releases/tag/v1.1-metal-hardware-audit)

Universal Intel 12th/13th Gen (Alder Lake & Raptor Lake Xe-LP) Metal 2/3 Hardware Acceleration, Diagnostic Suite & Agentic AI Playbook.

---

> 🤖 **FOR AGENTIC AI (Cursor, Claude Code, Antigravity, Codex, ChatGPT)**:  
> Pass this repository to your AI agent and tell it:  
> **`"Follow AGENT_PLAYBOOK.md in this repository to diagnose and configure my Intel Xe-LP Hackintosh."`**  
> The agent will automatically read [`AGENT_PLAYBOOK.md`](./AGENT_PLAYBOOK.md), analyze your silicon binning, and apply the exact required patches without guessing!

---

## ⚡ 1-Command Universal Hardware Diagnostics

Run the single-file diagnostic tool for your current environment:

### In macOS (Live Diagnostics & Report Archive):
```bash
curl -fsSL https://raw.githubusercontent.com/aurtxx/WhateverXe-Patched/main/scripts/diagnose_mac.sh | bash
```
*Evaluates: Loaded kexts, silicon fuse readout (`N97GTReadout`), VCS2 vs VCS0 topology, eDP 6-bpc handoff, backlight profile, `IntelAccelerator` Metal binding, and USB port mapping. Auto-sanitizes and zips all logs to your Desktop.*

### In Linux (Live USB or Dual-Boot Hardware Audit):
```bash
curl -fsSL https://raw.githubusercontent.com/aurtxx/WhateverXe-Patched/main/scripts/diagnose_linux.sh | bash
```
*Evaluates: `00:02.0` PCI hardware identity, `i915_engine_info` MMIO bases (`rcs0`, `bcs0`, `vcs` base `0x1C0000` vs `0x1D0000`), SSEU slice/EU status, and provides an instant compatibility diagnosis for WhateverXe.*

---

## 🚀 Verified Hardware Status (HP 15s-fr5009TU / Core i3-1215U `8086:46B3`)

| Component | Status | Verified Runtime Proof |
|---|---|---|
| **Metal 2/3 Hardware Acceleration** | **WORKING** | `IntelAccelerator` active under `IOAccelerator`, translucent dock, fluid GUI |
| **Internal 6-bpc 1080p eDP Display** | **WORKING** | `WEXDisplay13BootReady = Yes`, `boot-display check status = 1 (Ready)` |
| **Native Framebuffer** | **WORKING** | `N97FramebufferStartAccepted = Yes`, `1920x1080 Internal`, `1536 MB` |
| **Display Backlight Brightness** | **WORKING** | `PNLF _UID = 19` (`\_SB.PC00.GFX0`), `AppleIntelPanelA` (`F19T07d0`) |
| **USB 3.2 Gen 1 Type-C Subsystem** | **WORKING** | Machine-exact `UTBMap.kext` (9 active physical ports, Type-C reversible switch) |
| **High Definition Audio (ALC236)** | **WORKING** | `AppleALC.kext` with `layout-id = 99` (Headphone 0x21, Mic 0x19) |
| **Bluetooth 5.0 (Internal USB)** | **WORKING** | `RealtekBluetoothFirmware.kext` + `BlueToolFixup.kext` |
| **Battery Management & Power** | **WORKING** | `ECEnabler.kext` + `SMCBatteryManager.kext` |
| **Wi-Fi (Realtek RTL8822CE)** | *Workaround* | Unsupported in macOS Sequoia; using Android USB Tethering (`HoRNDIS.kext`) |

---

## 🔬 The Working Solution (The Silicon Breakthrough)

Achieving Metal 2/3 acceleration on Alder Lake-U/P with VCS2-only silicon requires solving two core hardware traps:

### 1. Silicon Fuse Admission (`video = 4` / `fuses[4] = 0x000E00FB`)
* Certain Intel Core i3-1215U / i5-1235U dies have **physical VCS0 (`0x001C0000`) fused off**, leaving only **physical VCS2 (`0x001D0000`)** active.
* Upstream WhateverXe `<= 0.8.3` checks `(video != 1 && video != 5)` and rejects `video = 4`, setting `N97GTTopologyReady = No`.
* **Fix**: Built WhateverXe with `-wex-adlp-allow-vcs2` admitting `video = 4`, allowing `decodeADLPGT()` to assert `N97GTTopologyReady = Yes` with 64 EUs and 6 L3 banks.

### 2. The HP BIOS PAVP Panic Fix (`NULL + 0xB8`)
* HP Alder Lake BIOS locks PAVP (Protected Audio Video Path) registers in MMIO `0x1082C0`.
* Apple's `IntelAccelerator::PAVPCommandCallback` trusts this bit and attempts to dereference an uncreated PAVP context at `accel + 0x1278`, causing a hard kernel panic (`NULL + 0xB8`) in `startGraphicsEngine()`.
* **Fix**: Patched `PAVPCommandCallback` to force the "PAVP disabled" branch (`WEXPAVPDisabledPath`), completely eliminating the boot panic.

### 3. VCS2 Hardware Media Routing
* Remapped `__ZL34g_cInitGfxHwCtxParamsForVideoMedia` from VCS0 (`0x001C0000`, type 3, inst 0) to VCS2 (`0x001D0000`, type 4, inst 2) and routed `readAndClearVCSInterrupts` to `wexVCSIRQ`.

* **Prebuilt Kext & Source Code**:
  - Source branch: [`aurtxx/WhateverXe (branch vcs2-hp-pavp)`](https://github.com/aurtxx/WhateverXe/tree/vcs2-hp-pavp)
  - Verified Release: [Release `v1.1-metal-hardware-audit`](https://github.com/aurtxx/WhateverXe-Patched/releases/tag/v1.1-metal-hardware-audit)

---

## 📋 Full Hardware Audit & Diagnostics

A comprehensive 153-line hardware diagnostic audit was completed on the target laptop:
* **Full Audit Document**: [`docs/HARDWARE_DIAGNOSTIC_REPORT.md`](./docs/HARDWARE_DIAGNOSTIC_REPORT.md)
* **Official Verification Proof Pack**: [Release `v1.1-metal-hardware-audit`](https://github.com/aurtxx/WhateverXe-Patched/releases/tag/v1.1-metal-hardware-audit) (contains full IORegistry dumps, system profiler reports, and crash logs).

### Active Remaining Bottlenecks & Optimization:
1. **1536 MB VRAM Ceiling**: For an 8 GB system, Apple's `AppleIntelTGLGraphics` automatically reports 1536 MB nominal VRAM. WhateverXe 0.8.3 only implements `framebuffer-stolenmem`; a TGL unified memory patch is needed to override this display figure. *(Note: Metal still dynamically allocates up to ~5.5 GB of system RAM under load via Unified Memory)*.
2. **AppleGVA Media Decoding (VCS2 vs VCS0)**: Apple's VideoToolbox framework submits decode jobs expecting VCS0. While WhateverXe remaps the hardware context to VCS2, hardware video playback in players like VLC can hitch. **Workaround**: Disabling hardware acceleration in VLC uses CPU AVX2 decoding, playing 1080p and 4K 60fps smoothly at ~5% CPU usage.
3. **HP BIOS PAVP Hardware DRM**: Bypassing the PAVP panic allows Metal acceleration to work, but hardware DRM (FairPlay / Apple TV 4K) remains locked by HP firmware.

---

## 🌟 Community Acknowledgments

* **[@Chicken_Nugget_725 (Reddit)](https://www.reddit.com/user/Chicken_Nugget_725/)**: The very first person who helped boot macOS on this HP 15s-fr5009TU hardware!
* **[@b00t0x](https://github.com/b00t0x)**: Creator of WhateverXe; author of the 6-bpc eDP boot handoff and backlight engine.
* **[@TrDiTu](https://github.com/TrDiTu)**: For the VCS2 silicon admission and HP PAVP crash bypass logic.
* **[@belugaa-01](https://github.com/belugaa-01)**: For early 6-bpc research and diagnostic scripts.

---

## 📂 Navigation Index

| Section | Path | Contents |
|---|---|---|
| **AI Agent Playbook** | [`AGENT_PLAYBOOK.md`](./AGENT_PLAYBOOK.md) | Standardized machine prompt for Cursor, Claude, Antigravity, and Codex |
| **macOS Diagnostic Tool** | [`scripts/diagnose_mac.sh`](./scripts/diagnose_mac.sh) | All-in-one macOS Xe-LP diagnostic and report generator |
| **Linux Diagnostic Tool** | [`scripts/diagnose_linux.sh`](./scripts/diagnose_linux.sh) | All-in-one Linux live USB / dual-boot hardware auditor |
| **Hardware Diagnostic Report** | [`docs/HARDWARE_DIAGNOSTIC_REPORT.md`](./docs/HARDWARE_DIAGNOSTIC_REPORT.md) | 2026-11-19 audit: full inventory, crash analysis, flaws & bottlenecks |
| **Hardware Profile** | [`docs/HARDWARE_PROFILE.md`](./docs/HARDWARE_PROFILE.md) | Full laptop, CPU, iGPU PCI/BAR/GGC, Display, Audio, NVMe & Linux `i915` breakdown |
| **Software & EFI Guide** | [`docs/SOFTWARE_AND_EFI.md`](./docs/SOFTWARE_AND_EFI.md) | OpenCore 1.0.9, kext load order, boot-args, DeviceProperties, SSDT-PNLF |
| **Diagnostic Timeline** | [`docs/DIAGNOSTIC_TIMELINE.md`](./docs/DIAGNOSTIC_TIMELINE.md) | Complete testing timeline from 0.8.0 to Metal 2/3 success |
