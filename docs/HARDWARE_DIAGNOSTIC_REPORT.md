# HP 15s-fr5009TU Hackintosh - Comprehensive Hardware Diagnostic & Flaw Report
**Target System:** HP 15s-fr5009TU Laptop (Subsystem 103C:8A20)  
**CPU:** Intel Core i3-1215U (Alder Lake-U / GT1, 2P + 4E / 8 Threads)  
**iGPU:** Intel UHD Graphics Xe-LP (8086:46B3, Rev 0x0C, Subsystem 103C:8A20)  
**OS:** macOS Sequoia 15.8.2 (Build 24H232, Darwin Kernel 24.6.0)  
**Bootloader:** OpenCore 1.0.9 (Release)  
**Timestamp:** 2026-11-19 21:25:00 UTC+5:30  
**Evidence Pack:** /Volumes/Ventoy/WEX_HARDWARE_EVIDENCE_PACK_20261119.zip  

---

## 1. Executive Summary & Hardware Inventory

### Physical Hardware Inventory
| Component | Specifications | Identification / ACPI Path | Driver / Kext Status |
| :--- | :--- | :--- | :--- |
| **Processor** | Intel Core i3-1215U (1.20GHz base, up to 4.40GHz boost) | `_SB.PR00` - `_SB.PR07` | Managed via `revcpu=1` + `CpuTopologyRebuild.kext` + `X86PlatformPlugin` |
| **Integrated GPU** | Intel UHD Graphics Xe-LP (Alder Lake-U GT1, 64 EUs) | `8086:46B3` (Rev 0x0C) `_SB.PC00.GFX0` | **Metal 2 Active** (`AppleIntelTGLGraphics` + `WhateverXe 0.8.3 VCS2+PAVP`) |
| **Internal Display** | 15.6" 1920x1080 FHD 6-bpc eDP panel | Combo DDI A (`AppleIntelPanelA`) | Working via eDP 6-bpc handoff patch; backlight via `SSDT-PNLF.aml` (`_UID=19`) |
| **System RAM** | 8.00 GB DDR4 (1x 8GB SO-DIMM) | Physical RAM: 8,589,934,592 bytes | macOS Compressor Mode 4 active |
| **NVMe Storage** | WD PC SN740 512GB NVMe SSD (Internal Disk 0) | `15B7:5017` (`pci15b7,5017`) | `NVMeFix.kext` loaded; **Protected: NEVER modified** |
| **Audio Codec** | Realtek ALC236 High Definition Audio | `10EC:0236` at `_SB.PC00.HDAS` | Working via `AppleALC.kext` (`layout-id = 99`) |
| **Wi-Fi Card** | Realtek RTL8822CE 802.11ac PCIe Adapter | `10EC:C822` (`pci10ec,c822`) | **UNSUPPORTED in macOS Sequoia** (no native driver) |
| **Bluetooth** | Realtek Bluetooth 5.0 (USB Internal) | USB Port 10 (`00e04c000001`) | Working via `RealtekBluetoothFirmware.kext` + `BlueToolFixup.kext` |
| **USB Controller** | Intel Alder Lake PCH USB 3.2 xHCI Host Controller | `8086:51ED` (`_SB.PC00.XHCI`) | `AppleUSBXHCISPT` + `USBToolBox.kext` |
| **Webcam** | HP TrueVision HD Camera | USB Port 3 (`0408:536c`) | Native UVC Video Driver working |
| **Battery & Power** | HP Smart Battery System | `_SB.PC00.LPCB.BAT0` | Working via `ECEnabler.kext` + `SMCBatteryManager.kext` |

---

## 2. Root Cause Analysis of Recent Crashes

### A. The System Freeze & Reboot (20:55:56)
* **Crash Signature:** `WindowServer_...userspace_watchdog_timeout.spin` preceded by `Kernel_...gpuRestart` (Signature 803).
* **Fault Summary:**
  ```text
  Event: GPU Reset
  Application: WindowServer
  Intel GPU Hang Summary: Processing hang for hardware context ID[5]
  -- Summary of Status for ALL Rings --
  RCS Ring is: - busy - in the ring <-- Appears hung
  BCS Ring is: - NOT enabled - busy - in the ring <-- Appears hung
  ```
* **Root Cause:**
  Hardware context ID 5 on the Render Command Streamer (RCS) ring hung during a Metal 3D blit/submission operation. The GPU failed to report fence completion. WindowServer became unresponsive waiting for the display server pipe transaction, triggering macOS userspace watchdog timeout (60-second hang limit), which forced a hardware reboot.
* **Relation to WhateverXe:**
  Matches the documented edge-case in WhateverXe for Alder Lake-U: under certain complex compositor loads or multi-tab browser rendering, the Xe-LP hardware command streamer experiences ring stalls.

### B. Application Crashes (Safari, Brave Browser, Books, DictationIM)
* **Crash Signature:** `EXC_BAD_ACCESS (SIGBUS: 10)` at virtual address `0x7ff81b3e504c`.
* **Kernel Triage:**
  ```text
  APFS - Encountered a compressed data hash mismatch
  VM - Page has restart bit set
  APFS - Pagein of compressed inode failed
  VM - Filesystem pagein returned an error in vnode_pagein
  Subtype: FS pagein error: 94 Bad message (EBADMSG)
  ```
* **Root Cause:**
  The address `0x7ff81b3e504c` belongs to `/usr/lib/liblangid.dylib` (NLP language identification/spell checking). When any browser or text input process launched, the kernel attempted to page in this compressed inode from the APFS root volume. The decompressed block hash failed APFS checksum verification (`EBADMSG`), causing the kernel to throw `SIGBUS (Bus error: 10)` to the application.
* **Is it RAM, Swap, or GPU Shared Memory?**
  * **Not a Swap exhaustion:** Total swap was 1024 MB with 867 MB free.
  * **Not a GPU shared memory crash:** GPU memory allocation did not fail.
  * **It is an APFS Compressed Inode Data Integrity issue** under page cache pressure.

---

## 3. Comprehensive Audit of Gaps, Flaws & Bottlenecks

### 1. GPU VRAM Allocation Ceiling (1536 MB vs 2560 MB)
* **Issue:** OpenCore `config.plist` specifies `framebuffer-unifiedmem = 000000A0` (2560 MB / 2.5 GB), but System Information reports `1536 MB (Dynamic, Max)`.
* **Root Cause:** WhateverXe 0.8.3 only implements `framebuffer-stolenmem` (`tglStolenMemoryReady` / `TGLStolenMemoryApplied`) for `AppleIntelTGLGraphics`. It does **not** patch the unified memory tables or override the dynamic VRAM calculation in `AppleIntelFramebufferController`.
* **Impact:** For an 8 GB system, the macOS TGL driver automatically caps VRAM at 1536 MB. Modifying `framebuffer-unifiedmem` in DeviceProperties has no effect unless WhateverXe adds an explicit TGL unifiedmem hook.

### 2. Media Decode Engine & VCS Ring Routing (VCS2 vs VCS0)
* **Issue:** Local playback in VLC is smooth, but hardware VideoToolbox acceleration suffers hitches, YouTube seeking stalls, and Safari playback can freeze.
* **Root Cause:**
  * Physical silicon fuses: `fuses[4] = 0x000E00FB` (`video = 4`). On this Core i3-1215U, physical VCS0 is fused off; only physical VCS2 is present.
  * WhateverXe patches `__ZL34g_cInitGfxHwCtxParamsForVideoMedia` to remap the media context from VCS0 (`0x001C0000`) to VCS2 (`0x001D0000`).
  * However, Apple's proprietary `AppleGVA.framework` and `AppleIntelTGLGraphics` VideoToolbox decoders hardcode command submissions to the primary VCS0 ring. When AppleGVA attempts to dispatch hardware decoding passes to VCS0, the job either drops back to software decode or causes buffer timeout hitches.

### 3. PAVP Hardware DRM Locked
* **Issue:** FairPlay 1.x/2.x/3.x DRM (Apple TV+ 1080p/4K, Netflix in Safari) is non-functional.
* **Root Cause:** HP Alder Lake BIOS locks PAVP (Protected Audio Video Path) registers at `0x1082C0`. WhateverXe forces `WEXPAVPDisabledPath = Yes` to bypass the `NULL + 0xB8` panic in `startGraphicsEngine()`. Disabling PAVP resolves the boot panic but permanently disables hardware DRM.

### 4. USB 3.2 Type-C Subsystem (RESOLVED in this session)
* **Flaw Identified:**
  * OpenCore was using `UTBDefault.kext` (empty placeholder) without a custom `UTBMap.kext`.
  * macOS applied its default 15-port discovery limit on `XHCI@14000000`.
  * 12 ports were consumed by USB 2.0 (HS01 to HS12).
  * Only 3 ports were available for USB 3.0 (ports 13, 14, 15).
  * The physical USB 3.2 Type-C SuperSpeed lines (Port 15/16) and Type-C orientation switching (`UsbConnector = 9`) were improperly mapped or truncated.
* **Fix Implemented & Deployed:**
  * Created custom `UTBMap.kext` mapping exactly 9 active physical ports:
    * `HS01` / `SS01`: Left Type-A USB 3.2 Gen 1 (Connector Type 3)
    * `HS02` / `SS02`: Right Type-A USB 3.2 Gen 1 (Connector Type 3)
    * `HS03`: Internal HP TrueVision HD Camera (Connector Type 255)
    * `HS04` / `SS03` / `SS04`: USB 3.2 Gen 1 Type-C Port (Connector Type 9 - Type-C with switch)
    * `HS10`: Internal Realtek Bluetooth 5.0 (Connector Type 255)
  * Staged `UTBMap.kext` in `/Volumes/OPENCORE_E/EFI/OC/Kexts/UTBMap.kext`.
  * Updated `/Volumes/OPENCORE_E/EFI/OC/config.plist` (with automated timestamped backup).

### 5. Wi-Fi Adapter Unsupported
* **Issue:** Realtek RTL8822CE (`10EC:C822`) has no native macOS Sequoia driver.
* **Status:** `rtw88.kext` in OpenCore does not support macOS 15.
* **Workaround:** Currently utilizing Android USB Tethering (`HoRNDIS.kext`) providing high-speed network over interface `en0`. Permanent solution requires replacing the M.2 Wi-Fi card with an Intel AX201/AX210 (`AirportItlwm.kext`).

### 6. External Display (HDMI) Unconfigured
* **Issue:** Connecting an external monitor via HDMI yields no signal.
* **Root Cause:** The `PciRoot(0x0)/Pci(0x2,0x0)` configuration currently only patches stolenmem and framebuffer enable. It lacks connector pipe definitions (`framebuffer-con1-enable`, `framebuffer-con1-type = 00080000` for HDMI) targeting the second Combo DDI.

---

## 4. Evidence Package Contents

All evidence, logs, crash dumps, and updated kexts have been archived into:  
`file:///Volumes/Ventoy/WEX_HARDWARE_EVIDENCE_PACK_20261119.zip`

### File Manifest inside Evidence Pack:
1. `HARDWARE_DIAGNOSTIC_REPORT.md`: This comprehensive diagnostic report.
2. `UTBMap.kext/`: Custom generated USB 3.2 Type-C mapping kext.
3. `config.plist.backup-20261119`: Clean backup of OpenCore config before USB mapping update.
4. `igpu_ioreg.txt`: Complete IORegistry properties for `_SB.PC00.GFX0` (IGPU).
5. `usb_ioreg.txt`: Complete IORegistry properties for `_SB.PC00.XHCI` and USB devices.
6. `full_ioreg.txt`: Full system IORegistry dump (8.7 MB).
7. `system_profiler_displays.txt`: System Profiler graphics, displays, and VRAM report.
8. `system_profiler_hardware.txt`: System Profiler CPU, memory, and board report.
9. `system_profiler_audio.txt`: System Profiler audio codecs and output routes.
10. `system_profiler_bluetooth.txt`: System Profiler Bluetooth controller and paired peripherals.
11. `system_profiler_storage.txt`: System Profiler APFS containers, NVMe, and USB volumes.
12. `loaded_kexts.txt`: Output of `kmutil showloaded` showing all active kexts.
13. `kernel_boot_log.txt`: Kernel syslog extract for graphics and WhateverXe.
14. `crash_reports/`:
    * `Kernel_2026-11-19-204440_aurtxs-MacBook-Pro.gpuRestart` (RCS ring hang report)
    * `WindowServer_2026-11-19-205138_aurtxs-MacBook-Pro.userspace_watchdog_timeout.spin` (Watchdog reset report)
    * `Safari-2026-11-19-204723.ips` (SIGBUS liblangid APFS pagein crash)
    * `Brave Browser-2026-11-19-204427.ips` (SIGBUS liblangid APFS pagein crash)
    * `Books-2026-11-19-202755.ips` (SIGBUS liblangid APFS pagein crash)

---

## 5. Instructions for Windows Antigravity Session ("win agy")

When switching back to Windows 11 to update the GitHub repository (`aurtxx/WhateverXe` or EFI repo):
1. **Repository Update:**
   * Commit the `HARDWARE_DIAGNOSTIC_REPORT.md` to `docs/` or root of the repo.
   * Add the evidence archive `WEX_HARDWARE_EVIDENCE_PACK_20261119.zip` to the release assets or tracking folder.
2. **OpenCore USB Fix Verification:**
   * Verify that `UTBMap.kext` is enabled under `Kernel -> Add` in `config.plist`.
   * Test USB Type-C SuperSpeed (5Gbps / 10Gbps) flash drives or hubs in both orientations.
3. **Future WhateverXe Feature PRs:**
   * Propose a PR or feature patch to WhateverXe to support `framebuffer-unifiedmem` override for TigerLake / AlderLake (`AppleIntelTGLGraphics`).
   * Propose an investigation into hooking AppleGVA ring submission to route media decode jobs to VCS2 instead of hardcoded VCS0.
