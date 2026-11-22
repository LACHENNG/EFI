# LACHENNG/EFI — Lenovo 82MS (Ryzen 7 5800H) OpenCore 配置

> 详细背景、踩坑记录和后续 TODO 见 **[CLAUDE.md](CLAUDE.md)**；操作步骤见 **[docs/操作明细.md](docs/操作明细.md)**。

## 硬件

| 项目 | 型号 |
| --- | --- |
| 机器 | Lenovo 82MS |
| CPU | AMD Ryzen 7 5800H (8C/16T) |
| 核显 | AMD Radeon Vega 8 — `1002:1638` (Cezanne) |
| 内存 | 16 GB |
| 硬盘 | WDC PC SN730 512G NVMe（Windows + macOS 双系统） |
| 引导 | OpenCore 1.0.1（ESP `disk0p1`） |

## 当前方案

- **NootedRed**：`steve12311/NootedRed` fork `v0.9.0-pre-release.19`（RELEASE）
  - 支持 VCN 视频硬解、VP9、显示/花屏修复
  - 启动参数：`-NRedDisplayFix -NRedVideoFix`
  - 依赖 Lilu ≥ 1.7.0（仓库内为 1.7.2）
- **AMFIPass 1.4.0**：关闭 AMFI 签名检查（原配置必需，勿删）
- **VoodooI2C 2.9.1**：修复 2.8 在新版 macOS 上 I2C 控制器卡死的问题
- **SecureBootModel**：`Default`（该 macOS 是在 j223 策略下安装的，改 Disabled 会退回 OC 菜单）
- **csr-active-config**：`430A0000`（字节 `43 0A 00 00`，NootedRed 用户态补丁要求）
- 回退用上游 NootedRed 1.0.0 保留在 `OC/Kexts/NootedRed-1.0.0.kext`（配置里默认禁用）

## 配置变体

`OC/` 下有多套 `config-*.plist`，Windows 侧用 `一键安装\切换配置.cmd` 一键切换（自动备份 + ocvalidate 校验）：

| # | 文件 | 说明 |
| --- | --- | --- |
| 1 | config.plist | fork + SecureBootModel Disabled |
| 2 | config-sbdefault.plist | fork + Default |
| 3 | config-fallback.plist | 上游 1.0.0 + Disabled |
| 4 | config-fallback-sbdefault.plist | 上游 1.0.0 + Default |
| 5 | config-debug-fork.plist | fork + Default + AppleDebug + 精简日志 |
| 6 | config-debug-fallback.plist | 上游 + Default + AppleDebug |
| 7 | config-amfipass-fork.plist | fork + AMFIPass + Default（**推荐**） |
| 8 | config-amfipass-fallback.plist | 上游 + AMFIPass + Default |
| 9 | config-noi2c-fork.plist | fork + AMFIPass + Default + 禁用 VoodooI2C（触控板失效，应急） |
| 10 | config-noi2c-fallback.plist | 上游 + 同上 |
| 11 | config-polling-fork.plist | fork + AMFIPass + Default + `-vi2c-force-polling` |
| 12 | config-polling-fallback.plist | 上游 + 同上 |

## 快速使用

1. 把本仓库的 `BOOT/`、`OC/` 复制到 ESP 的 `EFI/` 下（**不要动 `EFI/Microsoft` 和 `EFI/BOOT/BOOTx64.efi`**）。
2. 重启 → 开机 F12 选 `OC` → 选 macOS。
3. 首次如遇问题，优先看 [CLAUDE.md](CLAUDE.md) 的“关键坑”章节。

## 参考

- 视频/EFI 作者：<https://github.com/Kingtous/thinkbook14p-Gen2-ACH-hackintosh>
- NootedRed 修复 fork：<https://github.com/steve12311/NootedRed>
- NootedRed 上游：<https://github.com/ChefKissInc/NootedRed>
- VoodooI2C：<https://github.com/VoodooI2C/VoodooI2C>
