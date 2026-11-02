# Makes one Windows release, laid out as TRG Launcher 2.0's two GitHub releases serve it (as the Whopping
# collection does, trg-launcher launcher2/examples/whopping/tools/make_release.ps1).
#
#   powershell -ExecutionPolicy Bypass -File tools\make_release.ps1 -Version 0.0.1
#   powershell -ExecutionPolicy Bypass -File tools\make_release.ps1 -Version 0.0.2 -Earlier 0.0.1
#
# Build first: tools\build_game.bat (release) and tools\build_launcher.bat, both with this version.
# Writes dist\v<Version>\:
#   IncredibleHulk-v<Version>-windows-x64.zip   for players (tag v<Version>): the portable launcher with the game's
#                                               program in games\incredible_hulk; the disc is installed from it
#   packages\                                   the packages release (tag packages-v<Version>), what the launcher
#                                               downloads: its own update zip and the game's, with SHA256SUMS.txt
# and release-maps\v<Version>\ (the link map and the exact programs, never published).
# Each zip holds update-files.txt (trg-launcher tools/make_update_files.py), so an update replaces exactly the
# release's files and never the protected ones (disc files, settings, saves, logs).
param(
  [Parameter(Mandatory)][string]$Version,
  [string]$Earlier = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$python = (Get-Command python.exe -ErrorAction SilentlyContinue).Source
if (-not $python) { $python = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe" }
$tool = Join-Path $root 'third_party\trg-launcher\tools\make_update_files.py'
$game = Join-Path $root 'out\build\win-amd64-release'
$launcher = Join-Path $root 'out\launcher\hulk_launcher.exe'
$vs = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationPath
$crt = Get-ChildItem "$vs\VC\Redist\MSVC\*\x64\Microsoft.VC143.CRT" -Directory | Sort-Object FullName | Select-Object -Last 1
$crtFiles = 'msvcp140.dll', 'msvcp140_atomic_wait.dll', 'vcruntime140.dll', 'vcruntime140_1.dll'

# The programs must be this version's release builds, with no developer aids.
foreach ($exe in (Join-Path $game 'incredible_hulk.exe'), $launcher) {
  if (-not (Test-Path $exe)) { throw "$exe is missing: build it first" }
  $v = (Get-Item $exe).VersionInfo.FileVersion
  if ($v -ne $Version) { throw "$exe is version '$v', not $Version" }
}
$text = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes((Join-Path $game 'incredible_hulk.exe')))
if ([regex]::Matches($text, 'HULK_DEV_PAD|HULK_DUMP_IMAGE').Count) { throw 'incredible_hulk.exe is a developer build' }

$top = Join-Path $root "dist\v$Version"
if (Test-Path $top) { throw "$top already exists" }
$tag = Join-Path $top 'packages'
$stageRoot = Join-Path $top 'stage'
New-Item -ItemType Directory -Force $tag, $stageRoot | Out-Null
$notices = Join-Path $stageRoot 'THIRD-PARTY-NOTICES.txt'
& $python (Join-Path $root 'tools\make_notices.py') $notices
if ($LASTEXITCODE -ne 0) { throw 'the notices could not be made' }

$parts = @(
  @{ Folder = 'IncredibleHulk'; Files = @($launcher); Protect = @('games', 'save-backups', 'cache', 'hulk.txt', 'test-userdata') },
  @{ Folder = 'IncredibleHulkGame'; Id = 'incredible_hulk';
     Files = @((Join-Path $game 'incredible_hulk.exe'), (Join-Path $game 'rexruntime.dll'), (Join-Path $game 'rexgpu-xenos.dll')) +
             ($crtFiles | ForEach-Object { Join-Path $crt.FullName $_ });
     Protect = @('game', 'incredible_hulk.toml', 'logs', 'crash-report.txt') }
)
foreach ($p in $parts) {
  $stage = Join-Path $stageRoot $p.Folder
  New-Item -ItemType Directory -Force $stage | Out-Null
  Copy-Item $p.Files $stage
  Copy-Item (Join-Path $root 'LICENSE') (Join-Path $stage 'LICENSE.txt')
  Copy-Item $notices $stage
  if (-not $p.Id) { Copy-Item (Join-Path $root 'release\README.txt') $stage }
  $zip = Join-Path $tag "$($p.Folder)-v$Version-windows-x64.zip"
  $pyArgs = @($tool, 'package', $stage, '--version', $Version, '--zip', $zip, '--asset', "$($p.Folder)-*-windows-x64.zip")
  foreach ($x in $p.Protect) { $pyArgs += @('--protect', $x) }
  if ($Earlier) { $pyArgs += @('--earlier', (Join-Path $root "dist\v$Earlier\packages\$($p.Folder)-v$Earlier-windows-x64.zip")) }
  $log = & $python @pyArgs 2>&1
  if ($LASTEXITCODE -ne 0) { $log | Select-Object -Last 10; throw "packaging $($p.Folder) failed" }
  "{0,-48} {1,6:N1} MB" -f (Split-Path -Leaf $zip), ((Get-Item $zip).Length / 1MB)
}

# The players' zip: the launcher's zip with the game's zip unpacked into games\incredible_hulk, as the launcher's
# own download would put it there (its update list included).
$players = Join-Path $stageRoot 'players'
Expand-Archive (Join-Path $tag "IncredibleHulk-v$Version-windows-x64.zip") $players
$unpack = Join-Path $stageRoot 'unpack-game'
Expand-Archive (Join-Path $tag "IncredibleHulkGame-v$Version-windows-x64.zip") $unpack
$dest = Join-Path $players 'IncredibleHulk\games\incredible_hulk'
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item (Join-Path $unpack 'IncredibleHulkGame\*') $dest -Recurse
$playersZip = Join-Path $top "IncredibleHulk-v$Version-windows-x64.zip"
& "$env:WINDIR\System32\tar.exe" -a -c -f $playersZip -C $players IncredibleHulk
if ($LASTEXITCODE -ne 0) { throw 'the players zip could not be made' }
"{0,-48} {1,6:N1} MB  (players: the launcher and the game)" -f (Split-Path -Leaf $playersZip), ((Get-Item $playersZip).Length / 1MB)

$sums = Get-ChildItem $tag -Filter '*.zip' | Sort-Object Name | ForEach-Object {
  "$((Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower())  $($_.Name)"
}
[IO.File]::WriteAllText((Join-Path $tag 'SHA256SUMS.txt'), (($sums -join "`r`n") + "`r`n"))
[IO.File]::WriteAllText((Join-Path $top 'SHA256SUMS.txt'),
  "$((Get-FileHash $playersZip -Algorithm SHA256).Hash.ToLower())  $(Split-Path -Leaf $playersZip)`r`n")

$maps = Join-Path $root "release-maps\v$Version"
New-Item -ItemType Directory -Force $maps | Out-Null
Copy-Item (Join-Path $game 'incredible_hulk.map'), (Join-Path $game 'incredible_hulk.exe'), (Join-Path $game 'rexruntime.dll'),
  (Join-Path $game 'rexgpu-xenos.dll'), $launcher $maps
"Release map and programs kept in $maps"
"Next: VirusTotal for every zip, and a start from the unzipped players zip, before anything is published."
