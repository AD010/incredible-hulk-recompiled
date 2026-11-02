# Saves pictures of a running program's window without bringing it forward (PrintWindow with full content).
#   tools\capture_window.ps1 -ProcessId 1234 -Out runs\shot -Times 20,45,80
param([int]$ProcessId, [string]$Out, [int[]]$Times = @(30))
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  public static IntPtr Find(uint want) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, l) => { uint pid; GetWindowThreadProcessId(h, out pid);
      if (pid == want && IsWindowVisible(h)) { found = h; return false; } return true; }, IntPtr.Zero);
    return found;
  }
}
"@
# Without this a scaled display reports a smaller window than PrintWindow draws, and the picture is cropped.
[Win]::SetProcessDPIAware() | Out-Null
$start = Get-Date
foreach ($t in $Times) {
  while (((Get-Date) - $start).TotalSeconds -lt $t) { Start-Sleep -Milliseconds 250 }
  $h = [Win]::Find([uint32]$ProcessId)
  if ($h -eq [IntPtr]::Zero) { "no window at $t s"; continue }
  $r = New-Object Win+RECT
  [Win]::GetClientRect($h, [ref]$r) | Out-Null
  $w = [Math]::Max(1, $r.Right - $r.Left); $ht = [Math]::Max(1, $r.Bottom - $r.Top)
  $bmp = New-Object System.Drawing.Bitmap $w, $ht
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $dc = $g.GetHdc()
  [Win]::PrintWindow($h, $dc, 3) | Out-Null  # PW_CLIENTONLY | PW_RENDERFULLCONTENT
  $g.ReleaseHdc($dc); $g.Dispose()
  $file = "$Out-$t.png"
  $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
  "saved $file ($w x $ht)"
}
