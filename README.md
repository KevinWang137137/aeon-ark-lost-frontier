# Aeon Ark: The Lost Frontier

**方舟纪元：失落的世界** — an original Minecraft Java adventure modpack project.

> Development snapshot: **v0.2.0-alpha.3** · Minecraft **26.3** · Fabric · Java 25
>
> **Status: engineering preview, not yet launch-tested.** This repository does not claim to be a ready-to-play release.

## Project direction

A vanilla-inspired survival and exploration pack that begins on a small, isolated island. Players gradually explore new biomes and ruins, establish farms and workshops, discover arcane tools, recover the lost Ark civilization's archives, and eventually choose among multiple endings.

Design priorities:

- Dreamcraft-style special island start; standard Survival difficulty.
- Chapter-based Chinese quest book, independent mod-focused quest lines, and converging story milestones.
- New biomes, creatures, structures, food, machines and magic while keeping the visual style close to vanilla.
- Few major boss encounters; exploration and collection are the main progression drivers.
- Target memory allocation around 5 GB, subject to real-world testing.

## Current baseline

| Component | Target |
|---|---|
| Minecraft Java | 26.3 (latest stable line verified for this snapshot) |
| Mod loader | Fabric Loader 0.20.1 |
| Fabric API | 0.166.2+26.3 |
| Java | 25 x64 |
| Launcher target | PCL / PCL2 local-instance installation |
| Current authored quests | 72 across 8 categories |
| Long-term quest target | 360+ |

## Download the source snapshot

[Open the v0.2.0-alpha.3 GitHub pre-release](https://github.com/KevinWang137137/aeon-ark-lost-frontier/releases/tag/v0.2.0-alpha.3) and download **AeonArk-0.2.0-alpha.3-Source.zip**.

The bundle contains the authored quest data bundle, configuration, mod source list, Windows PowerShell build script, quest validator, and project notes. It **does not contain third-party mod JARs**. The build script resolves compatible files from Modrinth on a Windows machine and validates downloaded hashes. This is a source-only engineering preview, not a prebuilt playable pack.

## Local validation

Run from the extracted project directory:

```powershell
python scripts/validate_quests.py
```

This expands `quest-data/quests.json.gz.b64` when needed, then checks the quest JSON structure, supported objective/reward types and required fields, prerequisite references, and the 26.3 datapack metadata. It is a static check only; it does not prove that the game launches or that each objective registers in-game.

On Windows, run `Build_PCL整合包.bat`. The build first expands the tracked quest bundle using `scripts/expand_quest_bundle.ps1`, then to resolve/download the selected 26.3 Fabric mod files and build a local complete-files ZIP plus an `.mrpack` index. Use Java 25 x64 and test in a new PCL instance. The small-island seed is still a candidate and must be validated in-game.

## Current verification boundary

**Passed:** 72 quest files parse; 8 categories present; all quest prerequisites resolve; supported JustQuests fields pass static validation; archive integrity check passes.

**Not yet performed:** Windows download/build execution, full dependency-resolution run, PCL import, Minecraft client launch, world creation, island spawn verification, per-quest in-game objective checks, and 5 GB performance/stability testing.

See [`docs/技术核验记录.md`](docs/技术核验记录.md), [`docs/V0.2.0-alpha.3更新说明.md`](docs/V0.2.0-alpha.3更新说明.md), and [`CHANGELOG.md`](CHANGELOG.md).

---

# 中文说明

这是《方舟纪元：失落的世界》的正式开发仓库。当前是 **V0.2.0-alpha.3 工程预览版**，不是已通过客户端测试的可玩发行版。

本次源代码包有 72 条原创任务、8 个任务分类、任务前置链、模组清单、PCL 本地构建脚本与静态校验脚本。目标为 Minecraft Java 26.3 + Fabric + Java 25，Dreamcraft 式特殊小岛开局、标准生存难度。

本次会话附带的 source ZIP 解压后，请按 `README_先看这里.md` 操作。第三方模组 JAR 不随仓库重打包；Windows 构建脚本会从 Modrinth 官方项目记录下载并校验文件。启动、岛屿生成、任务实测和性能测试尚未完成。