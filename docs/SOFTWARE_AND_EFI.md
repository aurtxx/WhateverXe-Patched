# Software Stack & Sanitized OpenCore Configuration

*(All SMBIOS identifiers — SerialNumber, MLB, ROM, and SystemUUID — are strictly omitted.)*

## Operating System & Bootloader
- **macOS:** Sequoia `15.8.2` (`24H232`, Darwin `24.6.0`)
- **OpenCore:** `1.0.9` (`ocvalidate`: 0 issues)
- **SMBIOS Model:** `MacBookPro16,2` (`ProcessorType = 1537`)
- **SIP / Secure Boot:** `csr-active-config = 03080000`, `SecureBootModel = Disabled`

## Boot Arguments
```text
-v debug=0x100 keepsyms=1 -disablegfxfirmware -igfxdvmt revcpu=1 -allow3d
```

## Graphics Package & Kext Load Order

| Order | Component | Version | Status in `kmutil showloaded` |
|---|---|---|---|
| 0 | `Lilu.kext` | `1.7.3` | Loaded |
| 1 | `AMFIPass.kext` (Mod) | `1.4.1` | Loaded |
| 2 | `WhateverXe.kext` (official upstream RELEASE) | `0.8.3` | Loaded |
| — | `WhateverXe-Graphics-0.4.4.pkg` | `0.4.4` | Installed (`org.b00t0x.WhateverXe.Sequoia`, `.Common`) |
| — | `AppleIntelTGLCompat.kext` | `0.8.1` | Loaded |
| — | `AppleIntelTGLGraphicsFramebuffer.kext` | `16.0.0` | Loaded |
| — | `AppleIntelTGLGraphics.kext` | `16.0.0` | Loaded |
| — | `WhateverGreen.kext` | — | **Not present** |

Other non-graphics kexts loaded on this machine: `AppleALC 1.9.9`, `BlueToolFixup 2.7.3`, `BrightnessKeys 1.0.4`, `ECEnabler 1.0.6`, `NVMeFix 1.1.4`, `RealtekBluetoothFirmware 1.0.2`, `RestrictEvents 1.1.7`, `VirtualSMC 1.3.9`, `CpuTopologyRebuild 2.0.2`, `SMC* 1.3.9`, `USBToolBox 1.2.0`, `UTBDefault`, `VoodooI2C 2.9.1`, `VoodooI2CHID`, `VoodooPS2Controller 2.3.8`, `rtw88 1.0.1`, `HoRNDIS 9.3`.

## `DeviceProperties` (`PciRoot(0x0)/Pci(0x2,0x0)`)
| Key | Type | Value | Purpose |
|---|---|---|---|
| `framebuffer-patch-enable` | Data | `01000000` | Enable DVMT stolenmem patch |
| `framebuffer-stolenmem` | Data | `0000C003` | 60 MB DVMT pre-allocation (`GMS 0xFE`) |
| `model` | String | `Intel UHD Graphics (Alder Lake-U)` | Cosmetic GPU label |
| `device-id` | *(not set)* | — | Real `0x46B3` ID preserved |

## Key Quirks & Backlight ACPI
- `Kernel > Quirks > DisableIoMapper = true` (VT-d / IOMapper handled)
- `Kernel > Quirks > ProvideCurrentCpuInfo = true`, `AppleXcpmCfgLock = true`
- `Kernel > Emulate`: `Cpuid1Data = 55060a00000080000000000000000000`, `Cpuid1Mask = ffffffff0000ff000000000000000000`
- `Kernel > Patch`: Sequoia HT patch (`_cpu_thread_alloc`, `MinKernel = 24.0.0`)
- `ACPI > Add`: `SSDT-PNLF.aml` targeting `\_SB.PC00.GFX0`, resolving dynamically to `_UID = 19` ([`SSDT-PNLF.dsl`](../reports/hp-15s-46b3-vcs2/opencore_config_sanitized/SSDT-PNLF.dsl))

Full sanitized configuration details are also in [`config_summary.md`](../reports/hp-15s-46b3-vcs2/opencore_config_sanitized/config_summary.md).
