# === CONFIG FROM GITHUB ===
$configUrl = "https://raw.githubusercontent.com/Vaporware-Toolkit/Toolkit/main/config.json"
$expectedHash = "3380e3672ffd50394d8d9bd0750eb1d67ffdf728a72e5afded85b26df6a57347"

function Get-ConfigJson {
    try {
        Write-Host "Fetching config.json from GitHub..." -ForegroundColor Cyan
        $jsonData = Invoke-RestMethod -Uri $configUrl -UseBasicParsing

        # Compute SHA256 hash
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonData | ConvertTo-Json -Compress)
        $hash = ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""

        if ($hash -ne $expectedHash) {
            Write-Host "Config hash mismatch! Aborting." -ForegroundColor Red
            return $null
        } else {
            Write-Host "Config verified successfully." -ForegroundColor Green
            return $jsonData | ConvertFrom-Json
        }
    } catch {
        Write-Host "Failed to fetch or parse config.json: $_" -ForegroundColor Red
        return $null
    }
}

# === CATEGORY MENU ===
function Show-CategoryMenu {
    Write-Host "`n=== Vaporware Toolkit Categories ===`n" -ForegroundColor Cyan
    $i = 1
    foreach ($cat in $categories.Keys) {
        Write-Host "$i. $cat"
        $i++
    }
    Write-Host "`n0. Exit`n"
}

# === TOOLS MENU ===
function Show-ToolsMenu {
    param([array]$names, [hashtable]$config)
    $i = 1
    $toolMap = @{}
    foreach ($name in $names) {
        Write-Host "$i. $name"
        $toolMap[$i] = $config[$tools[$name]]
        $i++
    }
    Write-Host "`n0. Back`n"
    return $toolMap
}

# === MAIN MENU LOOP ===
function Run-MainMenu {
    param([hashtable]$config)
    while ($true) {
        Show-CategoryMenu
        $choice = Read-Host "Enter category number"

        if ($choice -eq "0") { break }

        if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $categories.Keys.Count) {
            $catKey = ($categories.Keys | Select-Object -Index ($choice - 1))
            $toolNames = $categories[$catKey]
            $toolMap = Show-ToolsMenu -names $toolNames -config $config

            while ($true) {
                $toolChoice = Read-Host "Enter tool number to open URL"
                if ($toolChoice -eq "0") { break }
                if ($toolChoice -match '^\d+$' -and $toolMap.ContainsKey([int]$toolChoice)) {
                    Start-Process $toolMap[[int]$toolChoice]
                } else {
                    Write-Host "Invalid choice, try again." -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Invalid category, try again." -ForegroundColor Red
        }
    }
}

# === MAIN EXECUTION ===
$config = Get-ConfigJson
if ($config) {
    Run-MainMenu -config $config
}
