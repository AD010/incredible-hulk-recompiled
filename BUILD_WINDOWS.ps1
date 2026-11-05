# Build Hulk Native PC from sources on Windows. Does NOT enable Vulkan drawing.
# Usage: BUILD_WINDOWS.cmd -GameRoot "E:\Games\IncredibleHulk\games\incredible_hulk\game"
param(
  [string]$GameRoot = "",
  [switch]$NativeXLink,
  [switch]$Pm4Probe,
  [switch]$InputProbe
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Source = $PSScriptRoot
$BuildLog = Join-Path $Source 'HULK_BUILD_LOG.txt'
try { Start-Transcript -Path $BuildLog -Force | Out-Null } catch { Write-Warning 'Could not start build transcript' }
function Require-Command([string]$name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Missing tool '$name'. Install Visual Studio C++, CMake, Ninja, Git and Python 3."
  }
}
function Invoke-Checked([string]$exe, [string[]]$arguments, [string]$dir) {
  Push-Location -LiteralPath $dir
  try {
    Write-Host ("RUN: " + $exe + " " + ($arguments -join ' '))
    & $exe @arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed ($LASTEXITCODE): $exe" }
  } finally { Pop-Location }
}
try {
  foreach ($cmd in @('git', 'cmake', 'ninja', 'clang++', 'python')) { Require-Command $cmd }
  if (-not $GameRoot) {
    $known = 'E:\Games\IncredibleHulk\games\incredible_hulk\game'
    if (Test-Path (Join-Path $known 'default.xex')) { $GameRoot = $known }
    elseif (Test-Path (Join-Path $Source 'game\default.xex')) { $GameRoot = Join-Path $Source 'game' }
    else { $GameRoot = Read-Host 'Full path to installed game folder containing default.xex' }
  }
  $GameRoot = (Resolve-Path -LiteralPath $GameRoot).Path
  $Xex = Join-Path $GameRoot 'default.xex'
  if (-not (Test-Path -LiteralPath $Xex)) { throw "default.xex not found in '$GameRoot'" }
  Write-Host "Game data: $GameRoot"

  $LocalGame = Join-Path $Source 'game'
  New-Item -ItemType Directory -Force -Path $LocalGame | Out-Null
  $LocalXex = Join-Path $LocalGame 'default.xex'
  if ($LocalXex -ne $Xex) { Copy-Item -LiteralPath $Xex -Destination $LocalXex -Force }
  # The game data can stay at its installed path. Codegen only needs default.xex.

  $Sdk = Join-Path $Source 'sdk-src'
  if (-not (Test-Path (Join-Path $Sdk 'CMakeLists.txt'))) {
    Invoke-Checked 'git' @('clone', '--branch', 'recomp', '--depth', '1', '--recurse-submodules',
      'https://github.com/ElGuslml/rexglue-sdk.git', $Sdk) $Source
  } else {
    Write-Host 'Using existing sdk-src (no automatic upgrade).'
    Invoke-Checked 'git' @('-C', $Sdk, 'submodule', 'update', '--init', '--recursive') $Source
  }
  # The SDK carries a couple of symlinks which Git on Windows may check out as text files.
  Invoke-Checked 'python' @((Join-Path $Source 'tools\fix_symlinks.py'), $Sdk) $Source
  Invoke-Checked 'cmake' @('--preset', 'win-amd64') $Sdk
  Invoke-Checked 'cmake' @('--build', 'out/build/win-amd64', '--config', 'Release', '--target', 'install', '--parallel') $Sdk
  $SdkInstall = Join-Path $Sdk 'out\install\win-amd64'
  $Codegen = Join-Path $SdkInstall 'bin\rexglue.exe'
  if (-not (Test-Path $Codegen)) { throw "SDK install did not produce $Codegen" }
  Invoke-Checked $Codegen @('codegen', (Join-Path $Source 'incredible_hulk_manifest.toml')) $Source
  if (-not (Test-Path (Join-Path $Source 'generated\default\sources.cmake'))) {
    throw 'Codegen did not produce generated/default/sources.cmake; aborting before CMake configure.'
  }
  # Compile and run standalone input tests before the larger game build.
  $TestDir = Join-Path $Source 'out\input-tests'
  Invoke-Checked 'cmake' @('-S', (Join-Path $Source 'tests'), '-B', $TestDir, '-G', 'Ninja',
    '-DCMAKE_CXX_COMPILER=clang++', '-DCMAKE_BUILD_TYPE=Release') $Source
  Invoke-Checked 'cmake' @('--build', $TestDir, '--parallel') $Source
  Invoke-Checked 'ctest' @('--test-dir', $TestDir, '--output-on-failure') $Source

  $BuildDir = Join-Path $Source 'out\build\win-amd64-release'
  $cmakeArgs = @('--preset', 'win-amd64-release', '-DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF')
  # Explicit read-only debug instrumentation (OFF by default).
  if ($Pm4Probe) { $cmakeArgs += '-DHULK_XDK_PM4_PROBE=ON' }
  else { $cmakeArgs += '-DHULK_XDK_PM4_PROBE=OFF' }
  if ($InputProbe) { $cmakeArgs += '-DHULK_GAME_INPUT_PROBE=ON' }
  else { $cmakeArgs += '-DHULK_GAME_INPUT_PROBE=OFF' }
  if ($NativeXLink) {
    # Linking does NOT enable Vulkan. No unverified XDK hooks are activated.
    $NxrFull = Join-Path $Source 'native_x_renderer_git'
    if (-not (Test-Path (Join-Path $NxrFull 'thirdparty\diligent-core\CMakeLists.txt'))) {
      if (Test-Path $NxrFull) { throw "Incomplete renderer directory: $NxrFull (delete it to retry)" }
      Invoke-Checked 'git' @('clone', '--depth', '1', '--recurse-submodules',
        'https://github.com/ElGuslml/NativeXRenderer.git', $NxrFull) $Source
    }
    $cmakeArgs += @("-DREXSDK_DIR=$Sdk", '-DHULK_WITH_NATIVE_X=ON',
      "-DHULK_NATIVE_X_SOURCE_DIR=$NxrFull")
  } else {
    $cmakeArgs += @("-DCMAKE_PREFIX_PATH=$SdkInstall", '-DHULK_WITH_NATIVE_X=OFF')
  }
  Invoke-Checked 'cmake' $cmakeArgs $Source
  Invoke-Checked 'cmake' @('--build', $BuildDir, '--parallel') $Source
  $exe = Join-Path $BuildDir 'incredible_hulk.exe'
  if (-not (Test-Path $exe)) { throw "Build exited without producing $exe" }
  $Deliver = Join-Path $Source 'out\HULK_NATIVE_PC_TEST'
  if (Test-Path $Deliver) { Remove-Item -LiteralPath $Deliver -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $Deliver | Out-Null
  Copy-Item $exe $Deliver -Force
  foreach ($dll in @('rexruntime.dll','rexgpu-xenos.dll')) {
    $candidates = @((Join-Path $BuildDir $dll), (Join-Path $SdkInstall "bin\$dll"))
    $found = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $found) { throw "Missing runtime DLL: $dll; check SDK installation" }
    Copy-Item $found $Deliver -Force
  }
  # NativeX / SDK may copy additional DLL dependencies next to the built executable.
  Get-ChildItem -LiteralPath $BuildDir -Filter '*.dll' -File -ErrorAction SilentlyContinue |
    ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $Deliver -Force }
  $save = Join-Path $env:LOCALAPPDATA 'HulkNativePC\Saves'
  $gameEscaped = $GameRoot.Replace("'", "''")
  $run = @'
$ErrorActionPreference = 'Stop'
$exe = Join-Path $PSScriptRoot 'incredible_hulk.exe'
$game = '__GAMEROOT__'
$user = Join-Path $env:LOCALAPPDATA 'HulkNativePC\Saves'
New-Item -ItemType Directory -Force -Path $user | Out-Null
& $exe "--game_data_root=$game" "--user_data_root=$user" '--mnk_mode=false' '--hulk_native_mnk=true'
'@
  $run = $run.Replace('__GAMEROOT__', $gameEscaped)
  Set-Content -LiteralPath (Join-Path $Deliver 'RUN_HULK_NATIVE.ps1') -Value $run -Encoding UTF8
  $cmd = '@echo off' + "`r`n" + 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RUN_HULK_NATIVE.ps1"' + "`r`n" + 'pause' + "`r`n"
  [IO.File]::WriteAllText((Join-Path $Deliver 'RUN_HULK_NATIVE.cmd'), $cmd, [Text.Encoding]::ASCII)
  Write-Host "SUCCESS: $Deliver"
  if ($NativeXLink) { Write-Host 'NativeXRenderer was linked only; drawing still uses Xenos.' }
  Write-Host 'Test by launching RUN_HULK_NATIVE.cmd; this build has not been game-tested.'
  try { Stop-Transcript | Out-Null } catch {}
  exit 0
} catch {
  Write-Host ("BUILD ERROR: " + $_.Exception.Message) -ForegroundColor Red
  Write-Host ("Send this file for diagnosis: " + $BuildLog)
  try { Stop-Transcript | Out-Null } catch {}
  exit 1
}

