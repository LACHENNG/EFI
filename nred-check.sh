#!/bin/bash
# ============================================================
# NootedRed 状态采集脚本（macOS 14 Sonoma / Cezanne 1002:1638）
#
# 用法（在 macOS 终端里执行，二选一）：
#   sudo diskutil mount disk0s1 && bash /Volumes/EFI/nred-check.sh
#
# 说明：
#   - 脚本会把报告写到 EFI 分区（FAT32），这样重启回 Windows 后能直接读到；
#   - 同时在桌面留一份 nred-report.txt 作备份；
#   - 只读采集，不修改系统任何设置。
# ============================================================

OUT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ESP 挂载后，OC 实际在 /Volumes/EFI/EFI/OC（Windows 侧是 S:\EFI\OC）
if [ -d "$OUT_DIR/EFI/OC" ] && [ -w "$OUT_DIR/EFI/OC" ]; then
  REPORT="$OUT_DIR/EFI/OC/nred-report.txt"
elif [ -d "$OUT_DIR/OC" ] && [ -w "$OUT_DIR/OC" ]; then
  REPORT="$OUT_DIR/OC/nred-report.txt"
elif [ -w "$OUT_DIR" ]; then
  REPORT="$OUT_DIR/nred-report.txt"
else
  REPORT="$HOME/Desktop/nred-report.txt"
fi

{
  echo "================================================================"
  echo " NootedRed 诊断报告   $(date '+%Y-%m-%d %H:%M:%S')"
  echo "================================================================"
  echo
  echo "### 0. 关键结论（先看这里）"
  echo "--- GPU ---"
  system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Chipset Model|VRAM|Metal|Resolution|Display Type" 
  echo "--- NRed 关键属性 ---"
  ioreg -l -w 0 2>/dev/null | grep -oE "NRed[A-Za-z0-9]+=[^\"[:space:]]+" | sort -u
  echo "--- 是否加载 ---"
  kextstat 2>/dev/null | grep -iE "nooted" 
  echo
  echo "### 1. 系统"
  sw_vers
  uname -a
  echo "CPU : $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
  echo "机型: $(sysctl -n hw.model 2>/dev/null)"
  echo
  echo "### 2. SIP / 启动参数"
  csrutil status 2>&1
  echo "boot-args: $(nvram boot-args 2>/dev/null | sed 's/^boot-args[[:space:]]*//')"
  echo
  echo "### 3. 显卡完整信息"
  system_profiler SPDisplaysDataType 2>/dev/null
  echo
  echo "### 4. 加速器 / 相关 kext"
  kextstat 2>/dev/null | grep -Ei "nooted|lilu|whatevergreen|amd|agdp"
  echo
  echo "### 5. NootedRed 全部运行属性"
  ioreg -l -w 0 2>/dev/null | grep -E "NRed" | sed 's/^ *//' | sort -u | head -120
  echo
  echo "### 6. VP9 / VCN 解码能力"
  ioreg -l -w 0 2>/dev/null | grep -E "IOGVAVP9|IOGVAXDecode|IOGVA.*Decode|IOGVA.*Encode" | head -30
  echo
  echo "### 7. 内核日志（NRed 相关，最近）"
  dmesg 2>/dev/null | grep -iE "nred|nooted" | tail -80
  echo
  echo "### 8. 统一日志（最近 5 分钟，可能较慢）"
  log show --last 5m --style compact 2>/dev/null | grep -iE "nred|nooted" | tail -40
  echo
  echo "### 9. 音频"
  system_profiler SPAudioDataType 2>/dev/null | head -50
  echo
  echo "### 10. 网络 / 蓝牙"
  networksetup -listallhardwareports 2>/dev/null
  system_profiler SPBluetoothDataType 2>/dev/null | head -40
  echo
  echo "### 11. 电池 / 电源"
  pmset -g batt 2>/dev/null
  echo
  echo "### 12. 最近的崩溃 / panic 报告"
  ls -lt /Library/Logs/DiagnosticReports 2>/dev/null | head -15
  echo
  echo "### 13. 磁盘"
  diskutil list 2>/dev/null
  echo
  echo "报告结束   $(date '+%Y-%m-%d %H:%M:%S')"
} > "$REPORT" 2>&1

cp "$REPORT" "$HOME/Desktop/nred-report.txt" 2>/dev/null

echo ""
echo "报告已写入：$REPORT"
echo "桌面副本  ：$HOME/Desktop/nred-report.txt"
echo ""
echo "接下来请做第 3 节的手工验收，然后再运行一次本脚本，最后重启回 Windows。"
