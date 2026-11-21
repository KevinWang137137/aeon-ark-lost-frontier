# 更新日志

## 0.2.0-alpha.3
- 新增 JustQuests 离线静态校验脚本和校验报告。
- 为本地完整文件 ZIP 增加构建后检查，确认压缩包的 mods/ 下有真实 JAR。
- 确认 Global Packs 使用实例级 global_packs/required_data/；enable_system_global_packs=false 是预期的实例隔离设置。
- 版本基线：Minecraft Java 26.3、Fabric Loader 0.20.1、Fabric API 0.166.2+26.3、Java 25 x64。
- 明确本版未完成 Windows 构建、PCL 导入和客户端启动验收。

## 0.2.0-alpha.2
- 建立 72 条原创 JustQuests 任务数据，分为 8 个分类。
- 加入 Modrinth 版本解析、文件哈希校验与 PCL 本地构建脚本。
