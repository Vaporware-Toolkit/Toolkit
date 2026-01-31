# === Contributors.ps1 ===

# GitHub repository info
$owner = "Vaporware-Toolkit"
$repo  = "Toolkit"
$contributorsUrl = "https://api.github.com/repos/$owner/$repo/contributors"

# Simple ASCII render function (uppercase with spacing)
function Write-Ascii {
    param([string]$Text)
    $Text = $Text.ToUpper()
    $ascii = $Text -replace '.', '$& '  # Space between letters
    Write-Host $ascii -ForegroundColor Cyan
}

# Fetch and display contributors
function Show-Contributors {
    try {
        Write-Host "Fetching contributors from GitHub..." -ForegroundColor Cyan

        # GitHub API requires a User-Agent header
        $headers = @{ "User-Agent" = "ContributorsScript" }
        $response = Invoke-WebRequest -Uri $contributorsUrl -Headers $headers -UseBasicParsing
        $contributors = $response.Content | ConvertFrom-Json

        if ($contributors.Count -eq 0) {
            Write-Host "No contributors found." -ForegroundColor Yellow
            return
        }

        Write-Ascii "Contributors"

        foreach ($c in $contributors) {
            # Fetch the full user info to get display name
            $userUrl = $c.url
            $userResponse = Invoke-WebRequest -Uri $userUrl -Headers $headers -UseBasicParsing
            $userInfo = $userResponse.Content | ConvertFrom-Json
            $displayName = if ($userInfo.name) { $userInfo.name } else { "No Name" }

            Write-Ascii "$($c.login) ($displayName)"
        }

    } catch {
        Write-Host "Failed to fetch contributors: $_" -ForegroundColor Red
    }
}

# --- MAIN ---
Show-Contributors
