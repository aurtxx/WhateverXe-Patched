#!/usr/bin/env bash
# ==============================================================================
# Anywhere-Patched Hackintosh: Universal macOS Xe-LP Diagnostic & Audit Tool
# Repository: https://github.com/aurtxx/WhateverXe-Patched
# Supports: Intel 12th/13th Gen Alder Lake & Raptor Lake Xe-LP (UHD / Iris Xe)
# ==============================================================================

set -uo pipefail

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="$HOME/Desktop/wex_diag_$STAMP"
mkdir -p "$OUT_DIR"

LOG_FILE="$OUT_DIR/diagnostic_summary.txt"
exec > >(tee "$LOG_FILE") 2>&1

echo "======================================================================"
echo "    ANYWHERE-PATCHED HACKINTOSH: MACOS XE-LP DIAGNOSTIC REPORT       "
echo "    Generated: $(date)                                               "
echo "======================================================================"
echo ""

# Section 1: OS & System
echo "--- [1/6] System & Kernel ---"
sw_vers
uname -a
echo "SIP Status: $(csrutil status 2>&1)"
BOOTARGS="$(sysctl -n kern.bootargs 2>/dev/null || true)"
echo "Boot Arguments: $BOOTARGS"
echo ""

# Section 2: Kext Load Order & Driver Versions
echo "--- [2/6] Graphics & Security Kexts ---"
kextstat | grep -iE "Lilu|AMFIPass|Whatever|AppleIntelTGL|Xe" | tee "$OUT_DIR/loaded_kexts.txt" || echo "No Xe graphics kexts detected."
echo ""

# Section 3: Silicon Fuse Vector & Video Engine Analysis
echo "--- [3/6] Xe-LP GT Fuses & Topology Readout ---"
READOUT="$(ioreg -lw0 -p IODeviceTree -k N97GTReadout 2>/dev/null | grep -o 'N97GTReadout.*' || true)"
if [ -n "$READOUT" ]; then
    echo "Raw Readout: $READOUT"
    echo "$READOUT" > "$OUT_DIR/gt_readout.txt"
    
    # Check Silicon Topology Status
    TOPOLOGY_READY="$(ioreg -lw0 -p IODeviceTree -k N97GTTopologyReady 2>/dev/null | grep -o 'N97GTTopologyReady" = Yes' || echo 'No')"
    START_ALLOWED="$(ioreg -lw0 -p IODeviceTree -k N97NativeStartAllowed 2>/dev/null | grep -o 'N97NativeStartAllowed" = Yes' || echo 'No')"
    PAVP_BYPASS="$(ioreg -lw0 -p IODeviceTree -k WEXPAVPDisabledPath 2>/dev/null | grep -o 'WEXPAVPDisabledPath" = true' || echo 'No')"
    VCS2_MEDIA="$(ioreg -lw0 -p IODeviceTree -k WEXVCS2Media 2>/dev/null | grep -o 'WEXVCS2Media" = true' || echo 'No')"
    
    echo "N97GTTopologyReady:    $TOPOLOGY_READY"
    echo "N97NativeStartAllowed:  $START_ALLOWED"
    echo "WEXPAVPDisabledPath:    $PAVP_BYPASS"
    echo "WEXVCS2Media:           $VCS2_MEDIA"
    
    # Evaluate Silicon VCS Binning
    if echo "$READOUT" | grep -q -i "fb000e00"; then
        echo ""
        echo ">> SILICON CLASSIFICATION: VCS2-ONLY DIE (video = 4 / fuses[4] = 0x000E00FB) <<"
        echo "   Physical VCS0 is fused off on this CPU die."
        if echo "$BOOTARGS" | grep -q -- "-wex-adlp-allow-vcs2"; then
            echo "   [OK] -wex-adlp-allow-vcs2 boot-arg is present!"
        else
            echo "   [!] WARNING: -wex-adlp-allow-vcs2 boot-arg is MISSING in OpenCore config.plist!"
        fi
    fi
else
    echo "N97GTReadout property not found in IODeviceTree."
fi
echo ""

# Section 4: Display Handoff & Backlight
echo "--- [4/6] Display Handoff & Brightness ---"
BOOT_READY="$(ioreg -lw0 -p IODeviceTree -k WEXDisplay13BootReady 2>/dev/null | grep -o 'WEXDisplay13BootReady" = Yes' || echo 'No')"
echo "WEXDisplay13BootReady: $BOOT_READY"
ioreg -c AppleIntelPanelA -r > "$OUT_DIR/panel_backlight.txt" 2>&1 || true
if grep -q "WhateverXeBacklightProfile" "$OUT_DIR/panel_backlight.txt" 2>/dev/null; then
    PROFILE="$(grep "WhateverXeBacklightProfile" "$OUT_DIR/panel_backlight.txt" | head -n 1)"
    echo "Backlight Status: ACTIVE ($PROFILE)"
else
    echo "Backlight Status: AppleIntelPanelA not bound. Check SSDT-PNLF (_UID=19)."
fi
echo ""

# Section 5: Metal 2/3 Hardware Acceleration Check
echo "--- [5/6] Metal & Hardware Accelerator ---"
ACCEL_CHECK="$(ioreg -c IOAccelerator -r | grep -i "IntelAccelerator" | head -n 1 || true)"
if [ -n "$ACCEL_CHECK" ]; then
    echo ">> SUCCESS: IntelAccelerator is ACTIVE under IOAccelerator! <<"
    echo "   Hardware Metal 2/3 Acceleration is operational."
else
    echo ">> BLOCKED: IntelAccelerator is NOT active. Check Topology and PAVP bypass. <<"
fi
system_profiler SPDisplaysDataType > "$OUT_DIR/displays.txt" 2>/dev/null || true
grep -E "Chipset Model:|VRAM|Metal Support:|Resolution:" "$OUT_DIR/displays.txt" || true
echo ""

# Section 6: USB 3.2 Type-C Subsystem
echo "--- [6/6] USB Subsystem & UTBMap Check ---"
if kextstat | grep -q "UTBMap"; then
    echo "USB Port Map: [OK] Custom UTBMap.kext loaded."
elif kextstat | grep -q "UTBDefault"; then
    echo "USB Port Map: [!] WARNING: Generic UTBDefault.kext active. USB Type-C port truncation likely."
else
    echo "USB Port Map: Native AppleUSBXHCISPT active."
fi
echo ""

# Dump Full IOReg & System Profiler
echo "Exporting full system dumps..."
ioreg -l > "$OUT_DIR/full_ioreg.txt" 2>/dev/null || true
system_profiler SPHardwareDataType > "$OUT_DIR/hardware.txt" 2>/dev/null || true
system_profiler SPAudioDataType > "$OUT_DIR/audio.txt" 2>/dev/null || true
system_profiler SPBluetoothDataType > "$OUT_DIR/bluetooth.txt" 2>/dev/null || true
dmesg | tail -n 1500 > "$OUT_DIR/dmesg_tail.txt" 2>/dev/null || true

# Privacy Sanitization
echo "Sanitizing private serial numbers and identifiers..."
python3 - "$OUT_DIR" <<'PY'
import pathlib, re, sys

root = pathlib.Path(sys.argv[1])
mac_re = re.compile(r'(?i)\b(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}\b')
serial_re = re.compile(r'(?i)(serial(?:number)?\s*[=:]\s*)[A-Z0-9]{8,14}')
uuid_re = re.compile(r'(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')

for p in root.glob('*.txt'):
    try:
        text = p.read_text(encoding='utf-8', errors='replace')
        text = mac_re.sub('<REDACTED_MAC>', text)
        text = serial_re.sub(r'\1<REDACTED_SERIAL>', text)
        text = uuid_re.sub('00000000-0000-0000-0000-000000000000', text)
        p.write_text(text, encoding='utf-8')
    except Exception:
        pass
PY

# Package into ZIP
ZIP_NAME="WEX_MACOS_REPORT_$STAMP.zip"
ZIP_PATH="$HOME/Desktop/$ZIP_NAME"
(cd "$HOME/Desktop" && zip -rq "$ZIP_NAME" "$(basename "$OUT_DIR")")

# Copy to USB if present
for vol in /Volumes/*; do
    if [ -d "$vol/EFI" ] || [ -d "$vol/WEX_083_MAC_KIT" ] || [ -f "$vol/ventoy" ]; then
        cp "$ZIP_PATH" "$vol/" 2>/dev/null && echo "Report also copied to USB drive: $vol/$ZIP_NAME"
        break
    fi
done

echo ""
echo "======================================================================"
echo "    DIAGNOSTIC COMPLETE!                                              "
echo "    Sanitized Report Archive: $ZIP_PATH                               "
echo "======================================================================"
