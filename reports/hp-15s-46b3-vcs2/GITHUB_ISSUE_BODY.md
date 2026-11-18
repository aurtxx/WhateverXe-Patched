# Suggested GitHub Issue Title
`[ADL-U 8086:46B3 rev 0C] Display & brightness work on 0.8.3 + 0.4.4, but N97GTTopologyReady=No due to VCS2-only fuse (fuses[4]=0x000E00FB, video=4)`

---

# Issue Body (copy below this line)

### Summary
On an HP 15s laptop with **Intel Core i3-1215U (`8086:46B3`, rev `0x0C`, subsystem `103C:8A20`)** running **macOS Sequoia 15.8.2 (`24H232`)** with completely unmodified official **WhateverXe `0.8.3` RELEASE** + **WhateverXe Graphics `0.4.4`**:

- **Internal 6-bpc 1080p eDP display handoff, native framebuffer, and panel brightness all work cleanly!**
  - `WEXDisplay13BootReady = Yes`
  - `N97FramebufferStartAccepted = Yes`, `N97FramebufferBackendReady = Yes`
  - `boot-display check status = 1 (Ready)`
  - `PNLF _UID = 19` (`\_SB.PC00.GFX0`), `AppleIntelPanelA` attached with `WhateverXeBacklightProfile = "F19T07d0"`, **display brightness slider works**.
- **The only blocker preventing Metal / native accelerator startup is `N97GTTopologyReady = No`** because this specific i3-1215U die has **VCS0 fused off and only VCS2 enabled** (`fuses[4] = 0x000E00FB` â†’ `video = 4`).
- `decodeADLPGT()` in `WhateverXe/kern_xelp_gt_resources.hpp` currently only admits `video == 1 || video == 5`.

---

### Hardware & Software Environment
| Item | Value |
|---|---|
| Laptop | HP 15s-fr5009TU (`103C:8A20`) |
| CPU | 12th Gen Intel Core i3-1215U (Alder Lake-U) |
| iGPU | Intel UHD Graphics (`8086:46B3`, rev `0x0C`) |
| Internal Panel | 15.6" `1920x1080` 6-bpc eDP |
| Firmware DVMT | 60 MB (`GMS = 0xFE`, `WhateverXePhysicalGGC = 65217`) |
| macOS | Sequoia `15.8.2` (`24H232`, Darwin `24.6.0`) |
| Bootloader / SMBIOS | OpenCore `1.0.9`, `MacBookPro16,2` |
| Kexts (in order) | `Lilu 1.7.3` â†’ `AMFIPass 1.4.1` (Mod) â†’ `WhateverXe 0.8.3` (official RELEASE) |
| Graphics Package | `WhateverXe-Graphics-0.4.4.pkg` (`AppleIntelTGLCompat 0.8.1`, `AppleIntelTGLGraphicsFramebuffer 16.0.0`, `AppleIntelTGLGraphics 16.0.0`) |
| `boot-args` | `-v debug=0x100 keepsyms=1 -disablegfxfirmware -igfxdvmt revcpu=1 -allow3d` |
| `DeviceProperties` (`0x2,0x0`) | `framebuffer-patch-enable = 01000000`, `framebuffer-stolenmem = 0000C003` (no `device-id` spoof) |
| `DisableIoMapper` | `true` |

---

### macOS `WhateverXe 0.8.3` Fuse Readout (`gt_readout.txt`)
```text
"WhateverXePhysicalGGC" = 65217
"N97PhysicalRevision" = 12
"N97GTStep" = "unknown"
"N97GTReadout" = <01000000040000000400000003000000030000000000000000000100000000000000000000000000010000000100000000000100000001000000000000000000010000000f0000000000000044000000fb000e00000000000000000000000000000000000000000000000000100000003020000000000000342000000000000038200000000000003c200000000000009c20000000020000342200000100000038220000000000009c220000000000003020020000000000342002000000000038200200000000003c200200000000009c20020000020000342202000100000038220200000000009c22020000000000>
"N97NativeEDRAM" = 0
"N97GTTopologyReady" = No
```

Decoded fuse words:
- `fuses[0] = 0x00000001` â†’ 1 slice
- `fuses[1] = 0x0000000F` â†’ 4 DSS / 8 native subslices
- `fuses[2] = 0x00000000` â†’ 16 EU/DSS â†’ **64 EUs**
- `fuses[3] = 0x00000044` â†’ **6 L3 banks / 384 KiB URB**
- `fuses[4] = 0x000E00FB` â†’ `video = (~0x000E00FB) & 0xFF = 0x04` (**VCS2 only**), `enhance = 0x01` (**VECS0**)

---

### Linux `i915` Hardware Cross-Verification
On the exact same laptop under Linux (`i915`):
- **`i915_dmesg.txt`**: `Found alderlake_p (device ID 46b3) integrated display version 13.00 stepping D0`
- **`i915_sseu_status.txt`**: `Available Slice Mask: 0001`, `Available Subslice Total: 4`, `Available EU Total: 64`, `Available EU Per Subslice: 16`
- **`i915_engine_info.txt`** confirms the exact physical MMIO bases of all 4 present engines:
  - `rcs0` â†’ MMIO base `0x00002000`
  - `bcs0` â†’ MMIO base `0x00022000`
  - `vcs0` *(logical)* â†’ **MMIO base `0x001D0000`** *(physical VCS2 â€” physical VCS0 `0x001C0000` is fused off)*
  - `vecs0` â†’ MMIO base `0x001C8000`

*(Note: Because physical VCS0 at `0x1C0000` is absent on this die, simply relaxing `(video != 1 && video != 5)` in `decodeADLPGT()` is not sufficient by itself â€” the donor TGL accelerator engine initialization / VCS routing also needs to handle VCS0-absent / VCS2-only hardware.)*

---

### Full Diagnostic Package & Evidence Repository
- Complete sanitized macOS (`0.8.3` + `0.4.4`) + Linux (`i915`) evidence repository: **https://github.com/aurtxx/WhateverXe-Patched/tree/main/reports/hp-15s-46b3-vcs2**
- Attached sanitized report ZIP: `wex_0.8.3_46b3_vcs2_report.zip`

Happy to test any diagnostic or candidate builds on this hardware and report back!
