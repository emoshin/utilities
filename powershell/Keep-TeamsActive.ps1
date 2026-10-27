<#
.SYNOPSIS
    This script is designed to keep Microsoft Teams active by simulating user activity(pressing F15 key)
.EXAMPLE
    .\Keep-TeamsActive.ps1  # every 60s until Ctrl+C is pressed
    .\Keep-TeamsActive.ps1 -IntervalSeconds 30 -Until "17:00"
#>
[CmdletBinding()]
param(
    [int]$IntervalSeconds = 60,
    [datetime]$Until = [datetime]::MaxValue
)

Add-Type -Namespace Win32 -Name Input -MemberDefinition @'
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);
    [DllImport("kernel32.dll")]
    public static extern uint SetThreadExecutionState(uint esFlags);
'@

$VK_F15 = 0x7E
$KEYEVENTF_KEYUP = 0x2

[void][Win32.Input]::SetThreadExecutionState([uint32]2147483651) # ES_CONTINUOUS | ES_SYSTEM_REQUIRED
Write-Host "Press Ctrl+C to stop the script. Simulating F15 key press every $IntervalSeconds seconds until $Until."

try{
    while((Get-Date) -lt $Until){
        [Win32.Input]::keybd_event($VK_F15, 0, 0, [UIntPtr]::Zero)
        [Win32.Input]::keybd_event($VK_F15, 0, $KEYEVENTF_KEYUP, [UIntPtr]::Zero)
        Write-Verbose "$(Get-Date -Format T) ping"
        Start-Sleep -Seconds $IntervalSeconds
    }
}
finally {
    [void] [Win32.Input]::SetThreadExecutionState([uint32]2147483648) # ES_CONTINUOUS
    Write-Host "Stopped."
}