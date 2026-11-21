$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BundlePath = Join-Path $Root 'quest-data/quests.json.gz.b64'
$QuestRoot = Join-Path $Root 'global_packs/required_data/arkfrontier_quests/data/arkfrontier/justquests/quests'
if ((Test-Path $QuestRoot) -and (Get-ChildItem $QuestRoot -Filter '*.json' -Recurse -File | Select-Object -First 1)) { exit 0 }
if (-not (Test-Path $BundlePath)) { throw "找不到任务数据包：$BundlePath" }
$Bytes = [Convert]::FromBase64String((Get-Content -Path $BundlePath -Raw).Trim())
$InputStream = [IO.MemoryStream]::new($Bytes)
$GzipStream = [IO.Compression.GZipStream]::new($InputStream, [IO.Compression.CompressionMode]::Decompress)
$Reader = [IO.StreamReader]::new($GzipStream, [Text.Encoding]::UTF8)
try { $Bundle = $Reader.ReadToEnd() | ConvertFrom-Json } finally { $Reader.Dispose(); $GzipStream.Dispose(); $InputStream.Dispose() }
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
foreach ($Entry in $Bundle.files) {
    $Target = Join-Path (Join-Path $Root 'global_packs') ([string]$Entry.path)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
    $Json = $Entry.content | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($Target, $Json + "`n", $Utf8NoBom)
}
Write-Host "已展开原创任务：$($Bundle.files.Count) 条" -ForegroundColor Green
