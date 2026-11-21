$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object Windows.Forms.Form
$form.Text = 'Aeon Ark — The Lost Frontier'
$form.Size = New-Object Drawing.Size(640,480)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object Drawing.Size(640,480)
$title = New-Object Windows.Forms.Label
$title.Text = 'AEON ARK  |  THE LOST FRONTIER'
$title.Font = New-Object Drawing.Font('Segoe UI',18,[Drawing.FontStyle]::Bold)
$title.Location = New-Object Drawing.Point(24,20)
$title.Size = New-Object Drawing.Size(570,42)
$form.Controls.Add($title)
$desc = New-Object Windows.Forms.Label
$desc.Text = 'Minecraft Java 26.3 · Fabric · Java 25 x64'
$desc.Location = New-Object Drawing.Point(28,68)
$desc.Size = New-Object Drawing.Size(560,24)
$form.Controls.Add($desc)
$status = New-Object Windows.Forms.TextBox
$status.Multiline = $true
$status.ReadOnly = $true
$status.ScrollBars = 'Vertical'
$status.Location = New-Object Drawing.Point(28,110)
$status.Size = New-Object Drawing.Size(568,190)
$status.Text = 'Welcome!' + [Environment]::NewLine + '1. Build/download verified mod files.' + [Environment]::NewLine + '2. Select your Fabric 26.3 instance folder and install.' + [Environment]::NewLine + '3. Open PCL and launch the instance.' + [Environment]::NewLine + 'This preview does not install Minecraft or Fabric automatically. Back up worlds before changing an instance.'
$form.Controls.Add($status)
function Log([string]$Message) { $status.AppendText([Environment]::NewLine + "[$(Get-Date -Format HH:mm:ss)] $Message"); [Windows.Forms.Application]::DoEvents() }
$build = New-Object Windows.Forms.Button
$build.Text = '1. Build / Download Pack'
$build.Location = New-Object Drawing.Point(28,325)
$build.Size = New-Object Drawing.Size(178,42)
$form.Controls.Add($build)
$install = New-Object Windows.Forms.Button
$install.Text = '2. Install to Instance'
$install.Location = New-Object Drawing.Point(224,325)
$install.Size = New-Object Drawing.Size(178,42)
$form.Controls.Add($install)
$open = New-Object Windows.Forms.Button
$open.Text = '3. Open PCL'
$open.Location = New-Object Drawing.Point(420,325)
$open.Size = New-Object Drawing.Size(176,42)
$form.Controls.Add($open)
$build.Add_Click({
 try {
  $build.Enabled = $false
  Log 'Starting verified Modrinth download and pack build. A console window will open.'
  $p = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c','Build_PCL整合包.bat') -WorkingDirectory $Root -Wait -PassThru
  if ($p.ExitCode -ne 0) { throw "Build failed (exit code $($p.ExitCode)). Read the build console output." }
  Log 'Build finished. Verified mods and configs are ready.'
 } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Aeon Ark') | Out-Null; Log "ERROR: $($_.Exception.Message)" }
 finally { $build.Enabled = $true }
})
$install.Add_Click({
 try {
  $source = Join-Path $Root '.build_full_zip'
  if (-not (Test-Path (Join-Path $source 'mods'))) { [Windows.Forms.MessageBox]::Show('Please run Build / Download Pack first.','Aeon Ark') | Out-Null; return }
  $dialog = New-Object Windows.Forms.FolderBrowserDialog
  $dialog.Description = 'Select the game directory of your Minecraft 26.3 Fabric instance'
  if ($dialog.ShowDialog() -ne 'OK') { return }
  $target = $dialog.SelectedPath
  foreach ($folder in @('mods','config','global_packs')) {
   $from = Join-Path $source $folder
   if (Test-Path $from) { $to = Join-Path $target $folder; New-Item -ItemType Directory -Force -Path $to | Out-Null; Copy-Item (Join-Path $from '*') $to -Recurse -Force }
  }
  Log "Installed mods/config/global_packs into: $target"
  Log 'No worlds or saves were copied or deleted. Launch the matching Fabric 26.3 profile in PCL.'
 } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Aeon Ark') | Out-Null; Log "ERROR: $($_.Exception.Message)" }
})
$open.Add_Click({
 $candidates = @("$env:APPDATA\PCL\Plain Craft Launcher 2.exe","$env:APPDATA\PCL2\PCL2.exe","$env:LOCALAPPDATA\Programs\PCL2\PCL2.exe")
 $pcl = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
 if ($pcl) { Start-Process $pcl; Log "Opened PCL: $pcl" }
 else { $dialog = New-Object Windows.Forms.OpenFileDialog; $dialog.Title = 'Locate your PCL / PCL2 executable'; $dialog.Filter = 'Executable (*.exe)|*.exe'; if ($dialog.ShowDialog() -eq 'OK') { Start-Process $dialog.FileName; Log "Opened: $($dialog.FileName)" } }
})
$footer = New-Object Windows.Forms.Label
$footer.Text = 'Preview launcher · Requires Windows 10/11, internet for first build, Java 25 x64, and Fabric 26.3.'
$footer.Location = New-Object Drawing.Point(28,390)
$footer.Size = New-Object Drawing.Size(568,32)
$footer.ForeColor = [Drawing.Color]::DimGray
$form.Controls.Add($footer)
[void]$form.ShowDialog()
