# === Contributors.ps1 (Clean Version) ===

# GitHub repository info
$owner = "Vaporware-Toolkit"
$repo  = "Toolkit"
$contributorsUrl = "https://api.github.com/repos/$owner/$repo/contributors"

# Fetch and display contributors
function Show-Contributors {
    try {
        Write-Host "Fetching contributors from GitHub..." -ForegroundColor Cyan

        # GitHub API requires a User-Agent header
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
        Write-Host "Failed to fetch contributors: $_" -ForegroundColor Red
    }
}

# --- MAIN ---
Show-Contributors
