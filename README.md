# 参考资料

https://www.youtube.com/watch?v=CdLvTaBCYyA


# 使用步骤
## 一. USB 启动盘（可以选择如下几种）
- 制作恢复镜像，参考[老吴黑苹果](https://hpglw.com/macOS-Sonoma-14.4.html)
- 下载镜像dmg后使用BalenaEtcher写入镜像到USB [下载地址](https://m.bilibili.com/opus/933508367289155587) 
- 其他

## 二. 安装后
1. 打开软件花屏问题（百度云网盘，QQ，Chrome等）
- 跟进NootedRed是否修复双源崩溃问题（Dual source blend causes corruption and freezes）
- 崩溃的临时解决方法：使用 [GLFriend](https://github.com/ovoME/GLFriend)工具修复一下要打开的软件
2. 分辨率问题
- 2k显示屏可能字体太小，可以使用[HiDPI](https://github.com/xzhih/one-key-hidpi)开启缩放。原理就是将原本一个像素作为两个或者多个像素来填充，即保证了图标放大，又保证了清晰。注意在使用工具输入自定义的分辨率，应该和你的屏幕分辨率成一定的比例关系。比如缩放125%，150%，200%，则自定义分辨率应该为原来（你显示屏）的3/4，2/3/，1/2. 

例子：
如果你的显示器是 2560x1400 的分辨率，以下是不同缩放比例下的目标分辨率：

- **125% 缩放**:  
  - 目标分辨率：2048x1120
  
- **150% 缩放**:  d fzx xz    
  - 目标分辨率：1707x933
  
- **200% 缩放**:  
  - 目标分辨率：1280x700

这些目标分辨率是你在使用 `hidpi.sh` 脚本时可以输入的合法分辨率，以达到相应的缩放效果。


# 参考
1. https://qqquq.com/article/amd-laptop-hackintosh/
2. docker可能解决方案：virual box + linux [参考](https://macos86.it/topic/6535-guidevirtualbox-on-sonoma-and-amd-hackintosh/)

> 对于使用virtual box你需要：
禁用MacOs的SIP，并加载AMFIPass kexts，以便virtual box能正常在AMD hackintosh中启动。
Virtual box 需要6.1.50（7.x不支持）

> Disable SIP:
Boot into Recovery Mode (press and hold Cmd + R during startup).
Open Terminal from the Utilities menu.
Run: csrutil disable.
Reboot.
Load AMFIPass Kext:

> Download the AMFIPass kext.
Place the kext in your EFI partition under EFI/OC/Kexts/.
Add it to your config.plist under the Kernel -> Add section.
Save and reboot.

3. 设置好virtual box后，有个额外的好处，现在可以使用如下命令使用minikube+virtual box实现和docker desktop类似的效果，直接在终端使用docker 命令，是目前比较好的透明的，和原来体验差不多的方式。[参考](https://www.whidy.net/amd-hackintosh-incompatible-docker-desktop-and-solution)
```shell
brew install virtualbox
brew install minikube docker
minikube start --driver=virtualbox --keep-context
eval $(minikube docker-env)
```
