$ErrorActionPreference = "Stop"

$base = "https://raw.githubusercontent.com/Vaporware-Toolkit/Toolkit/main"
$configUrl     = "$base/Config.json"
$categoriesUrl = "$base/categories.json"
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

$config     = Get-JsonHashtable $configUrl
$tools      = Get-JsonHashtable $toolsUrl
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

# --- Show Categories ---
function Show-Categories {
    Write-Host "`n=== Categories ===`n" -ForegroundColor Cyan
    $i = 1
    $map = @{}
    foreach ($c in $categories.Keys) {
        Write-Host "$i. $c"
        $map[$i] = $c
        $i++
    }
    Write-Host "`n0. Exit"
    return $map
}

# --- Show Tools ---
function Show-Tools {
    param ($category)
    Write-Host "`n=== $category ===`n" -ForegroundColor Cyan
    $i = 1
    $map = @{}
    foreach ($id in $categories[$category]) {
        Write-Host "$i. $($tools[$id])"
        $map[$i] = $id
        $i++
    }
    Write-Host "`n0. Back"
    return $map
}

# --- Main Menu ---
Show-Contributors

while ($true) {
    $catMap = Show-Categories
    $choice = Read-Host "Select category"
    if ($choice -eq "0") { break }
    if (-not $catMap.ContainsKey([int]$choice)) { continue }

    $category = $catMap[[int]$choice]

    while ($true) {
        $toolMap = Show-Tools $category
        $toolChoice = Read-Host "Select tool"
        if ($toolChoice -eq "0") { break }
        if (-not $toolMap.ContainsKey([int]$toolChoice)) { continue }

        $id = $toolMap[[int]$toolChoice]
        Start-Process $config[$id]
    }
}
