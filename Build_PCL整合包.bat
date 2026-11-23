@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 方舟纪元：失落的世界 - Minecraft 26.3 Fabric 构建器
echo 将生成 PCL 可直接导入的单个 ZIP，所有实际模组 JAR 将下载并校验后直接打入 ZIP。
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
