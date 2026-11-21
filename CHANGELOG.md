# 更新日志

## 0.2.0-alpha.3
- 新增 JustQuests 离线静态校验脚本；首次运行可从压缩任务源展开 72 条任务。
- 为本地完整文件 ZIP 增加构建后检查，确认 mods/ 下有真实 JAR。
- 纠正 Biomes O' Plenty Modrinth 条目的类型，移除错误的必装 JAR 依赖。
- 加入 Terralith 2.6.5+26.3 与 Dungeons & Taverns 候选数据包，并放入 optional_data，不默认改动出生岛。
- 明确 Global Packs 使用实例内 global_packs/required_data/；enable_system_global_packs=false 是预期设置。
- 本版尚未完成 Windows 构建、PCL 导入、客户端启动和性能验收。

## 0.2.0-alpha.2
- 建立 72 条原创 JustQuests 任务数据，分成 8 个任务分类。
- 加入 Modrinth 版本解析、SHA 校验和 PCL 本地构建脚本。
