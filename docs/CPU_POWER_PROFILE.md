# Core i3-1215U CPUFriend profile

This records the CPU power-management changes present in the main USB OpenCore setup on 23 November 2026. The USB enables CPUFriend 1.3.0 and CPUFriendDataProvider 1.0.1; the previous SSD configuration had neither load entry. The supplied provider is the existing machine-specific profile, not a newly generated tuning profile. Its OpenCore comment describes it as LFM 800 MHz and EPP 0x80; performance, thermals, and power consumption were not measured during this export.

## Apply to an existing EFI

Back up the existing EFI first. Obtain CPUFriend 1.3.0 from [Acidanthera CPUFriend](https://github.com/acidanthera/CPUFriend) and place `CPUFriend.kext` in `EFI/OC/Kexts`. Create `EFI/OC/Kexts/CPUFriendDataProvider.kext/Contents/Info.plist` using [the exported provider plist](../profiles/cpu/i3-1215u/CPUFriendDataProvider-Info.plist). The provider is a codeless kext and has no executable.

Add the following enabled `Kernel/Add` entries after Lilu and before the existing WhateverXe entry, preserving the other entries:

```json
[
  {
    "Arch": "Any",
    "BundlePath": "CPUFriend.kext",
    "Comment": "Power management data injector",
    "Enabled": true,
    "ExecutablePath": "Contents/MacOS/CPUFriend",
    "MaxKernel": "",
    "MinKernel": "",
    "PlistPath": "Contents/Info.plist"
  },
  {
    "Arch": "Any",
    "BundlePath": "CPUFriendDataProvider.kext",
    "Comment": "i3-1215U CPU power profile (LFM 800MHz, EPP 0x80)",
    "Enabled": true,
    "ExecutablePath": "",
    "MaxKernel": "",
    "MinKernel": "",
    "PlistPath": "Contents/Info.plist"
  }
]
```

The main USB retains its existing CPUID emulation, CpuTopologyRebuild, `ProvideCurrentCpuInfo`, and boot arguments. The separate `OC_CPU_TEST` configuration adds `ctrsmt=off` and lacks these CPUFriend load entries; those experimental settings are not part of this profile. The USB also changes audio layout-id from 99 to 55, which is separate from this CPU change.

## OpenCore file logging

To stop OpenCore file logging while retaining console diagnostics, clear bit `0x40` in `Misc/Debug/Target` (the USB's value 67 becomes 3). Set `AppleDebug`, `ApplePanic`, and `SysReport` to false to disable those additional file reports. This does not remove verbose macOS boot arguments or change the WhateverXe build.

## Deployment status

The existing SSD EFI was backed up locally, and an SSD config containing the main USB changes with file logging disabled passed OpenCore 1.0.9 ocvalidate. The attempted SSD deployment was blocked before execution: this export does not mean the SSD was updated or that a subsequent macOS boot was tested. Full OpenCore configs, SMBIOS identifiers, Windows boot files, and EFI backups are not included in this export.
