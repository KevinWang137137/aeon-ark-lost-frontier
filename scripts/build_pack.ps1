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
$Stage = Join-Path $Root '.build_full_pack'
$GameRoot = Join-Path $Stage '.minecraft'
$ModsDir = Join-Path $GameRoot 'mods'
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
    Download-Verified $File (Join-Path $ModsDir $File.filename)
    $IndexFiles.Add([ordered]@{filename=$File.filename;version=$Version.version_number;project=$Meta.id;sha1=$File.hashes.sha1;sha512=$File.hashes.sha512;size=[long]$File.size})
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
        $StageDestination = Join-Path $GameRoot "global_packs/$Directory/$Filename"
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
    New-Item -ItemType Directory -Force -Path $ModsDir,$Out | Out-Null
    if (Test-Path (Join-Path $Root 'config')) { Copy-Item (Join-Path $Root 'config') (Join-Path $GameRoot 'config') -Recurse -Force }
    if (Test-Path (Join-Path $Root 'global_packs')) { Copy-Item (Join-Path $Root 'global_packs') (Join-Path $GameRoot 'global_packs') -Recurse -Force }
    foreach ($Folder in @('resourcepacks','shaderpacks','defaultconfigs','kubejs','scripts')) {
        $Source = Join-Path $Root $Folder
        if (Test-Path $Source) { Copy-Item $Source (Join-Path $GameRoot $Folder) -Recurse -Force }
    }
    $Manifest = Get-Content (Join-Path $Root 'modpack_sources.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($Mod in $Manifest.required_mods) { Add-Project ([string]$Mod.project) $true }
    foreach ($Mod in $Manifest.optional_mods) { Add-Project ([string]$Mod.project) $false }
    foreach ($Pack in $Manifest.datapack_projects) {
        $Dir = if ($Pack.directory) { [string]$Pack.directory } else { 'optional_data' }
        $Required = if ($null -ne $Pack.required) { [bool]$Pack.required } else { $false }
        Add-Datapack ([string]$Pack.project) ([string]$Pack.filename) $Dir $Required
    }
    $Components = @(
        [ordered]@{uid='net.minecraft';version=$Game;important=$true},
        [ordered]@{uid='net.fabricmc.fabric-loader';version=$LoaderVersion;important=$true}
    )
    $MmcPack = [ordered]@{components=$Components;formatVersion=1}
    [IO.File]::WriteAllText((Join-Path $Stage 'mmc-pack.json'),($MmcPack | ConvertTo-Json -Depth 10),$Utf8)
    [IO.File]::WriteAllText((Join-Path $Stage 'instance.cfg'),"InstanceType=OneSix`r`nname=Aeon Ark - The Lost Frontier`r`n",$Utf8)
    $Report = [ordered]@{minecraft=$Game;loader=$Loader;loader_version=$LoaderVersion;resolved=$Resolved;warnings=$Warnings.ToArray()}
    [IO.File]::WriteAllText((Join-Path $GameRoot 'aeon-ark-mod-resolution-report.json'),($Report | ConvertTo-Json -Depth 30),$Utf8)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $MinimumMods = 150
    if ($IndexFiles.Count -lt $MinimumMods) { throw "实际解析到 $($IndexFiles.Count) 个模组 JAR，未达到正式版最低要求 $MinimumMods；拒绝生成不达标 ZIP。" }
    $PackZip = Join-Path $Out "AeonArk-26.3-Fabric-v$PackVersion.zip"
    if (Test-Path $PackZip) { Remove-Item $PackZip -Force }
    # PCL recognises this as an MMC instance ZIP; actual mod JARs are bundled under .minecraft/mods.
    [IO.Compression.ZipFile]::CreateFromDirectory($Stage,$PackZip,[IO.Compression.CompressionLevel]::Optimal,$false)
    $Check = [IO.Compression.ZipFile]::OpenRead($PackZip)
    try {
        if ($null -eq $Check.GetEntry('mmc-pack.json') -or $null -eq $Check.GetEntry('instance.cfg')) { throw 'ZIP 根目录缺少 PCL 可识别的 MMC 整合包文件' }
        $ModEntries = @($Check.Entries | Where-Object { $_.FullName -match '^\.minecraft/mods/[^/]+\.jar$' })
        if ($ModEntries.Count -ne $IndexFiles.Count) { throw "模组打包数量不一致：ZIP=$($ModEntries.Count)，解析=$($IndexFiles.Count)" }
        if ($ModEntries.Count -lt 150) { throw "ZIP 实际只有 $($ModEntries.Count) 个模组 JAR，少于正式版最低要求 150 个" }
        if ($ModEntries.Count -eq 0) { throw 'ZIP 中没有实际模组 JAR 文件' }
        if (@($Check.Entries | Where-Object { $_.FullName -like '.minecraft/config/*' }).Count -eq 0) { throw 'ZIP 中缺少 .minecraft/config 配置文件' }
        Write-Host "PCL 完整包验证通过：$($ModEntries.Count) 个实际模组 JAR 已装入 ZIP，$(@($Check.Entries).Count) 个压缩条目" -ForegroundColor Green
    } finally {
        $Check.Dispose()
    }
    Write-Host "构建完成：$PackZip" -ForegroundColor Green
    Write-Host "必需与自动依赖模组：$($IndexFiles.Count)；可选跳过：$($Warnings.Count)" -ForegroundColor Green
    Write-Host '将此 ZIP 直接拖入 PCL 导入；首次安装需要联网下载 Minecraft、Fabric 和运行库。建议 Java 25 x64，内存先设为 5GB。' -ForegroundColor Yellow
} catch {
    Write-Host "构建失败：$($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkYellow
    exit 1
} finally {
    if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
}
