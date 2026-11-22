# CLAUDE.md — 黑苹果（Lenovo 82MS / Ryzen 7 5800H）项目背景与避坑指南

> 给下一个接手这个仓库的 AI / 人：先读这份文件，再动任何东西。
> 最后更新：2026-11-22

---

## 1. 用户与环境

- 机器：**Lenovo 82MS**，AMD **Ryzen 7 5800H**（8C/16T），核显 **1002:1638（Cezanne / Vega 8）**，16 GB，NVMe `WDC PC SN730 512G`。
- 触控板：**ELAN06FA**（I2C HID，挂在 AMD I2C 控制器 `ACPI\AMDI0010` 上），macOS 下用 VoodooI2C + VoodooI2CHID 即可，不需要 ELAN 卫星驱动。
- 双系统：Windows 11（200 GB，C 盘）+ 黑苹果（约 151 GB APFS，同一块 NVMe 的 `disk0p5`）。
- 引导：**OpenCore 1.0.1**，位于同一块盘的 ESP（`disk0p1`，260 MB，Windows 侧盘符 `S:`）。
- 固件启动项：`OC` → `\EFI\OC\OpenCore.efi`，GUID `{92ace934-6205-11ef-9ceb-806e6f6e6963}`；`Windows Boot Manager` → `\EFI\Microsoft\Boot\bootmgfw.efi`。
- 用户使用中文，非专业逆向；给操作步骤要**可双击、可复制粘贴**，并写明失败分支。
- 用户 macOS 用户名：`langchen`（桌面 `/Users/langchen/Desktop`）。

### 系统版本

- 原始配置的内核补丁 `MaxKernel = 23.99.99`，即只支持 **macOS 14 Sonoma（Darwin 23）**。
- 2026-08 时能正常启动；2026-11 时原配置下的 VoodooI2C 2.8 会卡死（推测系统在 8 月后更新过，见第 5 节坑 #8）。
- 具体版本号仍需在 macOS 里用 `sw_vers` 确认（截至本文档最后更新尚未拿到）。

---

## 2. 目标

让 **AMD 核显硬件加速**完善：

1. Metal 渲染加速（NootedRed 基础功能）；
2. **VCN 视频硬解**（H.264/HEVC/VP9，只有 steve12311 fork 才支持）；
3. 修掉花屏/卡顿（`-NRedDisplayFix`）；
4. 保持触控板、亮度、音频、Wi-Fi、蓝牙、电池、睡眠可用。

参考实现：

- 视频作者 EFI：<https://github.com/Kingtous/thinkbook14p-Gen2-ACH-hackintosh>（macOS 26，OC 1.0.8，SMBIOS MacBookPro16,2）
- NootedRed 修复 fork：<https://github.com/steve12311/NootedRed>（本次用 `v0.9.0-pre-release.19` RELEASE）
- 本仓库：<https://github.com/LACHENNG/EFI>

---

## 3. 文件与配置布局

```
仓库根目录（= ESP 的 EFI 目录内容）
├─ BOOT/BOOTx64.efi          # 保持原样（Windows 的 bootmgfw 备份，不要覆盖 OC 入口）
├─ OC/
│  ├─ config.plist           # 当前启用配置（见下表）
│  ├─ config-*.plist         # 多套可切换配置（Windows 侧用「切换配置.cmd」）
│  ├─ ACPI/ Drivers/ Resources/
│  └─ Kexts/
│     ├─ Lilu.kext                 # 1.7.2（fork 要求 ≥1.7.0）
│     ├─ NootedRed.kext            # fork 0.9.0（主）
│     ├─ NootedRed-1.0.0.kext      # 上游 1.0.0（回退，配置里默认禁用）
│     ├─ AMFIPass.kext             # 1.4.0（原配置有，新版一度删除导致问题）
│     ├─ VoodooI2C.kext            # 已升级到 2.9.1（2.8 会在新系统卡死）
│     └─ ...（其余原样）
├─ CLAUDE.md
└─ docs/                     # 操作明细、说明
```

### 配置变体（Windows 侧 `切换配置.cmd` 编号）

| # | 文件 | 内容 | 状态 |
|---|---|---|---|
| 1 | config.plist | fork + SecureBootModel **Disabled** | 启动失败（回菜单） |
| 2 | config-sbdefault.plist | fork + **Default** | 启动失败（卡 VoodooGPIO） |
| 3 | config-fallback.plist | 上游 1.0.0 + Disabled | 未单独验证 |
| 4 | config-fallback-sbdefault.plist | 上游 1.0.0 + Default | 未单独验证 |
| 5 | config-debug-fork.plist | fork + Default + AppleDebug + 精简 LogModules | 卡 VoodooI2C |
| 6 | config-debug-fallback.plist | 上游 + Default + AppleDebug | 未单独验证 |
| 7 | config-amfipass-fork.plist | fork + AMFIPass + Default（**VoodooI2C 2.9.1 已替换**） | **待测：首选** |
| 8 | config-amfipass-fallback.plist | 上游 + AMFIPass + Default | 卡 VoodooI2C（2.8 时代） |
| 9 | config-noi2c-fork.plist | fork + AMFIPass + Default + **禁用 VoodooI2C 全套** | ✅ **能进桌面**（触控板失效） |
| 10 | config-noi2c-fallback.plist | 上游 + AMFIPass + Default + 禁用 VoodooI2C | 未测 |
| 11 | config-polling-fork.plist | fork + AMFIPass + Default + `-vi2c-force-polling` | 待测（2.9.1 下可替代 7） |
| 12 | config-polling-fallback.plist | 上游 + 同上 | 未测 |

---

## 4. 当前状态（2026-11-22 晚）

- ✅ 已确认：**VoodooI2C 2.8 是进不去桌面的根因**；禁用整套 VoodooI2C（变体 9）可以稳定进入 macOS 桌面，键盘、USB 鼠标正常，触控板失效。
- ✅ 已把 **VoodooI2C 升级到 2.9.1**（2024-11 发布，支持新系统），插件目录结构不变，配置无需改路径。
- ⏳ 待验证：变体 **7**（fork + AMFIPass + Default + VoodooI2C 2.9.1）是否能进桌面且触控板恢复；不行再试 **11**（轮询模式）。
- ⏳ 待验证：fork 的核显加速/硬解是否真的生效（需 `nred-check.sh` 报告，见第 6 节）。
- ⚠️ 尚未拿到 macOS 端诊断报告（`nred-report.txt`）。上次报告写在 macOS 桌面（APFS），Windows 读不到，需复制到 ESP 或 U 盘。

---

## 5. 关键坑（按踩坑顺序，务必看）

1. **`EFI\Microsoft\Boot\BCD` 被 Windows 占用，robocopy 备份会失败（exit 9）。**
   备份 ESP 时**绝对不能备份/还原整个 `EFI` 目录**，否则 `/MIR` 会删掉读不到的 BCD，导致 Windows 报 `0xc000000f`。
   正确做法：**只备份/替换 `EFI\OC`**（本仓库的 `install-efi.ps1` 已按此实现）。

2. **不要对 ESP 用 `robocopy /MIR`。** 只做 `/E` 覆盖；需要回滚时按“安装前文件清单”删除新增文件。

3. **Windows 批处理（`.cmd`）里不要写中文文件名给 `powershell -File`。**
   cmd 按 GBK 解析 UTF-8 批处理，会把 `检查修复引导.ps1` 变成乱码 `妫€鏌ヤ慨澶嶅紩瀵?ps1`。
   规则：`.cmd` 内容保持纯 ASCII，只引用英文脚本名（`check-boot.ps1`、`read-report.ps1` 等）。

4. **macOS 挂载 ESP 后，OC 在 `/Volumes/EFI/EFI/OC`，不是 `/Volumes/EFI/OC`。**
   采集脚本写报告要用 `/Volumes/EFI/EFI/OC/nred-report.txt`（Windows 侧 `S:\EFI\OC\nred-report.txt`）。

5. **OpenCore 的日志文件在把控制权交给 boot.efi 前就关闭了。**
   `Misc/Debug/Target=67` 只记录 OC 自己的阶段；`AppleDebug`、`LogModules` 都**抓不到** boot.efi/内核启动后的报错。要看后面的报错只能：手机慢动作录像（240fps），或看屏幕最后一行。

6. **`SecureBootModel` 与 macOS 安装时的策略绑定。**
   原配置 `Default`（对应 `j223`）；改成 `Disabled` 后 OC 日志里 `OCI4` 校验消失，系统会退回菜单。要么保持 `Default`，要么确认系统是在 `Disabled` 下安装的。

7. **AMFIPass 是原配置的一部分，不能随手删。**
   它负责关闭 AMFI 签名检查；删除后第三方未签名 kext（Voodoo、NootedRed 等）可能被拦或引发异常。要放松 SIP 时也应保留它（或确认 `csr-active-config` 生效）。

8. **VoodooI2C 2.8 在更新后的 macOS 上会卡死在内核启动阶段。**
   现场日志最后一行：`VoodooI2CREController::RWDBegin Starting I2C controller` → `VoodooGPIORMD::GPIO Controller is already awake!` → 卡住/重启。
   解决：升级 **VoodooI2C 2.9.1**（本仓库已替换）；临时绕过：禁用整套 VoodooI2C（变体 9），或加 `-vi2c-force-polling`（跳过 GPIO 中断）。

9. **NootedRed fork 0.9.0 的要求：**
   - Lilu **≥ 1.7.0**（本仓库 1.7.2）；
   - 用户态补丁需要 `csr-active-config = 430A0000`（**按字节写**：`43 0A 00 00`，即 `0x00000A43`；SIP 全开 `00000000` 不满足）；
   - 启动参数：`-NRedDisplayFix -NRedVideoFix`（硬解必须后者）；笔记本 EC 背光可加 `NRedECFix=1`；
   - 它的补丁数据是按 **macOS 14.8.9 / 23J631** 做的，低于此版本可能被逐项校验拒绝（安全，不生效），所以想要硬解最好把系统升到 14.8.9。

10. **不要覆盖 `EFI\BOOT\BOOTx64.efi`。**
    用户 ESP 上这个是 **Windows 的 bootmgfw**（1,693,640 字节），OC 走独立入口 `\EFI\OC\OpenCore.efi`；覆盖它没有收益，反而可能改变默认引导。

11. **`ProcessorType` 应为 3841（AMD）**，不是 1537（Intel 值）。

12. **esp 很小（260 MB）**，不要往里塞备份/zip；诊断报告只有几 KB 可以。

---

## 6. 诊断与操作工具（Windows 侧，位于 `D:\Users\12255\Desktop\new PLIST\一键安装`）

| 工具 | 作用 |
|---|---|
| `检查修复引导.cmd` | 检查 ESP 上 `BCD/bootmgfw/bootmgr/OC` 是否齐全；BCD 缺失时用 `bcdboot` 重建，并输出 `引导信息.txt` |
| `安装到ESP.cmd` | 只备份+替换 `EFI\OC`，哈希校验 + ocvalidate；失败自动回滚 |
| `还原ESP.cmd` | 按备份还原 `EFI\OC`（不动 Microsoft/BOOT） |
| `切换配置.cmd` | 选 1–12 号配置写入 `EFI\OC\config.plist`（自动备份 + 校验） |
| `抓取OC日志.cmd` | 把 ESP 根目录最新的 `opencore-*.txt` / `panic-*.txt` 复制到 `new PLIST\OC日志-最新.txt` |
| `读取诊断报告.cmd` | 从 ESP 取 `nred-report.txt` → `new PLIST\macOS报告.txt` |
| `启动顺序.cmd` | 把 OC 或 Windows 设为 UEFI 第一启动项（省 F12） |

macOS 侧脚本：`nred-check.sh`（安装器会放到 ESP 根目录）。

```bash
diskutil list | grep -i efi
sudo diskutil mount disk0s1
bash /Volumes/EFI/nred-check.sh
# 若 EFI 不可写，报告会落到 ~/Desktop，需再复制到 ESP 或 U 盘
sudo cp ~/Desktop/nred-report.txt /Volumes/EFI/
```

**报告里要重点看的字段**：`sw_vers`、`system_profiler SPDisplaysDataType`（GPU 名/VRAM/Metal）、`ioreg | grep NRed`（`NRedDisplayFixVersion`、`NRedVP9State`、`NRedFVRCEnabled` 等）。

---

## 7. 已知失败组合与结论

| 组合 | 症状 | 结论 |
|---|---|---|
| 原 ESP 配置（2026-08） | 当时能进 | 基线 |
| fork + Lilu 1.7.2 + csr 430A0000 + SB Disabled，无 AMFIPass | 跑码后回 OC 菜单 | `SecureBootModel` 改动 / 缺 AMFIPass |
| fork + Default，无 AMFIPass（变体 2/5） | 卡 `VoodooGPIORMD` | VoodooI2C 2.8 |
| 上游 + Default + AMFIPass（变体 8） | 卡 `VoodooI2CREController...` | VoodooI2C 2.8 |
| fork + AMFIPass + 禁用 VoodooI2C（变体 9） | **能进桌面** | 证实 VoodooI2C 是根因 |

---

## 8. 下一步 TODO

1. 用变体 **7**（或 11）验证 VoodooI2C 2.9.1 是否解决卡死 + 触控板恢复。
2. 拿到 `nred-report.txt`，确认：
   - `sw_vers` 具体版本；
   - GPU 是否 `AMD Radeon RX Vega 8`、VRAM 正常、Metal 3；
   - `NRedDisplayFixVersion=3`、`NRedVP9State` 等是否出现（fork 是否真正生效）。
3. 若硬解未生效：确认系统是否为 14.8.9；否则先升级 Sonoma 到 14.8.9，再重测。
4. 触控板若 2.9.1 仍不行：尝试只禁用 `VoodooGPIO`、保留 `VoodooI2C`+`VoodooI2CHID`，或换 satellite（Synaptics/ELAN）。
5. 稳定后再清理：去掉 `-v debug=0x100`、去掉调试配置、把 `config.plist` 定为最终版。

---

## 9. 绝对不要做

- 不要对 ESP 执行 `robocopy /MIR` 或整目录还原（会删 BCD）。
- 不要覆盖 `EFI\Microsoft`、`EFI\BOOT\BOOTx64.efi`。
- 不要把 macOS 桌面上的文件当成 Windows 能直接读（APFS）；要经 ESP/U 盘/DiskGenius 转出。
- 不要在 `.cmd` 里写中文脚本文件名。
- 不要同时改多个变量做测试；一次只动一个，先备份。
- 不要在未确认 `sw_vers` 的情况下断言“系统是 14.x”以外的版本。
