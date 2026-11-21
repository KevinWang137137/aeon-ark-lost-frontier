@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 方舟纪元：失落的世界 - Minecraft 26.3 Fabric 构建器
echo 将通过 Modrinth 官方 API 解析模组版本、依赖并校验文件哈希。
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build_pack.ps1"
if errorlevel 1 (
  echo.
  echo 构建失败。请查看上方错误信息。
) else (
  echo.
  echo 构建完成。输出位于 release 文件夹。
)
echo.
pause
