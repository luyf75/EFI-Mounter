# EFI-Mounter — EFI挂载器

一款简洁、直观的 macOS EFI / ESP 分区管理工具。

EFI-Mounter 专为 macOS 用户设计，用于识别、查看、挂载和卸载 EFI / ESP 分区，支持内置硬盘和外置存储设备。

## ✨ 主要功能

- 🔍 自动识别内置和外置磁盘
- 💾 显示磁盘总容量及 EFI 分区信息
- 🔧 一键挂载 EFI 分区
- ⏏️ EFI 分区卸载
- 🔄 自动刷新磁盘及挂载状态
- 🔃 手动刷新
- 📊 查看 EFI 详细信息
- 📋 一键复制 EFI 挂载路径
- 🖥️ 原生 macOS 图形界面
- ℹ️ 关于 EFI-Mounter
- 🧩 支持 Hackintosh / OpenCore EFI 管理

## 📊 EFI 详细信息

可以查看：

- 磁盘类型
- 磁盘名称
- 物理磁盘
- EFI 分区
- 磁盘容量
- EFI 容量
- 分区类型
- 当前状态
- 挂载路径

## 💿 下载

当前正式版本：

### EFI-Mounter v1.2.0

支持：

- Apple Silicon（arm64）
- Intel Mac（x86_64）

安装方式：

1. 下载 `EFI-Mounter-v1.2.0.dmg`
2. 打开 DMG
3. 将 **EFI挂载器** 拖入 Applications（应用程序）文件夹
4. 从应用程序中启动 EFI挂载器
## 🖥️ 软件截图

### 软件首页

![EFI-Mounter 首页](Screenshots/main.png)

### EFI 详细信息

![EFI详细信息](Screenshots/detail.png)

### 关于 EFI-Mounter

![关于 EFI-Mounter](Screenshots/about.png)

## 💻 系统要求

- macOS 11.0 Big Sur 或更高版本
- 支持 Intel Mac
- 支持 Apple Silicon Mac

## 🔐 权限说明

EFI 分区属于系统级磁盘分区。

执行 EFI 挂载等需要系统权限的操作时，macOS 可能会要求输入管理员密码。

这是 macOS 的正常安全机制。

## 📁 EFI / ESP 是什么？

EFI 分区（EFI System Partition，简称 ESP）是 GPT 磁盘上的系统启动分区。

在 macOS、Windows 以及 Hackintosh / OpenCore 环境中，EFI 分区通常用于存放启动相关文件。

例如 OpenCore EFI 通常包含：

```text
EFI/
├── BOOT/
├── OC/
└── Microsoft/
```

EFI-Mounter 可以帮助用户快速识别和挂载这些 EFI 分区，方便进行启动文件查看和维护。
## 🧩 Hackintosh / OpenCore

EFI-Mounter 特别适合 Hackintosh 用户管理 OpenCore EFI。

可以用于：

- 挂载 OpenCore EFI
- 查看 EFI 文件
- 修改 EFI 配置
- 维护 `EFI/OC`
- 管理 `config.plist`
- 检查启动文件

EFI-Mounter 本身不会自动修改 EFI 中的文件，用户可以根据需要自行进行 EFI 管理。

## 🛠️ 技术信息

- Swift
- AppKit
- Xcode
- macOS `diskutil`
- Universal Binary
- arm64 + x86_64

最低支持：

**macOS 11.0 Big Sur**

## 📦 当前版本

**EFI-Mounter v1.2.0**

当前版本已经完成正式发布。

## 👨‍💻 作者

**没气儿的青蛙**

邮箱：

386701036@qq.com

GitHub：

https://github.com/luyf75

项目地址：

https://github.com/luyf75/EFI-Mounter

## 📄 开源协议

本项目采用仓库中的 `LICENSE` 文件所规定的开源许可证。

## ⭐ 支持项目

如果 EFI-Mounter 对你有帮助，欢迎在 GitHub 上 Star 本项目。

欢迎提交 Issue 和 Pull Request，共同改进 EFI-Mounter。

---

**EFI-Mounter — EFI挂载器**

macOS EFI / ESP 分区管理工具。
