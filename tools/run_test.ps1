# Starts the test copy in runs\play for a while, then closes it and prints the end of its log.
#   tools\run_test.ps1 [-Seconds 60] [-Extra "--some_cvar=1,--other=2"]
# The game reads the disc files from game\ and keeps its saves in runs\user, never in Documents.
# Start tools\bgwin\bgwin.exe first so its window stays behind yours.
param([int]$Seconds = 60, [string]$Extra = "", [string]$Tag = "run")
$root = Split-Path $PSScriptRoot -Parent
$play = Join-Path $root "runs\play"
$log = Join-Path $root "runs\$Tag.log"
Remove-Item $log -ErrorAction SilentlyContinue
$args = @("--game_data_root=$root\game", "--user_data_root=$root\runs\user", "--log_file=$log")
if ($Extra) { $args += $Extra.Split(",") }
$p = Start-Process -FilePath (Join-Path $play "incredible_hulk.exe") -ArgumentList $args -WorkingDirectory $play -PassThru
$p.WaitForExit($Seconds * 1000) | Out-Null
$code = if ($p.HasExited) { "exited 0x{0:X8}" -f $p.ExitCode } else { "still running after $Seconds s, closed"; Stop-Process -Id $p.Id -Force }
"== $code"
if (Test-Path $log) { Get-Content $log -Tail 40 }
