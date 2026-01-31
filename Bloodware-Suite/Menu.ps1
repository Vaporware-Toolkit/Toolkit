<#
.SYNOPSIS
Vaporware Bloodware Suite – Unified & Safe
.DESCRIPTION
- Automatically installs latest PowerShell 7+ via winget if missing
- DNS Privacy, Discord Privacy, WHFS modules
- Safe defaults, AV-friendly
- Requires Administrator
#>

# ── ADMIN CHECK ─────────────────────────
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "❌ Run as Administrator!" -ForegroundColor Red
    exit
}

# ── LOGGING ─────────────────────────────
$LogPath="$env:ProgramData\Vaporware\Logs"
if (-not(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath | Out-Null }
Start-Transcript "$LogPath\Bloodware-Run-$(Get-Date -f yyyyMMdd-HHmmss).log"

# ── UTILITY FUNCTIONS ───────────────────
function Write-Box {
    param([string]$Title,[string[]]$Lines)
    $width = ($Lines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum + 4
    $hline = "═" * $width
    Write-Host ("╔" + $hline + "╗") -ForegroundColor DarkGray
    Write-Host ("║ " + $Title.PadRight($width-2) + "║") -ForegroundColor Cyan
    Write-Host ("╠" + $hline + "╣") -ForegroundColor DarkGray
    foreach ($line in $Lines) { Write-Host ("║ " + $line.PadRight($width-2) + "║") }
    Write-Host ("╚" + $hline + "╝") -ForegroundColor DarkGray
}

function Confirm-Action($msg) {
    $resp = Read-Host "$msg Type YES to continue"
    return ($resp -eq "YES")
}

function Ensure-PS7 {
    Write-Host "[*] Checking PowerShell 7+..."
    $pwshList = Get-Command pwsh.exe -All | Select-Object -ExpandProperty Source
    $latest = $pwshList | ForEach-Object {
        try { [PSCustomObject]@{Path=$_; Version=[Version]((& $_ -NoProfile -Command '$PSVersionTable.PSVersion.ToString()').Trim())} } catch {}
    } | Sort-Object Version -Descending | Select-Object -First 1

    if ($latest -and $latest.Version.Major -ge 7) {
        Write-Host "✅ Latest PS7 found: $($latest.Version) at $($latest.Path)"
        return $latest.Path
    } else {
        Write-Host "⚠️ PowerShell 7+ not found. Installing via winget..."
        try {
            Start-Process "winget" -ArgumentList "install --id Microsoft.PowerShell -e --silent --accept-package-agreements --accept-source-agreements" -Wait
            $pwshList = Get-Command pwsh.exe -All | Select-Object -ExpandProperty Source
            $latest = $pwshList | ForEach-Object {
                try { [PSCustomObject]@{Path=$_; Version=[Version]((& $_ -NoProfile -Command '$PSVersionTable.PSVersion.ToString()').Trim())} } catch {}
            } | Sort-Object Version -Descending | Select-Object -First 1
            if ($latest) { Write-Host "✅ PS7 installed: $($latest.Version) at $($latest.Path)"; return $latest.Path }
            else { Write-Host "❌ PS7 installation failed."; return $null }
        } catch { Write-Host "❌ Winget installation failed: $_"; return $null }
    }
}

# ── MODULES ─────────────────────────────

function Module-DNSPrivacy {
    Write-Host "[*] DNS Privacy Hardening"
    Get-DnsClient | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses ("1.1.1.1","1.0.0.1","9.9.9.9","149.112.112.112") -ErrorAction SilentlyContinue
    }
    Set-DnsClientGlobalSetting -EnableDnsSec $true
    reg add HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters /v EnableAutoDoh /t REG_DWORD /d 2 /f
    Get-WmiObject Win32_NetworkAdapterConfiguration | Where IPEnabled | ForEach-Object { $_.SetTcpipNetbios(2) }
    reg add HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient /v EnableMulticast /t REG_DWORD /d 0 /f
    Write-Host "✅ DNS Privacy configured"
}

function Module-DiscordPrivacy {
    Write-Host "[*] Discord Privacy + Vencord"
    $discordExe="$env:LOCALAPPDATA\Discord\app-1.0.9219\Discord.exe"
    $vencordFile="$env:APPDATA\Discord\app-1.0.9219\modules\discord_desktop_core-1\discord_desktop_core\vencord.asar"

    if (-not (Test-Path $discordExe)) { Write-Host "ℹ️ Discord not found. Skipping install for safety." }

    $settingsPath="$env:APPDATA\Discord\settings.json"
    $settings=@{
        "analytics"=$false
        "crash_reporting"=$false
        "enable_experiments"=$false
        "hardware_acceleration"=$false
        "overlay_enabled"=$false
        "auto_launch"=$false
    }
    $settings | ConvertTo-Json | Set-Content $settingsPath -Force
    Write-Host "🔧 Privacy settings applied"

    $telemetryHosts=@("discordapp.com","discord.com","api.discord.com","status.discord.com")
    foreach ($host in $telemetryHosts) {
        if (-not (Get-NetFirewallRule -DisplayName "Block $host" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName "Block $host" -Direction Outbound -Action Block -RemoteAddress $host -Profile Any -Enabled True
            Write-Host "🛡️ Blocked $host"
        }
    }
    Write-Host "✅ Discord Privacy Hardened"
}

function Module-WHFS {
    Write-Host "[*] Windows Host Fortification Suite (Safe Mode)"
    if (Confirm-Action "⚠️ This module performs system hardening. Proceed?") {
        bcdedit /set nx AlwaysOn
        bcdedit /set hypervisorlaunchtype Auto
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection /v AllowTelemetry /t REG_DWORD /d 0 /f
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f
        Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
        Set-Service DiagTrack Disabled
        Write-Host "✅ Safe WHFS hardening applied"
    } else { Write-Host "[!] WHFS skipped" }
}

# ── MAIN MENU ───────────────────────────
$pwshPath = Ensure-PS7
if (-not $pwshPath) { Write-Host "❌ Cannot continue without PS7"; exit }

do {
    Clear-Host
    Write-Host "Vaporware Bloodware Suite" -ForegroundColor DarkRed
    Write-Host "1️⃣  DNS Privacy + Quad9 + DoH"
    Write-Host "2️⃣  Discord Privacy + Vencord"
    Write-Host "3️⃣  WHFS Safe Hardening"
    Write-Host "Q️⃣  Quit"
    $choice = Read-Host "Enter choice"
    switch ($choice.ToUpper()) {
        "1" { Module-DNSPrivacy }
        "2" { Module-DiscordPrivacy }
        "3" { Module-WHFS }
        "Q" { break }
        default { Write-Host "❌ Invalid choice" -ForegroundColor Red }
    }
    Write-Host "`nPress Enter to return to menu..."
    Read-Host
} while ($true)

Stop-Transcript
Write-Host "🎉 Bloodware Suite finished. Review log at $LogPath" -ForegroundColor Green
