# Sanitized OpenCore Configuration Summary

*(SMBIOS SerialNumber, MLB, ROM, and SystemUUID intentionally omitted.)*

## Bootloader & System
- **OpenCore:** `1.0.9` (validated clean via `ocvalidate`, 0 issues)
- **SMBIOS Model:** `MacBookPro16,2` (`ProcessorType = 1537`)
- **macOS:** Sequoia `15.8.2` (`24H232`, Darwin `24.6.0`)
- **SecureBootModel:** `Disabled`
- **csr-active-config:** `03080000`

## Boot Arguments
```text
-v debug=0x100 keepsyms=1 -disablegfxfirmware -igfxdvmt revcpu=1 -allow3d
```

## DeviceProperties (`PciRoot(0x0)/Pci(0x2,0x0)`)
- `framebuffer-patch-enable`: `01000000` (Data)
- `framebuffer-stolenmem`: `0000C003` (Data — 60 MB DVMT pre-allocation, GMS `0xFE`)
- `model`: `Intel UHD Graphics (Alder Lake-U)` (String)
- *(No `device-id` spoof; real PCI ID `8086:46B3` rev `0x0C`)*

## Relevant Kexts (in exact `Kernel > Add` load order)
1. `Lilu.kext` `1.7.3`
2. `AMFIPass.kext` `1.4.1` (Mod build)
3. `WhateverXe.kext` `0.8.3` (official upstream RELEASE, unmodified)
4. `AppleALC.kext` `1.9.9`
5. `BrightnessKeys.kext` `1.0.4`
6. `VirtualSMC.kext` `1.3.9` + `CpuTopologyRebuild.kext` `2.0.2`
- **WhateverGreen:** NOT present / NOT loaded
- **WhateverXe Graphics Package:** `0.4.4` (`org.b00t0x.WhateverXe.Sequoia`, `org.b00t0x.WhateverXe.Common`; `AppleIntelTGLCompat 0.8.1`, `AppleIntelTGLGraphicsFramebuffer 16.0.0`, `AppleIntelTGLGraphics 16.0.0`)

## Relevant Kernel / Booter Quirks & CPU Emulation
- `Kernel > Quirks > DisableIoMapper`: `true`
- `Kernel > Quirks > ProvideCurrentCpuInfo`: `true`
- `Kernel > Quirks > AppleXcpmCfgLock`: `true`
- `Kernel > Emulate`: `Cpuid1Data = 55060a00000080000000000000000000`, `Cpuid1Mask = ffffffff0000ff000000000000000000`
- `Kernel > Patch`: Sequoia HT fix (`_cpu_thread_alloc`, `MinKernel = 24.0.0`)

## Backlight ACPI
- `SSDT-PNLF.aml` targeting `\_SB.PC00.GFX0`, resolving to `_UID = 19` (`0x13`) — see [`SSDT-PNLF.dsl`](./SSDT-PNLF.dsl).
- Confirmed active at runtime: `AppleIntelPanelA` attached with `WhateverXeBacklightProfile = "F19T07d0"`, **display brightness control works**.
