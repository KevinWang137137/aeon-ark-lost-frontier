# 方舟纪元：失落的世界 — Aeon Ark: The Lost Frontier

**当前开发版本：0.2.0-alpha.9（预览版）**

这是面向 Minecraft Java 26.3 + Fabric 的任务冒险整合包。发布时提供**一个完整客户端 ZIP**，实际模组 JAR 已经装在压缩包里，不是只给一份清单让 PCL 再逐个下载模组。

## 当前配置

- Minecraft Java：26.3
- Fabric Loader：0.20.1
- Java：25 x64
- 建议内存：先分配 5GB
- 玩法方向：小岛开局、章节任务、探索、农业、工业与魔法
- 当前任务内容：72 条中文任务、8 个分类（持续扩展中）

## PCL 安装

1. 从 GitHub Releases 下载唯一的 \`AeonArk-26.3-Fabric-v0.2.0-alpha.9.zip\`。
2. 将 ZIP 直接拖入 PCL。
3. PCL 识别 MMC 实例包后，按提示选择一个空的安装位置。
4. ZIP 已包含实际模组 JAR、配置、任务与数据包；PCL 不需要逐个联网下载模组。
5. PCL 仍可能需要获取 Minecraft/Fabric 本体及其运行库。首次安装请保持联网。
6. 使用 Java 25 x64，建议分配 5GB 内存；创建新世界进行测试。

## ZIP 内容

压缩包根目录直接包含：
- \`mmc-pack.json\` 与 \`instance.cfg\`：PCL 可识别的实例组件信息（Minecraft 26.3 + Fabric 0.20.1）。
- \`.minecraft/mods/\`：本整合包实际使用的模组 JAR，构建时从 Modrinth 下载并校验哈希后放入 ZIP。
- \`.minecraft/config/\`：模组配置。
- \`.minecraft/global_packs/\`：任务与全局数据包。
- 其他存在的资源包、光影包、默认配置和脚本目录。

这是完整客户端文件包，不是 Modrinth 在线下载清单。构建检查会核对 ZIP 内的实际 JAR 数量与解析出的模组数量。

## 当前验收状态

预览版尚需真实 PCL 导入与游戏内验收。重点检查：PCL 是否识别 MMC 包、Fabric 是否成功安装、所有模组是否加载、任务目标是否计数、世界生成与长时间稳定性。

如果启动失败，请提供 PCL 错误信息和实例目录 \`logs/latest.log\`。
