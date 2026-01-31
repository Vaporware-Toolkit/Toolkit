$ErrorActionPreference = "Stop"

$base = "https://raw.githubusercontent.com/Vaporware-Toolkit/Toolkit/main"
$configUrl      = "$base/Config.json"
$categoriesUrl  = "$base/categories.json"
$contributorsUrl = "$base/Contributors.ps1"

# --- Fetch JSON as Hashtable ---
function Get-JsonHashtable {
    param ($url)
    try {
        $raw = Invoke-WebRequest $url -UseBasicParsing
        $obj = $raw.Content | ConvertFrom-Json
        $ht = @{}
        foreach ($p in $obj.PSObject.Properties) {
            $ht[$p.Name] = $p.Value
        }
        return $ht
    } catch {
        Write-Host "Failed to fetch $url" -ForegroundColor Red
        return @{}
    }
}

# Fetch config and categories
$config     = Get-JsonHashtable $configUrl
$categories = Get-JsonHashtable $categoriesUrl

# --- Contributors ---
function Show-Contributors {
    try {
        $raw = Invoke-WebRequest -Uri $contributorsUrl -UseBasicParsing
        ($raw.Content -split "`n") |
            Where-Object { $_ -match 'Contributor\("' } |
            ForEach-Object {
                if ($_ -match 'Contributor\("([^"]+)","([^"]*)"\)') {
                    Write-Host "$($matches[1]) ($($matches[2]))"
                }
            }
    } catch {
        Write-Host "Failed to load contributors"
    }
}

# --- Show Categories (Sections) ---
function Show-Categories {
    Write-Host "`n=== Sections ===`n" -ForegroundColor Cyan
    $map = @{}
    $i = 1
    foreach ($section in $categories.Keys | Sort-Object) {
        Write-Host "$i. $section"
        $map[$i] = $section
        $i++
    }
    Write-Host "`n0. Exit"
    return $map
}

# --- Show Tools in Section ---
function Show-Tools {
    param ($section)
    Write-Host "`n=== $section ===`n" -ForegroundColor Cyan
    $map = @{}
    foreach ($id in $categories[$section] | Sort-Object) {
        $idStr = "$id" # <-- force string
        if ($config.ContainsKey($idStr)) {
            Write-Host "$idStr. $($config[$idStr].Name)"
            $map[$idStr] = $config[$idStr]
        }
    }
    Write-Host "`n0. Back"
    return $map
}

# --- Main Menu ---
Show-Contributors

while ($true) {
    $catMap = Show-Categories
    $choice = Read-Host "Select section"
    if ($choice -eq "0") { break }
    if (-not $catMap.ContainsKey([int]$choice)) { continue }

    $section = $catMap[[int]$choice]

    while ($true) {
        $toolMap = Show-Tools $section
        $toolChoice = Read-Host "Select tool (use ID)"
        if ($toolChoice -eq "0") { break }
        if (-not $toolMap.ContainsKey("$toolChoice")) { 
            Write-Host "Invalid selection" -ForegroundColor Yellow
            continue 
        }

        $tool = $toolMap["$toolChoice"]

        # Open the URL associated with the tool
        if ($tool.PSObject.Properties.Name -contains "URL") {
            Start-Process $tool.URL
        } else {
            Write-Host "No URL found for $($tool.Name)" -ForegroundColor Yellow
        }
    }
}
