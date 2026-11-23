# 方舟纪元：失落的世界 — Aeon Ark: The Lost Frontier

**当前开发版本：0.2.0-alpha.9（预览版）**

这是一个面向 Minecraft Java 26.3 + Fabric 的任务冒险整合包。主要安装方式是：**下载一个 ZIP，直接拖入 PCL 导入**。本项目不再制作或发布独立启动器 EXE。

## 当前配置

- Minecraft Java：26.3
- Fabric Loader：0.20.1
- Java：25 x64
- 建议内存：先分配 5GB，之后按实际运行情况调整
- 难度：标准生存
- 玩法方向：Dreamcraft 风格小岛开局、章节任务、探索、农业、工业与魔法
- 当前任务内容：72 条中文任务、8 个分类；后续继续扩展

## PCL 安装方式

1. 从 GitHub Releases 下载唯一的 AeonArk-26.3-Fabric-v0.2.0-alpha.9.zip。
2. 打开 PCL，将 ZIP 文件直接拖入 PCL 窗口。
3. 按 PCL 提示导入并创建独立游戏版本。
4. 首次安装需要联网。ZIP 内含 Modrinth 格式清单 modrinth.index.json，PCL 会按清单下载 Minecraft/Fabric 组件和模组。
5. 使用 Java 25 x64；建议先分配 5GB 内存。
6. 安装完成后创建新世界测试。不要将预览版直接覆盖到已有实例或存档。

## ZIP 内部结构

- modrinth.index.json：位于 ZIP 根目录，供 PCL 识别为 Modrinth 整合包并解析模组下载项。
- overrides/config/：整合包配置。
- overrides/global_packs/：任务与数据包资源。
- overrides/aeon-ark-mod-resolution-report.json：构建时解析出的模组版本与可选项警告。

第三方模组 JAR 不直接打包进 ZIP；PCL 首次导入时根据清单下载，避免整合包重复携带大体积文件。

## 本地构建（开发者）

在联网 Windows 环境中运行 Build_PCL整合包.bat。脚本会查询 Modrinth API、解析必需模组及其必需依赖、检查文件名冲突和下载元数据完整性，并下载/校验纳入 overrides 的数据包。构建完成后，唯一交付文件位于 release/。

## 当前验收状态

这是持续开发中的预览版，不宣称已经通过完整游戏验收。以下项目仍需在 PCL 实际导入并启动后验证：

- 当前 Minecraft 26.3 / Fabric 组合能否完整安装并启动。
- 每个模组的实际加载兼容性与内存占用。
- JustQuests 任务显示、前置解锁、目标计数与奖励。
- 小岛开局种子与出生点是否符合设计。
- 长时间游玩稳定性、结构生成与数据包效果。

如果启动失败，请提供 PCL 的错误信息和游戏目录 logs/latest.log，以便逐项修复。
