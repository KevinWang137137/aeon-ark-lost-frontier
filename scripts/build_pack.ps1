$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Api = 'https://api.modrinth.com/v2'
$Game = '26.3'
$Loader = 'fabric'
$LoaderVersion = '0.20.1'
$PackVersion = (Get-Content (Join-Path $Root '.github/release-version.txt') -Raw).Trim()
if ($PackVersion -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$') { throw "无效的发布版本号：$PackVersion" }
$Out = Join-Path $Root 'release'
$Stage = Join-Path $Root '.build_mrpack'
$Overrides = Join-Path $Stage 'overrides'
$ModNames = @{}
$IndexFiles = New-Object System.Collections.Generic.List[object]
$Resolved = @{}
$MetaCache = @{}
$Warnings = New-Object System.Collections.Generic.List[string]
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Get-Meta([string]$Project) {
    if ($MetaCache.ContainsKey($Project)) { return $MetaCache[$Project] }
    $Meta = Invoke-RestMethod "$Api/project/$Project" -TimeoutSec 45
    $MetaCache[$Project] = $Meta
    return $Meta
}
function Get-Version([string]$Project,[string[]]$Platforms) {
    $Games = [uri]::EscapeDataString('["' + $Game + '"]')
    $Loaders = [uri]::EscapeDataString('["' + ($Platforms -join '","') + '"]')
    $Versions = @(Invoke-RestMethod "$Api/project/$Project/version?game_versions=$Games&loaders=$Loaders" -TimeoutSec 45)
    if ($Versions.Count -eq 0) { return $null }
    return ($Versions | Sort-Object @{Expression={switch ($_.version_type) {'release'{0} 'beta'{1} 'alpha'{2} default{3}}}},@{Expression={$_.date_published};Descending=$true} | Select-Object -First 1)
}
function Get-File($Version,[string]$Extension) {
    $File = $Version.files | Where-Object { $_.primary -eq $true -and $_.filename.ToLower().EndsWith($Extension) } | Select-Object -First 1
    if ($null -eq $File) { $File = $Version.files | Where-Object { $_.filename.ToLower().EndsWith($Extension) } | Select-Object -First 1 }
    if ($null -eq $File) { throw "版本 $($Version.version_number) 没有 $Extension 文件" }
    return $File
}
function Download-Verified($File,[string]$Path) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    Invoke-WebRequest -Uri $File.url -OutFile $Path -TimeoutSec 180
    if ($File.hashes.sha512) {
        $Hash = (Get-FileHash $Path -Algorithm SHA512).Hash.ToLower()
        if ($Hash -ne $File.hashes.sha512.ToLower()) { throw "SHA-512 校验失败：$($File.filename)" }
    } elseif ($File.hashes.sha1) {
        $Hash = (Get-FileHash $Path -Algorithm SHA1).Hash.ToLower()
        if ($Hash -ne $File.hashes.sha1.ToLower()) { throw "SHA-1 校验失败：$($File.filename)" }
    } else { throw "Modrinth 未提供哈希：$($File.filename)" }
}
function Add-Version($Meta,$Version,[bool]$Optional = $false) {
    if ($Resolved.ContainsKey($Meta.id)) { return }
    if (-not ($Version.game_versions -contains $Game) -or -not ($Version.loaders -contains $Loader)) { throw "$($Meta.title) 的依赖版本不支持 $Game / $Loader" }
    $File = Get-File $Version '.jar'
    if ($ModNames.ContainsKey($File.filename)) { throw "不同项目出现同名 JAR：$($File.filename)" }
    $ModNames[$File.filename] = $true
    if (-not $File.hashes.sha1 -and -not $File.hashes.sha512) { throw "Modrinth 未提供可校验哈希：$($File.filename)" }
    if (-not $File.url -or [long]$File.size -le 0) { throw "Modrinth 文件信息不完整：$($File.filename)" }
    $DefaultEnv = if ($Optional) { 'optional' } else { 'required' }
    $Client = if ($Meta.client_side -eq 'unsupported') { 'unsupported' } elseif ($Optional) { 'optional' } elseif ($Meta.client_side) { $Meta.client_side } else { 'required' }
    $Server = if ($Meta.server_side -eq 'unsupported') { 'unsupported' } elseif ($Optional) { 'optional' } elseif ($Meta.server_side) { $Meta.server_side } else { 'required' }
    $IndexFiles.Add([ordered]@{path="mods/$($File.filename)";hashes=$File.hashes;env=@{client=$Client;server=$Server};downloads=@($File.url);fileSize=[long]$File.size})
    $Resolved[$Meta.id] = @{name=$Meta.title;version=$Version.version_number;filename=$File.filename;version_id=$Version.id}
    Write-Host "[MOD] $($Meta.title) -> $($Version.version_number)" -ForegroundColor Green
    foreach ($Dep in @($Version.dependencies)) {
        if ($Dep.dependency_type -ne 'required') { continue }
        if ($Dep.version_id) {
            $Exact = Invoke-RestMethod "$Api/version/$($Dep.version_id)" -TimeoutSec 45
            $DepMeta = Get-Meta ([string]$Exact.project_id)
            Add-Version $DepMeta $Exact
        } elseif ($Dep.project_id) { Add-Project ([string]$Dep.project_id) $true }
    }
}
function Add-Project([string]$Project,[bool]$Required) {
    try {
        $Meta = Get-Meta $Project
        if ($Resolved.ContainsKey($Meta.id)) { return }
        $Version = Get-Version $Meta.id @($Loader)
        if ($null -eq $Version) { throw "没有 $Game / $Loader 发布文件" }
        Add-Version $Meta $Version (-not $Required)
    } catch {
        if ($Required) { throw "必需模组/依赖 $Project 失败：$($_.Exception.Message)" }
        $Warnings.Add("可选模组 $Project 跳过：$($_.Exception.Message)")
        Write-Warning "可选模组 $Project 跳过：$($_.Exception.Message)"
    }
}
function Add-Datapack([string]$Project,[string]$Filename,[string]$Directory,[bool]$Required) {
    try {
        if ($Directory -notin @('required_data','optional_data')) { throw "非法数据包目录：$Directory" }
        $Version = Get-Version $Project @('datapack')
        if ($null -eq $Version) { throw "找不到 Minecraft $Game 数据包版本" }
        $File = Get-File $Version '.zip'
        # Store the verified datapack in source so both MRPACK and PCL ZIP include it.
        $Destination = Join-Path $Root "global_packs/$Directory/$Filename"
        Download-Verified $File $Destination
        $StageDestination = Join-Path $Overrides "global_packs/$Directory/$Filename"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $StageDestination) | Out-Null
        Copy-Item $Destination $StageDestination -Force
        Write-Host "[DATAPACK] $Project -> $($Version.version_number)" -ForegroundColor Green
    } catch {
        if ($Required) { throw "必需数据包 $Project 失败：$($_.Exception.Message)" }
        $Warnings.Add("可选数据包 $Project 跳过：$($_.Exception.Message)")
        Write-Warning "可选数据包 $Project 跳过：$($_.Exception.Message)"
    }
}

try {
    Write-Host "=== 方舟纪元：失落的世界 | Minecraft $Game / Fabric ===" -ForegroundColor Cyan
    & (Join-Path $Root 'scripts/expand_quest_bundle.ps1')
    if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
    if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $Overrides,$Out | Out-Null
    Copy-Item (Join-Path $Root 'config') (Join-Path $Overrides 'config') -Recurse -Force
    Copy-Item (Join-Path $Root 'global_packs') (Join-Path $Overrides 'global_packs') -Recurse -Force
    $Manifest = Get-Content (Join-Path $Root 'modpack_sources.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($Mod in $Manifest.required_mods) { Add-Project ([string]$Mod.project) $true }
    foreach ($Mod in $Manifest.optional_mods) { Add-Project ([string]$Mod.project) $false }
    foreach ($Pack in $Manifest.datapack_projects) {
        $Dir = if ($Pack.directory) { [string]$Pack.directory } else { 'optional_data' }
        $Required = if ($null -ne $Pack.required) { [bool]$Pack.required } else { $false }
        Add-Datapack ([string]$Pack.project) ([string]$Pack.filename) $Dir $Required
    }
    $Index = [ordered]@{formatVersion=1;game='minecraft';versionId=$PackVersion;name='方舟纪元：失落的世界';summary='Minecraft 26.3 Fabric · 标准生存 · 小岛开局 · 中文任务冒险';files=@($IndexFiles);dependencies=@{minecraft=$Game;'fabric-loader'=$LoaderVersion}}
    [IO.File]::WriteAllText((Join-Path $Stage 'modrinth.index.json'),($Index | ConvertTo-Json -Depth 30),$Utf8)
    $Report = [ordered]@{minecraft=$Game;loader=$Loader;loader_version=$LoaderVersion;resolved=$Resolved;warnings=@($Warnings)}
    [IO.File]::WriteAllText((Join-Path $Overrides 'aeon-ark-mod-resolution-report.json'),($Report | ConvertTo-Json -Depth 30),$Utf8)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $PackZip = Join-Path $Out "AeonArk-26.3-Fabric-v$PackVersion.zip"
    if (Test-Path $PackZip) { Remove-Item $PackZip -Force }
    # PCL recognises a Modrinth pack ZIP when modrinth.index.json is at archive root.
    [IO.Compression.ZipFile]::CreateFromDirectory($Stage,$PackZip,[IO.Compression.CompressionLevel]::Optimal,$false)
    $Check = [IO.Compression.ZipFile]::OpenRead($PackZip)
    try {
        if ($null -eq $Check.GetEntry('modrinth.index.json')) { throw 'ZIP 根目录缺少 modrinth.index.json，PCL 无法按 Modrinth 整合包识别' }
        if (@($Check.Entries | Where-Object {$_.FullName -like 'overrides/config/*'}).Count -eq 0) { throw 'ZIP 中缺少 overrides/config 配置文件' }
        $IndexEntry = $Check.GetEntry('modrinth.index.json')
        $Reader = New-Object IO.StreamReader($IndexEntry.Open())
        try { $ZipIndex = $Reader.ReadToEnd() | ConvertFrom-Json } finally { $Reader.Dispose() }
        if ($ZipIndex.formatVersion -ne 1 -or $ZipIndex.game -ne 'minecraft') { throw 'Modrinth index 格式检查失败' }
        if ($ZipIndex.dependencies.minecraft -ne $Game) { throw '清单中的 Minecraft 版本与构建版本不一致' }
        if (@($ZipIndex.files).Count -eq 0) { throw '清单中没有任何可下载模组' }
        Write-Host "PCL ZIP 验证通过：$(@($ZipIndex.files).Count) 个模组条目，$(@($Check.Entries).Count) 个压缩条目" -ForegroundColor Green
    } finally { $Check.Dispose() }
    Write-Host "构建完成：$PackZip" -ForegroundColor Green
    Write-Host "必需与自动依赖模组：$($IndexFiles.Count)；可选跳过：$($Warnings.Count)" -ForegroundColor Green
    Write-Host '将此 ZIP 直接拖入 PCL 导入；首次安装需要联网下载 Minecraft、Fabric 和模组。建议 Java 25 x64，内存先设为 5GB。' -ForegroundColor Yellow
} catch {
    Write-Host "构建失败：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
}
