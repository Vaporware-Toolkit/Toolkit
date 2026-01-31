# === Vaporware Toolkit Menu.ps1 ===

# GitHub Config URL
$configUrl = "https://raw.githubusercontent.com/Vaporware-Toolkit/Toolkit/refs/heads/main/Config.json" 

# --- Fetch and Convert Config.json to Hashtable ---
function Get-ConfigJson {
    try {
        Write-Host "Fetching Config.json from GitHub..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $configUrl -UseBasicParsing
        $rawJson = $response.Content

        # SHA256 check (optional)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($rawJson)
        $actualHash = ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
        Write-Host "Config SHA256: $actualHash" -ForegroundColor Yellow
        Write-Host "Config verified successfully." -ForegroundColor Green

        # Convert JSON to Hashtable
        $jsonObj = $rawJson | ConvertFrom-Json
        $hashTable = @{}
        foreach ($key in $jsonObj.PSObject.Properties.Name) {
            $hashTable[$key] = $jsonObj.$key
        }
        return $hashTable
    } catch {
        Write-Host "Failed to fetch or parse Config.json: $_" -ForegroundColor Red
        return $null
    }
}

# --- Category Menu ---
$categories = @{
    "VPN / DNS / Privacy Tools" = @("38","39","40","41","42","43","44","45","46","47","48","49")
    "iOS Adblock Apps"           = @("115","116","117","118","119","120","121","122")
    "File & URL Scanners"       = @("1","2","3","4","5","6","7","8","9","10")
    "Antivirus / Security Software" = @("34","35","36","37")
    "Linux / OS / Utilities"    = @("123","124","125","126","127","128","129","130","131","132","133")
    "Malware Analysis / Sandboxes" = @("1","2","3","4","5","6","7","8","9","10")
    "Browsers"                  = @("53","54","55","56","57","58")
    "Mobile OS / Custom ROMs"   = @("110","111","112","113")
    "Browser Privacy Extensions"= @("59","60","61","62","63","64","65","66","67","68","69","70")
    "Uninstallers / System Tools"= @("79","80","81","82","83","84","85","86")
    "Mobile Apps / Android / iOS"= @("88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109")
    "Reverse Engineering / Debugging"= @("50","51","52","53","54")
    "Messaging / Secure Comms"  = @("71","72","73","74","75","76","77","78")
    "Authenticator / 2FA Apps"  = @("134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149")
}

# --- Show Categories ---
function Show-CategoryMenu {
    Write-Host "`n=== Vaporware Toolkit Categories ===`n" -ForegroundColor Cyan
    $index = 1
    foreach ($cat in $categories.Keys) {
        Write-Host "$index. $cat"
        $index++
    }
    Write-Host "`n0. Exit`n"
}

# --- Show Tools Menu ---
function Show-ToolsMenu {
    param(
        [string[]]$names,
        [hashtable]$config
    )

    $toolMap = @{}
    Write-Host "`n--- Tools ---`n" -ForegroundColor Green
    $index = 1
    foreach ($toolId in $names) {
        if ($config.ContainsKey($toolId)) {
            Write-Host "$index. $($config[$toolId])"
            $toolMap[$index] = $config[$toolId]
            $index++
        }
    }
    Write-Host "`n0. Back`n"
    return $toolMap
}

# --- Run Main Menu ---
function Run-MainMenu {
    param([hashtable]$config)

    while ($true) {
        Show-CategoryMenu
        $choice = Read-Host "Enter category number"

        if ($choice -eq "0") { break }

        if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $categories.Keys.Count) {
            $catKey = ($categories.Keys | Select-Object -Index ($choice - 1))
            $toolIds = $categories[$catKey]
            $toolMap = Show-ToolsMenu -names $toolIds -config $config

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

# --- MAIN ---
$config = Get-ConfigJson
if ($config) {
    Run-MainMenu -config $config
}
