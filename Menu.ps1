# === LOCAL CONFIG PATH & EXPECTED HASH ===
$configPath = ".\config.json"
$expectedHash = "3380e3672ffd50394d8d9bd0750eb1d67ffdf728a72e5afded85b26df6a57347"

# === FUNCTION: Read and Verify Config ===
function Get-ConfigJson {
    try {
        if (-not (Test-Path $configPath)) {
            Write-Host "Config file not found at $configPath" -ForegroundColor Red
            return $null
        }

        $jsonData = Get-Content -Path $configPath -Raw

        # Compute SHA256 hash
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonData)
        $hash = ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""

        if ($hash -ne $expectedHash) {
            Write-Host "Config hash mismatch! Aborting." -ForegroundColor Red
            return $null
        } else {
            Write-Host "Config verified successfully." -ForegroundColor Green
            return $jsonData | ConvertFrom-Json
        }
    } catch {
        Write-Host "Failed to read or parse config.json: $_" -ForegroundColor Red
        return $null
    }
}

# === FUNCTION: Flatten Config for Menu ===
function Flatten-Config {
    param([PSCustomObject]$config)

    $flatList = @()
    foreach ($section in $config.PSObject.Properties) {
        foreach ($item in $section.Value.PSObject.Properties) {
            $flatList += [PSCustomObject]@{
                Section = $section.Name
                Name    = $item.Name
                URL     = $item.Value
            }
        }
    }
    return $flatList
}

# === FUNCTION: Show Menu ===
function Show-Menu {
    param([array]$items)

    Write-Host "`n=== Vaporware Toolkit Menu ===`n" -ForegroundColor Cyan

    $i = 1
    $sectionsPrinted = @()
    foreach ($item in $items) {
        if (-not ($sectionsPrinted -contains $item.Section)) {
            Write-Host "`n--- $($item.Section) ---`n" -ForegroundColor Yellow
            $sectionsPrinted += $item.Section
        }
        Write-Host "$i. $($item.Name)"
        $i++
    }

    Write-Host "`n0. Exit`n"
}

# === FUNCTION: Run Menu Selection ===
function Run-Menu {
    param([array]$items)

    while ($true) {
        Show-Menu -items $items
        $choice = Read-Host "Enter number to open URL"
        
        if ($choice -eq "0") { break }
        if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $items.Count) {
            $url = $items[$choice - 1].URL
            Write-Host "Opening $url..." -ForegroundColor Green
            Start-Process $url
        } else {
            Write-Host "Invalid choice, try again." -ForegroundColor Red
        }
    }
}

# === MAIN ===
$config = Get-ConfigJson
if ($config) {
    $flatItems = Flatten-Config -config $config
    Run-Menu -items $flatItems
}
