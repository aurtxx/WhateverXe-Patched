#!/usr/bin/env bash
# ==============================================================================
# Anywhere-Patched Hackintosh: Universal Linux Xe-LP Diagnostic & Audit Tool
# Repository: https://github.com/aurtxx/WhateverXe-Patched
# Supports: Intel 12th/13th Gen Alder Lake & Raptor Lake Xe-LP (UHD / Iris Xe)
# ==============================================================================

set -uo pipefail

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${1:-$HOME}/WEX_LINUX_REPORT_$STAMP"
mkdir -p "$OUT_DIR"

LOG_FILE="$OUT_DIR/diagnostic_summary.txt"
exec > >(tee "$LOG_FILE") 2>&1

echo "======================================================================"
echo "    ANYWHERE-PATCHED HACKINTOSH: LINUX XE-LP HARDWARE AUDIT TOOL     "
echo "    Generated: $(date)                                               "
echo "======================================================================"
echo ""

# Section 1: System & Linux Kernel
echo "--- [1/5] System & Kernel ---"
uname -a
if [ -f /etc/os-release ]; then
    grep -E "^(NAME|VERSION)=" /etc/os-release || true
fi
echo ""

# Section 2: Intel iGPU PCI Hardware Identity
echo "--- [2/5] Intel iGPU PCI Identity (00:02.0) ---"
if command -v lspci >/dev/null 2>&1; then
    lspci -nnvv -s 00:02.0 | tee "$OUT_DIR/lspci_00_02_0.txt"
else
    echo "lspci not found. Reading from /sys/bus/pci..."
fi

GPU_SYS="/sys/bus/pci/devices/0000:00:02.0"
if [ -d "$GPU_SYS" ]; then
    VEN="$(cat "$GPU_SYS/vendor" 2>/dev/null || echo "unknown")"
    DEV="$(cat "$GPU_SYS/device" 2>/dev/null || echo "unknown")"
    REV="$(cat "$GPU_SYS/revision" 2>/dev/null || echo "unknown")"
    SUB_VEN="$(cat "$GPU_SYS/subsystem_vendor" 2>/dev/null || echo "unknown")"
    SUB_DEV="$(cat "$GPU_SYS/subsystem_device" 2>/dev/null || echo "unknown")"
    echo "PCI Device:    $VEN:$DEV (Rev $REV)"
    echo "Subsystem:     $SUB_VEN:$SUB_DEV"
fi
echo ""

# Section 3: i915 Engine Topology (The VCS0 vs VCS2 Discovery)
echo "--- [3/5] i915 Driver Engine Topology & MMIO Bases ---"
ENGINE_INFO="/sys/kernel/debug/dri/0/i915_engine_info"
if [ ! -r "$ENGINE_INFO" ]; then
    ENGINE_INFO="$(ls /sys/kernel/debug/dri/*/i915_engine_info 2>/dev/null | head -n 1 || true)"
fi

VCS2_DETECTED=0
if [ -r "$ENGINE_INFO" ]; then
    cat "$ENGINE_INFO" > "$OUT_DIR/i915_engine_info.txt"
    echo "Extracting hardware engine MMIO bases:"
    grep -E "(rcs[0-9]|bcs[0-9]|vcs[0-9]|vecs[0-9]).*base" "$ENGINE_INFO" || grep -E "vcs.*base" "$ENGINE_INFO" || true
    
    if grep -q "0x001d0000" "$ENGINE_INFO" || grep -q "1d0000" "$ENGINE_INFO"; then
        VCS2_DETECTED=1
    fi
else
    echo "debugfs i915_engine_info not accessible without root or debugfs mounted."
    echo "Checking dmesg for i915 engine allocations..."
fi
echo ""

# Section 4: SSEU (Slices, Sub-slices, Execution Units)
echo "--- [4/5] i915 SSEU Status (Execution Units & Slices) ---"
SSEU_INFO="/sys/kernel/debug/dri/0/i915_sseu_status"
if [ ! -r "$SSEU_INFO" ]; then
    SSEU_INFO="$(ls /sys/kernel/debug/dri/*/i915_sseu_status 2>/dev/null | head -n 1 || true)"
fi

if [ -r "$SSEU_INFO" ]; then
    cat "$SSEU_INFO" > "$OUT_DIR/i915_sseu_status.txt"
    grep -E "Available Slice Mask|Available Subslice Total|Available EU Total|Available EU Per Subslice" "$SSEU_INFO" || cat "$SSEU_INFO"
else
    echo "debugfs i915_sseu_status not accessible."
fi
echo ""

# Section 5: Automated Hackintosh Compatibility Diagnosis
echo "--- [5/5] Automated Hackintosh AI Agent Assessment ---"
if [ "$VCS2_DETECTED" -eq 1 ] || grep -q "0x001d0000" "$OUT_DIR/i915_engine_info.txt" 2>/dev/null; then
    echo ">> CRITICAL SILICON BINNING DETECTED: VCS2-ONLY DIE (fuses[4] = 0x000E00FB / video = 4) <<"
    echo "   1. Physical VCS0 (0x001C0000) is fused off on this CPU die."
    echo "   2. Logical VCS0 is mapped to physical VCS2 (MMIO base 0x001D0000)."
    echo "   3. Official WhateverXe <= 0.8.3 will fail with N97GTTopologyReady = No unless patched."
    echo "   4. REQUIRED HACKINTOSH FIX:"
    echo "      - Kext: Custom WhateverXe (with -wex-adlp-allow-vcs2 + HP PAVP crash fix)"
    echo "      - boot-args: -v debug=0x100 keepsyms=1 -disablegfxfirmware -igfxdvmt revcpu=1 -allow3d -wex-adlp-allow-vcs2"
    echo "      - ACPI: SSDT-PNLF.aml targeting _UID = 19"
else
    echo ">> STANDARD TOPOLOGY: Standard VCS0 present or not explicitly fused to VCS2. <<"
    echo "   Follow standard WhateverXe 0.8.3 deployment guidelines."
fi
echo ""

# Dump dmesg
if command -v dmesg >/dev/null 2>&1; then
    dmesg | grep -Ei "i915|drm|guc|huc|vcs[0-9]|video engine" | tail -n 1000 > "$OUT_DIR/i915_dmesg.txt" 2>/dev/null || true
fi

# Sanitize & Zip
echo "Sanitizing logs and creating archive..."
python3 - "$OUT_DIR" <<'PY'
import pathlib, re, sys

root = pathlib.Path(sys.argv[1])
mac_re = re.compile(r'(?i)\b(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}\b')
serial_re = re.compile(r'(?i)(serial(?:number)?\s*[=:]\s*)[A-Z0-9]{8,14}')

for p in root.glob('*.txt'):
    try:
        text = p.read_text(encoding='utf-8', errors='replace')
        text = mac_re.sub('<REDACTED_MAC>', text)
        text = serial_re.sub(r'\1<REDACTED_SERIAL>', text)
        p.write_text(text, encoding='utf-8')
    except Exception:
        pass
PY

ARCHIVE="${OUT_DIR}.zip"
if command -v zip >/dev/null 2>&1; then
    (cd "$(dirname "$OUT_DIR")" && zip -rq "$(basename "$ARCHIVE")" "$(basename "$OUT_DIR")")
    echo "Report Archive: $ARCHIVE"
else
    tar -czf "${OUT_DIR}.tar.gz" -C "$(dirname "$OUT_DIR")" "$(basename "$OUT_DIR")"
    echo "Report Archive: ${OUT_DIR}.tar.gz"
fi

echo ""
echo "======================================================================"
echo "    LINUX AUDIT COMPLETE!                                             "
echo "======================================================================"
