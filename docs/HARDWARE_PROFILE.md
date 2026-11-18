# Hardware Profile — HP 15s-fr5009TU

Complete hardware specification verified directly from macOS IORegistry (`WhateverXe 0.8.3`) and native Linux (`i915` + `lspci`).

## Platform Overview

| Component | Details |
|---|---|
| **Laptop Model** | HP 15s-fr5009TU |
| **Subsystem ID** | `103C:8A20` (Hewlett-Packard Company) |
| **CPU** | 12th Gen Intel Core i3-1215U (Alder Lake-U, 6 Cores: 2P + 4E, 8 Threads) |
| **RAM** | 8 GB (`8589934592` bytes) |
| **Storage** | WD PC SN740 512 GB NVMe SSD |
| **Internal Display** | 15.6" `1920x1080` 6-bpc eDP panel via Combo DDI (`card1-eDP-1`) |
| **Audio** | Realtek ALC236 (`layout-id = 99`) + Intel Alder Lake SOF DSP |

---

## Integrated GPU (`00:02.0` / `\_SB.PC00.GFX0`)

| Property | Value | Source |
|---|---|---|
| **Vendor / Device ID** | `8086:46B3` (Alder Lake-UP3 GT1 / UHD Graphics) | [`lspci_00_02_0.txt`](../reports/hp-15s-46b3-vcs2/linux_i915_evidence/lspci_00_02_0.txt) |
| **PCI Revision** | `0x0C` (`12`) | [`pci_sysfs.txt`](../reports/hp-15s-46b3-vcs2/linux_i915_evidence/pci_sysfs.txt) |
| **Subsystem** | `103C:8A20` | [`pci_sysfs.txt`](../reports/hp-15s-46b3-vcs2/linux_i915_evidence/pci_sysfs.txt) |
| **Display IP** | Display `13.00`, stepping `D0` | [`i915_dmesg.txt`](../reports/hp-15s-46b3-vcs2/linux_i915_evidence/i915_dmesg.txt) |
| **BAR0 (MMIO)** | `16 MB` (`64-bit`, non-prefetchable) | [`lspci_00_02_0.txt`](../reports/hp-15s-46b3-vcs2/linux_i915_evidence/lspci_00_02_0.txt) |
| **BAR2 (Aperture)** | `256 MB` (`64-bit`, prefetchable) | [`lspci_00_02_0.txt`](../reports/hp-15s-46b3-vcs2/linux_i915_evidence/lspci_00_02_0.txt) |
| **Firmware DVMT (`GGC`)** | `60 MB` (`GMS = 0xFE`, `WhateverXePhysicalGGC = 65217`) | [`gt_readout.txt`](../reports/hp-15s-46b3-vcs2/macos_wex_0.8.3_report/gt_readout.txt) |
| **eDRAM** | `0` (`N97NativeEDRAM = 0`) | [`gt_readout.txt`](../reports/hp-15s-46b3-vcs2/macos_wex_0.8.3_report/gt_readout.txt) |

---

## GT Topology & Fuse Breakdown (macOS + Linux Cross-Checked)

| Fuse Word | Hex Value | Decoded Hardware Topology | Linux `i915` Verification |
|---|---|---|---|
| `fuses[0]` | `0x00000001` | `1` Slice | `Available Slice Mask: 0001` (`1`) |
| `fuses[1]` | `0x0000000F` | `4` DSS (`8` native subslices) | `Available Subslice Total: 4` |
| `fuses[2]` | `0x00000000` | `16` EU/DSS → **`64` EUs** | `Available EU Total: 64` (`16` EU/subslice) |
| `fuses[3]` | `0x00000044` | **`6` L3 banks** (`384 KiB` URB) | — |
| `fuses[4]` | `0x000E00FB` | `video = 0x04` (**VCS2 only**), `enhance = 0x01` (`VECS0`) | `vcs0` MMIO base **`0x001D0000`** (`VCS2`), `vecs0` **`0x001C8000`** |

### Verified Physical Engine Map ([`i915_engine_info.txt`](../reports/hp-15s-46b3-vcs2/linux_i915_evidence/i915_engine_info.txt))

| Engine Class | Linux `i915` Name | Physical MMIO Base | Present on Die? |
|---|---|---|---|
| Render | `rcs0` | `0x00002000` | Yes |
| Blitter | `bcs0` | `0x00022000` | Yes |
| Video Decode 0 | *(absent)* | `0x001C0000` | **No (fused off)** |
| Video Decode 2 | `vcs0` *(logical)* | **`0x001D0000`** | **Yes (sole VCS engine)** |
| Video Enhance 0 | `vecs0` | `0x001C8000` | Yes |
