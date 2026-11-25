# 方舟纪元：失落的世界 — Aeon Ark: The Lost Frontier

**正式发行版本：1.0.0**

- Minecraft Java：**26.3**
- Fabric Loader：**0.20.1**
- Java：**25 x64**
- PCL 导入格式：**MMC 实例 ZIP**
- 实际打包模组：**150 个 JAR**
- 原创任务：**72 条，分为 8 个分类**

## 下载

[下载完整 PCL 整合包 ZIP](https://github.com/KevinWang137137/aeon-ark-lost-frontier/releases/download/v1.0.0/AeonArk-26.3-Fabric-v1.0.0.zip)

[打开 GitHub v1.0.0 正式发行页面](https://github.com/KevinWang137137/aeon-ark-lost-frontier/releases/tag/v1.0.0)

这是完整客户端实例 ZIP，内含实际模组 JAR、配置、任务数据、Global Packs 和 AEON ARK 标题 Logo 资源包。GitHub 发布工作流确认 ZIP 内有 **150 个实际 JAR 文件**，并在发布前校验了 Modrinth 下载文件的哈希。

## PCL 安装步骤

1. 从上方 Releases 页面下载 ZIP。
2. 将 ZIP 直接拖入 PCL，导入为一个**全新的独立实例**。
3. 首次安装时保持联网，让 PCL 下载 Minecraft、Fabric 和运行库。
4. 选择 Java 25 x64。建议先分配 5GB 内存；这只是起始建议，不代表已经完成性能保证。
5. 创建新世界测试。不要将该实例指向已有存档。

## 整合包内容

- 特殊孤岛生存开局，标准生存难度。
- 72 条原创中文章节任务，分为 8 个分类。
- 探索、建筑结构、生物、食物、工业系统和魔法内容。
- AEON ARK 标题 Logo 资源包，已配置为新实例默认启用。
- Windows 构建工作流自动解析 Modrinth 依赖并校验文件哈希。

## 验收边界

**GitHub Actions 已自动验证：** 发布 ZIP 内有 150 个实际 `.jar`；下载时校验了 Modrinth 文件哈希；PCL MMC ZIP 结构通过检查；标题纹理和资源包元数据存在；`options.txt` 已启用标题资源包；任务数据静态校验通过。

**仍需真实桌面游戏环境确认：** 启动后的主菜单标题图视觉效果、目标电脑上的 PCL 导入、孤岛出生点、游戏内任务计数、模组之间的运行稳定性，以及 5GB 内存表现。标题资源包已打包并配置自动启用，但当前 CI 环境没有人工查看正在运行的游戏画面。

## 本地开发

运行 `python scripts/validate_quests.py` 可检查原创任务数据。

Windows 下运行 `Build_PCL整合包.bat` 可构建 PCL 实例 ZIP。如果无法为 Minecraft 26.3 + Fabric 解析并验证至少 150 个实际模组 JAR，构建会直接失败。

长期任务目标仍为 360+ 条。项目历史和技术记录见 `CHANGELOG.md` 与 `docs/`。
