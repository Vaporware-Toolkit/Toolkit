$ErrorActionPreference = "Stop"

$base = "https://raw.githubusercontent.com/Vaporware-Toolkit/Toolkit/main"
$configUrl     = "$base/Config.json"
$categoriesUrl = "$base/categories.json"
$contributorsUrl = "https://api.github.com/repos/Vaporware-Toolkit/Toolkit/contributors"

# --- Fetch JSON as Hashtable robustly ---
function Get-JsonHashtable {
    param ($url)
    try {
        $raw = Invoke-WebRequest $url -UseBasicParsing
        $obj = $raw.Content | ConvertFrom-Json

        # Force PSCustomObject into hashtable
        $ht = @{}
        foreach ($p in $obj.PSObject.Properties) {
            $ht[$p.Name] = $p.Value
        }
        return $ht
    } catch {
        Write-Host ("Failed to fetch " + $url + ": " + $_) -ForegroundColor Red
        return @{}
    }
}

# --- Contributors ---
function Show-Contributors {
    try {
        Write-Host "`nFetching contributors from GitHub..." -ForegroundColor Cyan

        $headers = @{ "User-Agent" = "VaporwareToolkit" }
        $response = Invoke-WebRequest -Uri $contributorsUrl -Headers $headers -UseBasicParsing
        $contributors = $response.Content | ConvertFrom-Json

        if (-not $contributors -or $contributors.Count -eq 0) {
            Write-Host "No contributors found." -ForegroundColor Yellow
            return
        }

        Write-Host "`n=== Contributors ===`n" -ForegroundColor Cyan
        foreach ($c in $contributors) {
            $displayName = if ($c.login) { $c.login } else { "Unknown" }
            Write-Host "• $displayName" -ForegroundColor Green
        }
        Write-Host "`n=====================`n" -ForegroundColor Cyan

    } catch {
        Write-Host ("Failed to fetch contributors: " + $_) -ForegroundColor Red
    }
}

# --- Show Categories (Sections) ---
function Show-Categories {
    Write-Host "`n=== Sections ===`n" -ForegroundColor Magenta
    $map = @{}
    $i = 1
    foreach ($section in $categories.Keys | Sort-Object) {
        Write-Host ("[{0}] {1}" -f $i, $section) -ForegroundColor Yellow
        $map[$i] = $section
        $i++
    }
    Write-Host "`n[0] Exit" -ForegroundColor Red
    return $map
}

# --- Show Tools in Section ---
function Show-Tools {
    param ($section)
    Write-Host "`n=== $section ===`n" -ForegroundColor Magenta
    $map = @{}
    foreach ($id in $categories[$section] | Sort-Object) {
        $idStr = "$id"
        if ($config.ContainsKey($idStr)) {
            Write-Host ("[{0}] {1}" -f $idStr, $config[$idStr].Name) -ForegroundColor Green
            $map[$idStr] = $config[$idStr]
        } else {
            Write-Host ("[{0}] [Missing config]" -f $idStr) -ForegroundColor DarkYellow
        }
    }
    Write-Host "`n[0] Back" -ForegroundColor Red
    return $map
}

# --- Fetch config and categories ---
Write-Host "Fetching configuration and categories..." -ForegroundColor Cyan
$config     = Get-JsonHashtable $configUrl
$categories = Get-JsonHashtable $categoriesUrl

# --- Main Menu ---
Clear-Host
Write-Host "*****************************************" -ForegroundColor Cyan
Write-Host "      Welcome to Vaporware Toolkit       " -ForegroundColor Cyan
Write-Host "*****************************************`n" -ForegroundColor Cyan

Show-Contributors

while ($true) {
    $catMap = Show-Categories
    $choice = Read-Host "`nSelect section (number)"
    if ($choice -eq "0") { break }
    if (-not $catMap.ContainsKey([int]$choice)) { 
        Write-Host "Invalid section choice!" -ForegroundColor Red
        continue 
    }

    $section = $catMap[[int]$choice]

    while ($true) {
        $toolMap = Show-Tools $section
        $toolChoice = Read-Host "`nSelect tool (ID)"
        if ($toolChoice -eq "0") { break }
        if (-not $toolMap.ContainsKey("$toolChoice")) { 
            Write-Host "Invalid tool selection!" -ForegroundColor Red
            continue 
        }

        $tool = $toolMap["$toolChoice"]

        if ($tool.PSObject.Properties.Name -contains "URL") {
            Write-Host "`nLaunching $($tool.Name)..." -ForegroundColor Cyan
            Start-Process $tool.URL
        } else {
            Write-Host "No URL found for $($tool.Name)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nThank you for using Vaporware Toolkit!" -ForegroundColor Cyan
