# =========================================
# Vaporware Toolkit Loader (Hardened, UTF-8, PS5.1+)
# =========================================

$ErrorActionPreference = "Stop"

$base = "https://raw.githubusercontent.com/Vaporware-Toolkit/Toolkit/main"

$menuUrl      = "$base/Menu.ps1"
$configUrl    = "$base/Config.json"
$categoriesUrl = "$base/categories.json"

$cacheDir  = Join-Path $env:LOCALAPPDATA "VaporwareToolkit"
$menuPath  = Join-Path $cacheDir "Menu.ps1"
$hashPath  = Join-Path $cacheDir "Menu.sha256"

Write-Host "`n[Vaporware Toolkit] Loader starting..." -ForegroundColor Cyan

# --- Ensure cache directory exists ---
if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir | Out-Null
}

# --- Check reachability of remote files ---
try {
    Invoke-WebRequest -Uri $configUrl -UseBasicParsing -TimeoutSec 10 | Out-Null
    $remoteMenu = Invoke-WebRequest -Uri $menuUrl -UseBasicParsing -TimeoutSec 10
} catch {
    Write-Host "[!] Required files unreachable. Aborting." -ForegroundColor Red
    exit 1
}

# --- Compute SHA256 of remote menu ---
$remoteBytes = [System.Text.Encoding]::UTF8.GetBytes($remoteMenu.Content)
$remoteHash  = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new($remoteBytes)) -Algorithm SHA256).Hash

$updateNeeded = $true

# --- Compare with cached hash ---
if ((Test-Path $menuPath) -and (Test-Path $hashPath)) {
    $localHash = Get-Content $hashPath -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($localHash -eq $remoteHash) {
        $updateNeeded = $false
    }
}

# --- Update cache if needed ---
if ($updateNeeded) {
    Write-Host "[*] Updating Menu.ps1..." -ForegroundColor Yellow
    $remoteMenu.Content | Out-File -FilePath $menuPath -Encoding UTF8 -Force
    $remoteHash         | Out-File -FilePath $hashPath -Encoding UTF8 -Force
} else {
    Write-Host "[+] Menu.ps1 is up to date." -ForegroundColor Green
}

# --- Display integrity hash ---
Write-Host "[i] Menu.ps1 SHA-256:" -ForegroundColor Cyan
Write-Host "    $remoteHash" -ForegroundColor DarkGray

# --- Execution policy check ---
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "Restricted") {
    Write-Host "`n[!] PowerShell execution policy is Restricted." -ForegroundColor Yellow
    Write-Host "    Allow local scripts to run:" -ForegroundColor Yellow
    Write-Host "    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned" -ForegroundColor Cyan
    exit 1
}

# --- Launch Menu ---
Write-Host "`n[+] Launching Vaporware Toolkit Menu..." -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoProfile -File `"$menuPath`"" -WindowStyle Normal

exit
