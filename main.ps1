$base = "https://raw.githubusercontent.com/Vaporware-Toolkit/Toolkit/main"

$configUrl     = "$base/Config.json"
$toolsUrl      = "$base/tools.json"
$categoriesUrl = "$base/categories.json"
$menuURL = "$base/Menu.json"

function Get-JsonHashtable {
    param ($url)
    $raw = Invoke-WebRequest $url -UseBasicParsing
    $obj = $raw.Content | ConvertFrom-Json
    $ht = @{}
    foreach ($p in $obj.PSObject.Properties) {
        $ht[$p.Name] = $p.Value
    }
    return $ht
}

$config     = Get-JsonHashtable $configUrl
$tools      = Get-JsonHashtable $toolsUrl
$categories = Get-JsonHashtable $categoriesUrl

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

function Show-Tools {
    param ($category)

    Write-Host "`n=== $category ===`n" -ForegroundColor Cyan
    $i = 1
    $map = @{}

    foreach ($id in $categories[$category]) {
        $name = $tools["$id"]
        Write-Host "$i. $name"
        $map[$i] = "$id"
        $i++
    }

    Write-Host "`n0. Back"
    return $map
}

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
