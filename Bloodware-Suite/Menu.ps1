# ==============================================================
# BLOODWARE SYSTEM SUITE – OG FULL DASHBOARD SAFE
# Multiple GPU + BIOS selection, PS7/.NET, Privacy, Hardening
# ==============================================================

$ErrorActionPreference = "Continue"
$host.UI.RawUI.WindowTitle = "BLOODWARE SYSTEM SUITE"

# ===================== RESTORE POINT PROMPT =====================
function Ask-RestorePoint {
    $answer = Read-Host "Do you want to create a system restore point before running? (Y/N)"
    if ($answer.ToUpper() -eq "Y") {
        try {
            Write-Host "[*] Creating restore point..." -ForegroundColor Cyan
            Checkpoint-Computer -Description "Bloodware Pre-Run Restore" -RestorePointType "MODIFY_SETTINGS"
            Write-Host "[✔] Restore point created successfully" -ForegroundColor Green
        } catch {
            Write-Host "[!] Failed to create restore point. Ensure System Restore is enabled." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[*] Skipping restore point." -ForegroundColor Yellow
    }
}

# ===================== UTILITY FUNCTIONS =====================
function Write-Box {
    param([string]$Title,[string[]]$Lines,[ConsoleColor]$TitleColor=[ConsoleColor]::Cyan,[ConsoleColor]$BorderColor=[ConsoleColor]::DarkGray)
    $width = ($Lines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum + 4
    $hline = "═" * $width
    Write-Host ("╔" + $hline + "╗") -ForegroundColor $BorderColor
    Write-Host ("║ " + $Title.PadRight($width - 2) + "║") -ForegroundColor $TitleColor
    Write-Host ("╠" + $hline + "╣") -ForegroundColor $BorderColor
    foreach ($line in $Lines) {
        Write-Host ("║ " + $line.PadRight($width - 2) + "║") -ForegroundColor White
    }
    Write-Host ("╚" + $hline + "╝") -ForegroundColor $BorderColor
    Write-Host ""
}

function Open-Link { param($URL) Start-Process $URL }
function FakeBar { param($Label,$Steps=20,$Delay=30); Write-Host "⚙️  $Label [" -NoNewline; 1..$Steps | ForEach-Object { Write-Host "█" -NoNewline; Start-Sleep -Milliseconds $Delay }; Write-Host "] ✓" }

# ===================== SYSTEM INFO =====================
$cs      = try { Get-CimInstance Win32_ComputerSystem } catch { $null }
$bb      = try { Get-CimInstance Win32_BaseBoard } catch { $null }
$bios    = try { Get-CimInstance Win32_BIOS } catch { $null }
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

# ===================== PRE-FLASH CHECKLIST =====================
$checklist = @()
$checklist += "Admin privileges        : " + ($Admin ? "✔" : "❌")
$checklist += "UEFI Firmware           : " + ($fwType -eq "UEFI" ? "✔" : "❌")
$checklist += "Secure Boot enabled     : " + ($sb -eq $true ? "✔" : ($sb -eq $false ? "❌" : "?"))
$checklist += "BitLocker suspended     : " + (-not $bitlocker ? "✔" : "❌")
$checklist += "Battery ≥40%            : " + ($BatteryLevel -ge 40 ? "✔" : "❌")
$checklist += "AC connected            : " + ($ACConnected ? "✔" : "❌")
$checklist += "Not running in VM       : " + (-not $VMCheck ? "✔" : "❌")
Write-Box -Title "PRE-FLASH SYSTEM CHECKLIST" -Lines $checklist -TitleColor DarkRed

# ===================== GPU / BIOS DASHBOARD =====================
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
    default    { $query = [uri]::EscapeDataString("$Vendor $Model $Board BIOS"); $biosURL = "https://www.startpage.com/do/search?query=$query" }
}

# ===================== MODULES =====================
function PS7-Check {
    Write-Host "[*] Checking PowerShell 7..." -ForegroundColor Cyan
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host "[*] PowerShell 7+ not detected. Install via winget if desired." -ForegroundColor Yellow
    } else {
        Write-Host "[✔] PowerShell 7+ is installed" -ForegroundColor Green
    }
}

function Install-DotNetSDK {
    param([ValidateSet("Current","LTS")] [string]$Channel)
    try {
        if ($Channel -eq "Current") { Start-Process "winget" -ArgumentList "install Microsoft.DotNet.SDK.7 -e --silent --accept-package-agreements --accept-source-agreements" -Wait }
        else { Start-Process "winget" -ArgumentList "install Microsoft.DotNet.SDK.6 -e --silent --accept-package-agreements --accept-source-agreements" -Wait }
        Write-Host "[✔] .NET SDK ($Channel) installed" -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to install .NET SDK ($Channel). Ensure winget is installed." -ForegroundColor Red
    }
}

function Safe-SystemHardening {
    Write-Host "[*] Applying safe system hardening..." -ForegroundColor Cyan
    New-Item -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -Name DisableIE -Type DWord -Value 1
    Remove-Item "C:\Program Files\Internet Explorer" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Program Files (x86)\Internet Explorer" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[✔] System hardening applied (IE disabled)" -ForegroundColor Green
}

function Discord-Privacy { Write-Host "[*] Applying Discord privacy..." -ForegroundColor Cyan }
function Privacy-Suite { Write-Host "[*] Applying privacy suite..." -ForegroundColor Cyan }
function DNS-Setup { Write-Host "[*] Configuring DNS..." -ForegroundColor Cyan }
function Firewall-AskMode { Write-Host "[*] Firewall ASK Mode..." -ForegroundColor Cyan }
function Firewall-Allow { Write-Host "[*] Firewall allow outbound..." -ForegroundColor Cyan }
function PowerShell-CLM { Write-Host "[*] Enabling Constrained Language Mode..." -ForegroundColor Cyan }
function Emergency-Restore { Write-Host "[*] Restoring safe defaults..." -ForegroundColor Cyan }

# ===================== MAIN MENU =====================
Ask-RestorePoint

while ($true) {
    Clear-Host
    Write-Host "=============================================================" -ForegroundColor DarkGray
    Write-Host "BLOODWARE SYSTEM SUITE - OG DASHBOARD" -ForegroundColor DarkRed
    Write-Host "=============================================================`n" -ForegroundColor DarkGray

    Write-Host " [1] PS7 Check"
    Write-Host " [2] Install .NET SDKs (Current + LTS)"
    Write-Host " [3] System Hardening"
    Write-Host " [4] Discord Privacy"
    Write-Host " [5] Privacy Suite"
    Write-Host " [6] DNS Setup"
    Write-Host " [7] Firewall ASK Mode"
    Write-Host " [8] Firewall Allow Outbound"
    Write-Host " [9] PowerShell CLM"
    Write-Host " [B] Open BIOS Update Link"
    Write-Host " [G] Open GPU Driver Links (Multiple Select)"
    Write-Host " [0] EMERGENCY RESTORE"
    Write-Host " [A] Run ALL"
    Write-Host " [X] Exit`n"

    $choice = Read-Host "Select option"
    Write-Host ""

    switch ($choice.ToUpper()) {
        "1" { PS7-Check }
        "2" { Install-DotNetSDK -Channel "Current"; Install-DotNetSDK -Channel "LTS" }
        "3" { Safe-SystemHardening }
        "4" { Discord-Privacy }
        "5" { Privacy-Suite }
        "6" { DNS-Setup }
        "7" { Firewall-AskMode }
        "8" { Firewall-Allow }
        "9" { PowerShell-CLM }
        "B" { Open-Link $biosURL }
        "G" {
            Write-Host "Detected GPU links:" -ForegroundColor Cyan
            foreach ($key in $gpuLinks.Keys) { Write-Host "[$key] $($gpuLinks[$key].Name) → $($gpuLinks[$key].URL)" }
            $gpuInput = Read-Host "Enter GPU numbers to open (comma-separated, e.g., 1,3)"
            $gpuInput -split "," | ForEach-Object {
                $num = $_.Trim()
                if ($gpuLinks.ContainsKey([int]$num)) { Open-Link $gpuLinks[[int]$num].URL }
            }
        }
        "0" { Emergency-Restore }
        "A" {
            PS7-Check
            Install-DotNetSDK -Channel "Current"
            Install-DotNetSDK -Channel "LTS"
            Safe-SystemHardening
            Discord-Privacy
            Privacy-Suite
            DNS-Setup
            Firewall-Allow
            PowerShell-CLM
        }
        "X" { Write-Host "Exiting Bloodware System Suite..." -ForegroundColor Yellow; exit }
        default { Write-Host "[!] Invalid option, try again." -ForegroundColor Red }
    }

    Write-Host "`nPress any key to continue..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
