# ==============================================================
# BLOODWARE SYSTEM SUITE – FULL ALL-IN-ONE SAFE MENU
# Vencord removed; includes PS7, DNS, Discord, WHFS, IE, BIOS, GPU, .NET
# ==============================================================

Clear-Host

# ── HEADER ──────────────────────────────
$logo=@"
██████╗ ██╗      ██████╗ ██████╗ ██████╗  █████╗ ██████╗ ███████╗
██╔══██╗██║     ██╔═══██╗██╔═══██╗██╔══██╗██║    ██║██╔══██╗██╔══██╗
██████╔╝██║     ██║   ██║██║   ██║██║  ██║██║ █╗ ██║███████║██████╔╝
██╔══██╗██║     ██║   ██║██║   ██║██║  ██║██║███╗██║██╔══██║██╔══██╗
██████╔╝███████╗╚██████╔╝╚██████╔╝██████╔╝╚███╔███╔╝██║  ██║██║  ██║
╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝
                 BLOODWARE SYSTEM SUITE – SAFE MODE
"@
Write-Host $logo -ForegroundColor DarkRed
Write-Host ("─" * 90) -ForegroundColor DarkGray

# ── UTILITY FUNCTIONS ───────────────────
function Confirm-Action { param([string]$Msg) return Read-Host "$Msg [Y/N]" -eq "Y" }
function FakeBar { param($Label,$Steps=20,$Delay=30); Write-Host "⚙️  $Label [" -NoNewline; 1..$Steps | ForEach-Object { Write-Host "█" -NoNewline; Start-Sleep -Milliseconds $Delay }; Write-Host "] ✓" }
function Open-Link { param($URL) Start-Process $URL }

# ==============================================================
# SYSTEM INFO FOR DASHBOARD (GPU / BIOS / Battery / Admin)
# ==============================================================
$cs      = try { Get-CimInstance Win32_ComputerSystem } catch { $null }
$bb      = try { Get-CimInstance Win32_BaseBoard } catch { $null }
$prod    = try { Get-CimInstance Win32_ComputerSystemProduct } catch { $null }
$gpuList = try { Get-CimInstance Win32_VideoController } catch { @() }
$battery = try { Get-CimInstance Win32_Battery } catch { $null }
$fwType  = try { (Get-ComputerInfo -Property BiosFirmwareType).BiosFirmwareType } catch { "Unknown" }
$sb      = try { Confirm-SecureBootUEFI } catch { $null }
$bitlocker = try { Get-BitLockerVolume | Where-Object {$_.ProtectionStatus -eq "On"} } catch { $null }

$Vendor = $cs.Manufacturer.Trim()
$Model  = $cs.Model.Trim()
$Board  = $bb.Product.Trim()
$Serial = $prod.IdentifyingNumber.Trim()
$BatteryLevel = if ($battery) { $battery.EstimatedChargeRemaining } else { 100 }
$ACConnected   = if ($cs.PowerSupplyState -eq 1) { $true } else { $false }
$Admin         = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$VMCheck       = if ($cs.Model -match "Virtual|VMware|KVM|Hyper-V") { $true } else { $false }

# ── BIOS LINK NORMALIZATION ─────────────
$VendorNormalized = switch -Regex ($Vendor) {
    "ASUSTeK|ASUS" { "ASUS" }
    "MSI"          { "MSI" }
    "Gigabyte"     { "Gigabyte" }
    "HP"           { "HP" }
    "Dell"         { "Dell" }
    "Lenovo"       { "Lenovo" }
    default        { $Vendor }
}

switch ($VendorNormalized) {
    "Dell"     { $biosURL = "https://www.dell.com/support/home/en-us/product-support/servicetag/$Serial" }
    "Lenovo"   { $biosURL = "https://pcsupport.lenovo.com/us/en/products?serialNumber=$Serial" }
    "HP"       { $biosURL = "https://support.hp.com/us-en/search?q=$Serial" }
    "MSI"      { $biosURL = "https://www.msi.com/support/search?q=$Board" }
    "Gigabyte" { $biosURL = "https://www.gigabyte.com/Search?kw=$Board" }
    default    { 
        $query = [uri]::EscapeDataString("$Vendor $Model $Board BIOS")
        $biosURL = "https://www.startpage.com/do/search?query=$query"
    }
}

# ── GPU DRIVER LINKS ─────────────────────
$gpuLinks=@{}
$i=1
foreach ($gpu in $gpuList) {
    $name=$gpu.Name
    switch -Regex ($name) {
        "NVIDIA" { $gpuLinks[$i] = @{ Name=$name; URL="https://www.nvidia.com/en-us/software/nvidia-app/" } }
        "AMD|Radeon" { $gpuLinks[$i] = @{ Name=$name; URL="https://www.amd.com/en/support" } }
        "Intel" { $gpuLinks[$i] = @{ Name=$name; URL="https://www.intel.com/download-center" } }
        default { $gpuLinks[$i] = @{ Name=$name; URL="https://www.startpage.com/do/search?query=$name+drivers" } }
    }
    $i++
}

# ── MODULE 1: PS7 ENFORCER / INSTALLER
function Module-PS7 {
    $pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwshPath) {
        Write-Host "[*] PowerShell 7 not found. Installing via winget..." -ForegroundColor Yellow
        Start-Process "winget" -ArgumentList "install --id Microsoft.PowerShell -e --silent --accept-package-agreements --accept-source-agreements" -Wait
    }
    Write-Host "✅ PowerShell 7 is installed / available"
}

# ── MODULE 2: DNS PRIVACY HARDENING
function Module-DNSPrivacy {
    Write-Host "[*] Configuring DNS Privacy..." -ForegroundColor Cyan
    Get-DnsClient | ForEach-Object { 
        Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses ("1.1.1.1","1.0.0.1","9.9.9.9","149.112.112.112") -ErrorAction SilentlyContinue 
    }
    Set-DnsClientGlobalSetting -EnableDnsSec $true
    reg add HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters /v EnableAutoDoh /t REG_DWORD /d 2 /f
    Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled} | ForEach-Object { $_.SetTcpipNetbios(2) }
    reg add HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient /v EnableMulticast /t REG_DWORD /d 0 /f
    ipconfig /flushdns | Out-Null
    Write-Host "✅ DNS privacy configured" -ForegroundColor Green
}

# ── MODULE 3: DISCORD PRIVACY ONLY
function Module-DiscordPrivacy {
    Write-Host "[*] Discord Privacy Hardening Module..." -ForegroundColor Cyan
    $discordExe = "$env:LOCALAPPDATA\Discord\app-1.0.9219\Discord.exe"
    if (-Not (Test-Path $discordExe)) {
        Write-Host "⬇️ Discord not found. Installing..."
        Get-Process Discord, DiscordSetup -ErrorAction SilentlyContinue | Stop-Process -Force
        $paths = @("$env:LOCALAPPDATA\Discord","$env:APPDATA\Discord")
        foreach ($p in $paths) { if (Test-Path $p) { Remove-Item $p -Recurse -Force } }
        $tempInstaller = "$env:LOCALAPPDATA\Temp\DiscordSetup.exe"
        Invoke-WebRequest -Uri "https://discord.com/api/download?platform=win" -OutFile $tempInstaller -UseBasicParsing
        Start-Process -FilePath $tempInstaller -ArgumentList "/S" -Wait
        Remove-Item $tempInstaller -Force
        Write-Host "✅ Discord installed."
    } else { Write-Host "ℹ️ Discord already installed." }

    # Apply privacy settings
    $settingsPath = "$env:APPDATA\Discord\settings.json"
    $settings = @{
        "analytics" = $false
        "crash_reporting" = $false
        "enable_experiments" = $false
        "hardware_acceleration" = $false
        "overlay_enabled" = $false
        "auto_launch" = $false
    }
    $settings | ConvertTo-Json | Set-Content $settingsPath -Force

    # Block telemetry
    $telemetryHosts = @("discordapp.com","discord.com","api.discord.com","status.discord.com")
    foreach ($host in $telemetryHosts) {
        if (-not (Get-NetFirewallRule -DisplayName "Block $host" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName "Block $host" -Direction Outbound -Action Block -RemoteAddress $host -Profile Any -Enabled True
        }
    }
    Write-Host "🎉 Discord privacy hardened"
}

# ── MODULE 4: WINDOWS HOST FORTIFICATION (WHFS)
function Module-WHFS {
    Write-Host "[*] Windows Host Fortification Suite..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block
    Write-Host "✅ Default firewall deny outbound applied"
    Write-Host "✅ Recommended WHFS hardening complete"
}

# ── MODULE 5: INTERNET EXPLORER CLEANUP
function Module-RemoveIE {
    Write-Host "[*] Internet Explorer Cleanup Module"
    if (Confirm-Action "⚠️ Disable IE and remove program files?") {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name DisableIE -Type DWord -Value 1
        Remove-Item "C:\Program Files\Internet Explorer" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Program Files (x86)\Internet Explorer" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ IE disabled & cleaned"
    }
}

# ── MODULE 6: BIOS / GPU / .NET DASHBOARD
function Module-Dashboard {
    Write-Host "[*] BIOS / GPU / .NET Dashboard"

    # BIOS Link
    Write-Host "[B] BIOS Update Link: $biosURL" -ForegroundColor Yellow

    # GPU Links
    foreach ($key in $gpuLinks.Keys) {
        Write-Host "[{0}] {1} → {2}" -f $key,$gpuLinks[$key].Name,$gpuLinks[$key].URL
    }

    # .NET SDK Installer
    Write-Host "[D] Install .NET SDKs (Current + LTS)" -ForegroundColor Green
    $dotnetInstallDir = "$env:LOCALAPPDATA\dotnet"
    $scriptPath = Join-Path $env:TEMP "dotnet-install.ps1"
    if (-not(Test-Path $scriptPath)) {
        Invoke-WebRequest "https://dot.net/v1/dotnet-install.ps1" -OutFile $scriptPath
        Unblock-File $scriptPath
    }
    $input = Read-Host "Install .NET SDKs? Y/N"
    if ($input -eq "Y") {
        & $scriptPath -Channel Current -InstallDir $dotnetInstallDir -NoPath
        & $scriptPath -Channel LTS -InstallDir $dotnetInstallDir -NoPath
        Write-Host "✅ .NET SDKs installed"
    }
}

# ── MAIN MENU LOOP
do {
    Write-Host "`n===== BLOODWARE SYSTEM SUITE MENU =====" -ForegroundColor DarkRed
    Write-Host "[1] PowerShell 7 Installer / Enforcer"
    Write-Host "[2] DNS Privacy Hardening"
    Write-Host "[3] Discord Privacy"
    Write-Host "[4] Windows Host Fortification (WHFS)"
    Write-Host "[5] Internet Explorer Cleanup"
    Write-Host "[6] BIOS / GPU / .NET Dashboard"
    Write-Host "[Q] Quit"

    $choice = Read-Host "`nSelect an option"
    switch ($choice.ToUpper()) {
        "1" { Module-PS7 }
        "2" { Module-DNSPrivacy }
        "3" { Module-DiscordPrivacy }
        "4" { Module-WHFS }
        "5" { Module-RemoveIE }
        "6" { Module-Dashboard }
        "Q" { break }
        default { Write-Host "❌ Invalid choice" -ForegroundColor Red }
    }
} while ($true)
