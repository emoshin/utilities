<#
.SYNOPSIS
    This script is designed to keep Microsoft Teams active on macOS by simulating user activity (pressing F15 key)
.EXAMPLE
    ./Keep-TeamsActive-Mac.ps1  # every 60s until Ctrl+C is pressed
    ./Keep-TeamsActive-Mac.ps1 -IntervalSeconds 30 -Until "17:00"
#>
[CmdletBinding()]
param(
    [int]$IntervalSeconds = 60,
    [datetime]$Until = [datetime]::MaxValue
)

if (-not $IsMacOS) {
    Write-Error "This script is intended to run only on macOS."
    exit 1
}

Add-Type -Namespace MacOS -Name Input -MemberDefinition @'
    [DllImport("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")]
    public static extern System.IntPtr CGEventCreateKeyboardEvent(System.IntPtr source, ushort virtualKey, bool keyDown);

    [DllImport("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")]
    public static extern void CGEventPost(uint tap, System.IntPtr evt);

    [DllImport("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")]
    public static extern void CFRelease(System.IntPtr cf);
'@

$kVK_F15 = 0x71
$kCGHIDEventTap = 0

$caffeinate = Start-Process -FilePath "/usr/bin/caffeinate" -ArgumentList "-i -w $PID" -NoNewWindow -PassThru
Write-Host "Press Ctrl+C to stop the script. Simulating F15 key press every $IntervalSeconds seconds until $Until."

try {
    while ((Get-Date) -lt $Until) {
        $keyDown = [MacOS.Input]::CGEventCreateKeyboardEvent([IntPtr]::Zero, $kVK_F15, $true)
        $keyUp = [MacOS.Input]::CGEventCreateKeyboardEvent([IntPtr]::Zero, $kVK_F15, $false)
        try {
            [MacOS.Input]::CGEventPost($kCGHIDEventTap, $keyDown)
            [MacOS.Input]::CGEventPost($kCGHIDEventTap, $keyUp)
        }
        finally {
            if ($keyDown -ne [IntPtr]::Zero) { [MacOS.Input]::CFRelease($keyDown) }
            if ($keyUp -ne [IntPtr]::Zero) { [MacOS.Input]::CFRelease($keyUp) }
        }
        Write-Verbose "$(Get-Date -Format T) ping"
        Start-Sleep -Seconds $IntervalSeconds
    }
}
finally {
    if ($caffeinate -and -not $caffeinate.HasExited) {
        $caffeinate.Kill()
    }
    Write-Host "Stopped."
}

