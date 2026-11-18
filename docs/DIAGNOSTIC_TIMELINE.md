# Diagnostic Timeline & Findings

| Date | Stage | Observation / Result |
|---|---|---|
| **2026-11-14** | `WhateverXe-Patched` `v0.2.0` (`0.8.0` base) | 6-bpc eDP display handoff passed (`WEXDisplay13BootReady = Yes`), but native start blocked by `N97NativeBlockReason` bit 17 (`0x20000`): `N97GTTopologyReady = No` due to `fuses[4] = 0x000E00FB` (`video = 4`). |
| **2026-11-16** | Native Linux `i915` capture | Cross-verified exact hardware topology: `8086:46B3` rev `0C`, Display `13.00` stepping `D0`, `1` slice, `4` DSS, `64` EUs, and logical `vcs0` mapped to **physical VCS2 MMIO `0x001D0000`** (confirming physical `VCS0` at `0x001C0000` is fused off). |
| **2026-11-17** | Instrumented `0.8.2` trace test | Confirmed that merely bypassing the `video != 1 && video != 5` guard passes `configureDevice()` (`64` EUs / `6` L3 banks), then crashes during `IntelAccelerator::startGraphicsEngine()` because donor TGL engine setup targets absent `VCS0`. |
| **2026-11-18** | Clean official **`WhateverXe 0.8.3` + `Graphics 0.4.4`** | Built clean USB OpenCore `1.0.9` from verified SSD EFI (`\_SB.PC00.GFX0` `SSDT-PNLF`, `_UID = 19`). **`check_wex_setup.sh`: 13 OK** — internal 6-bpc eDP, native framebuffer (`1536 MB`), and **display brightness all work cleanly**. Only remaining blocker is `N97GTTopologyReady = No` (`video = 4`). |
| **2026-11-18** | Upstream issues filed | Published clean sanitized evidence and opened [`b00t0x/WhateverXe#169`](https://github.com/b00t0x/WhateverXe/issues/169) and [`belugaa-01/WhateverXe-Patched#7`](https://github.com/belugaa-01/WhateverXe-Patched/issues/7). |

## Next Engineering Target
Integrate VCS2-only (`video == 4`) GT admission **plus** VCS2 engine/interrupt routing (as demonstrated for `0x46A3` in `TrDiTu/WhateverXe` `victus-46a3`) onto the `0.8.3` eDP/backlight baseline and verify full Metal (`IOAccelerator` + `Metal 2/3`) on `8086:46B3` rev `0C`.
