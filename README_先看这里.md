# 方舟纪元：失落的世界 — Minecraft 26.3 制作工程 V0.2.0-alpha.3

**项目目标：** Minecraft Java 26.3 + Fabric，面向 PCL/PCL2，标准生存难度，Dreamcraft 式小岛开局。

## 配置锁定
- Minecraft Java：**26.3**
- Mod Loader：**Fabric Loader 0.20.1**
- Fabric API：**0.166.2+26.3**（以构建脚本实际解析出的兼容构建为准）
- Java：**25，64 位**
- 内存目标：约 **5GB**，需实机压力测试；默认不启用光影
- 难度：标准
- 开局：小型森林生存岛，候选种子 `3404544535694295634`

> 选用 26.3 Fabric，是因为目前能确认的 JustQuests、Ala Industrial、Spellgems、JEI 等项目存在 26.3 Fabric 文件。群系扩展改用 Terralith 26.3 数据包，并先放入 optional_data，待小岛世界生成验收后再决定是否默认启用。旧方案 1.21.1 NeoForge 已撤销。Create / Ars Nouveau 不作为本版硬依赖，分别用 Ala Industrial / Spellgems 替代。

## 本版已经制作的内容
- 72 条 JustQuests 中文任务，8 个分类，每类 9 条；包括前置解锁、目标、经验奖励和提示信息。
- 岛屿启航、越海而行、生态探索、农业料理、工业机械、秘法符文、文明档案和多结局任务线。
- 机械专题已经改为 Ala Industrial 工业内容：锡矿与铜、铜缆、电子电路、发电机、电池箱、太阳能板、粉碎机、合金炉、风力发电和设备摆放目标。
- Spellgems 任务线介绍 Mana Root、Mana Essence、Mana Infuser 的实际玩法；对未核实的 Spellgems 注册 ID 不用猜测值。
- Global Packs 自动加载配置、JustQuests 配置、Modrinth API 本地构建脚本与 PCL 部署说明。

## 当前工程的边界（请务必看）
这不是已通过客户端验收的稳定发行版。当前压缩包**不包含第三方模组 JAR**，原因是制作环境无法直接连接 Modrinth 下载文件，也不能启动 Minecraft 客户端。工程内的 Windows 构建脚本会在你的电脑联网后下载 26.3 Fabric 兼容模组、解析必需依赖并校验 SHA-512/SHA-1，再生成包含真实 JAR 的完整文件包。

小岛种子和坐标也尚未在本整合包的全部模组组合下实测。种子 `3404544535694295634` 是候选起点，不会假装为已验证的专属岛屿地图。若可选 Terralith 改变出生位置，先关闭该数据包验收原版地形；如仍不满足要求，再制作专用起始岛方案。

## 使用步骤：先构建本地完整文件包
1. 在联网的 Windows 电脑上解压整个 ZIP。
2. 双击 `Build_PCL整合包.bat`。脚本将调用 Modrinth API 查询 Minecraft 26.3 + Fabric 版本，下载必需模组和必需依赖，验证文件哈希。
3. 若必需模组/依赖缺失或哈希校验失败，脚本会停止，不会输出伪完整包。
4. 成功后在 `release/` 生成 `.mrpack` 与 `AeonArk-26.3-Fabric-v0.2.0-alpha.3-FullFiles.zip`。

## PCL / PCL2 安装（尤其适用于 PCL2 2.99.x）
PCL2 2.99.x 不再替你下载 Minecraft 本体和模组。因此请采用**本地完整文件包**方式：
1. 先用正版 Minecraft 官方启动器准备好 Minecraft Java 26.3 本地游戏文件。
2. 为 26.3 安装 Fabric Loader 0.20.1，使用 Java 25 x64。
3. 在 PCL 中启动一次这个 Fabric 版本到主菜单，然后退出。
4. 解压 `release/AeonArk-26.3-Fabric-v0.2.0-alpha.3-FullFiles.zip`，将其中的 `mods/`、`config/`、`global_packs/` 合并复制到这个实例的游戏目录。
5. PCL 中为该实例分配约 5GB 内存，先关闭光影。
6. 创建**新世界**，选择生存、标准难度；使用候选种子 `3404544535694295634` 做首轮岛屿验收。
7. 进入游戏后按 **J** 尝试打开 JustQuests。若任务未出现，先 `/reload`，再查看 `logs/latest.log` 中 Global Packs、datapack、JustQuests 的报错。

旧版 PCL 或支持远程依赖下载的兼容启动器可以尝试导入 `.mrpack`，但本项目优先推荐最新 PCL 的本地文件包安装方式。

## V0.2.0-alpha.3 修复
- 为本地完整文件 ZIP 增加构建后完整性检查；模组 JAR 会由下载器写入 `.build_full_zip/mods/`，构建结束后会再次检查 ZIP 中的 JAR 数量。
- 新增 `scripts/validate_quests.py`，可离线检查所有任务文件、目标/奖励字段、前置关系与 26.3 数据包元信息。
- `enable_system_global_packs = false` 是故意的实例隔离设置；必需任务包目录由 `[datapacks].required` 指向 `global_packs/required_data/`。Terralith 与 Dungeons & Taverns 当前放入 `global_packs/optional_data/`，不默认强制启用。

## 本版质量检查
- 72 个任务 JSON 均可解析，并可由 `python scripts/validate_quests.py` 静态检查。
- 所有任务前置 ID 均有对应任务文件；本地检查缺失前置为 0。
- 机械任务所用 Ala Industrial 注册 ID 已对照模组 Wiki 核验；具体合成配方与机器行为仍需客户端确认。
- 数据包文件结构与 ZIP 完整性已经本地检查。
- 尚未完成：真实客户端启动、任务内运行、岛屿出生验收、长时间性能与崩溃测试。

## 下一期工作
1. 收集你运行构建脚本的结果和 `logs/latest.log`，修正真实启动错误。
2. 验收并锁定真正的小岛出生；如不满足需求，制作专用起始岛地图。
3. 在游戏里逐项验证工业、魔法、农业和探索任务是否正确计数。
4. 从 72 条扩充到 360 条目标，并制作更多原创文物、隐藏结构与多结局奖励。