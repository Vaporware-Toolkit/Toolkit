# === CONFIG FROM GITHUB ===
$configUrl = "https://raw.githubusercontent.com/Vaporware-Toolkit/Toolkit/main/Config.json"
$expectedHash = "6e7b0acc474f423452449ae652557c6f868d96e6eae9a76706e92c5fe2b8d351"

function Get-ConfigJson {
    try {
        Write-Host "Fetching Config.json from GitHub..." -ForegroundColor Cyan

        # Fetch raw content as string
        $rawJson = Invoke-RestMethod -Uri $configUrl -UseBasicParsing

        # Compute SHA256 hash on the raw string
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($rawJson)
        $hash = ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""

        if ($hash -ne $expectedHash) {
            Write-Host "Config hash mismatch! Aborting." -ForegroundColor Red
            Write-Host "Expected: $expectedHash"
            Write-Host "Actual  : $hash"
            return $null
        } else {
            Write-Host "Config verified successfully." -ForegroundColor Green
            return $rawJson | ConvertFrom-Json
        }
    } catch {
        Write-Host "Failed to fetch or parse Config.json: $_" -ForegroundColor Red
        return $null
    }
}

# === FRIENDLY NAMES MAPPING ===
$tools = @{
    "Any.Run" = "1"; "Hybrid Analysis" = "2"; "IRIS-H" = "3"; "Intezer Analyze" = "4"; "Joe Sandbox" = "5";
    "Manalyzer" = "6"; "Metadefender" = "7"; "Sandbox Pikker" = "8"; "Polyswarm" = "9"; "TY Labs Scan" = "10";
    "Checkpoint ThreatPoint" = "11"; "SecondWrite Webportal" = "12"; "Talos Intelligence" = "13"; "VirusTotal" = "14";
    "Kaspersky OpenTip" = "15"; "Jotti" = "16"; "URLVoid" = "17"; "URLScan.io" = "18"; "Quttera" = "19";
    "FileScan.io" = "20"; "VirScan.org" = "21"; "Sucuri SiteCheck" = "22"; "NordVPN File Checker" = "23"; 
    "Dr.Web VMS" = "24"; "ScanMalware.com" = "25"; "Internxt Virus Scanner" = "26"; "DynamiteLab" = "27"; 
    "VMRay" = "28"; "SecondWrite" = "29"; "MalShare" = "30"; "Acronis" = "31"; "EmailVeritas File Checker" = "32"; 
    "Watchdog Online Scanner" = "33"; "Kaspersky Free Antivirus" = "34"; "Bitdefender Free" = "35"; 
    "Dr.Web CureIt!" = "36"; "HitmanPro" = "37"; "ProtonVPN" = "38"; "Mullvad" = "39"; "NordVPN" = "40"; 
    "TunnelBear" = "41"; "Quad9 DNS" = "42"; "NextDNS" = "43"; "Cloudflare DNS" = "44"; "AdGuard DNS" = "45"; 
    "ControlD DNS" = "46"; "NordVPN Private DNS" = "47"; "DNS.Watch" = "48"; "JoinDNS4" = "49"; "IDA Auth" = "50"; 
    "dnSpy" = "51"; "ILSpy" = "52"; "LibreWolf Browser" = "53"; "Brave Browser" = "54"; "Tor Browser" = "55"; 
    "Mullvad Browser" = "56"; "Gnuzilla" = "57"; "Waterfox" = "58"; "AdNauseam" = "59"; "Privacy Badger" = "60"; 
    "HTTPS Everywhere" = "61"; "uBlock Origin" = "62"; "Qwant (Chrome)" = "63"; "Qwant (Firefox)" = "64"; 
    "Startpage (Chrome)" = "65"; "Startpage (Firefox)" = "66"; "JShelter" = "67"; "Cookie AutoDelete" = "68"; 
    "LibRedirect Website" = "69"; "LibRedirect GitHub" = "70"; "Telegram" = "71"; "Nekogram" = "72"; "Signal" = "73"; 
    "Threema" = "74"; "Session" = "75"; "Element" = "76"; "Briar" = "77"; "Simplex Chat" = "78"; 
    "Revo Uninstaller" = "79"; "Geek Uninstaller" = "80"; "Uninstalr" = "81"; "Bulk Crap Uninstaller" = "82"; 
    "FindMySoft" = "83"; "Uninstall Tool" = "84"; "Win11Debloat" = "85"; "Windows10Debloater" = "86"; 
    "Android Platform Tools" = "87"; "Brave Android" = "88"; "Firefox Android" = "89"; "Adblock Browser Android" = "90"; 
    "AdGuard Content Blocker" = "91"; "Aura Suite" = "92"; "Firefox Focus" = "93"; "VoiceNote" = "94"; "Pink App" = "95"; 
    "Organdramatraiin" = "96"; "ToLink" = "97"; "NowLookM" = "98"; "Tigtog" = "99"; "Mannic APK" = "100"; 
    "Popcorn Time APK" = "101"; "VideoFlow Player" = "102"; "Bingo Shoppers" = "103"; "Cine Rader" = "104"; 
    "Denmolaryan" = "105"; "Vimo EditFilm" = "106"; "FansLike MovieInfo" = "107"; "MyCinely App" = "108"; 
    "FansLike MovieInfo (2)" = "109"; "LineageOS" = "110"; "CalyxOS" = "111"; "GrapheneOS" = "112"; "CopperheadOS" = "113"; 
    "MicroG GmsCore" = "114"; "AdBlock Pro iOS" = "115"; "AdGuard iOS" = "116"; "1Blocker" = "117"; "Brave iOS" = "118"; 
    "Hush Nag Blocker" = "119"; "Firefox Focus iOS" = "120"; "Firefox iOS" = "121"; "Aura iOS" = "122"; 
    "Kali Linux" = "123"; "Lubuntu" = "124"; "Arch Linux" = "125"; "Fedora" = "126"; "Red Hat" = "127"; "Debian" = "128"; 
    "Ventoy" = "129"; "Rufus" = "130"; "Technitium MAC" = "131"; "Quax" = "132"; "OnionShare" = "133"; 
    "2FA Authenticator" = "134"; "Microsoft Authenticator" = "135"; "Google Authenticator" = "136"; 
    "Yubico Authenticator" = "137"; "FreeOTP" = "138"; "Proton Authenticator" = "139"; "Authy" = "140"; 
    "Proton 2FA Android" = "141"; "Aegis 2FA" = "142"; "TwoFAS App" = "143"; "Authy Android" = "144"; 
    "Google Authenticator Android" = "145"; "Azure Authenticator" = "146"; "Yubico Auth Android" = "147"; 
    "Ente Auth" = "148"; "FreeOTP Android" = "149"
}

# === CATEGORY MAPPING ===
$categories = @{
    "Malware Analysis / Sandboxes" = @("Any.Run","Hybrid Analysis","IRIS-H","Intezer Analyze","Joe Sandbox","Manalyzer","Metadefender","Sandbox Pikker","Polyswarm","TY Labs Scan","Checkpoint ThreatPoint","SecondWrite Webportal")
    "File & URL Scanners" = @("Talos Intelligence","VirusTotal","Kaspersky OpenTip","Jotti","URLVoid","URLScan.io","Quttera","FileScan.io","VirScan.org","Sucuri SiteCheck","NordVPN File Checker","Dr.Web VMS","ScanMalware.com","Internxt Virus Scanner","DynamiteLab","VMRay","SecondWrite","MalShare","Acronis","EmailVeritas File Checker","Watchdog Online Scanner")
    "Antivirus / Security Software" = @("Kaspersky Free Antivirus","Bitdefender Free","Dr.Web CureIt!","HitmanPro")
    "VPN / DNS / Privacy Tools" = @("ProtonVPN","Mullvad","NordVPN","TunnelBear","Quad9 DNS","NextDNS","Cloudflare DNS","AdGuard DNS","ControlD DNS","NordVPN Private DNS","DNS.Watch","JoinDNS4")
    "Reverse Engineering / Debugging" = @("IDA Auth","dnSpy","ILSpy")
    "Browsers" = @("LibreWolf Browser","Brave Browser","Tor Browser","Mullvad Browser","Gnuzilla","Waterfox")
    "Browser Privacy Extensions" = @("AdNauseam","Privacy Badger","HTTPS Everywhere","uBlock Origin","Qwant (Chrome)","Qwant (Firefox)","Startpage (Chrome)","Startpage (Firefox)","JShelter","Cookie AutoDelete","LibRedirect Website","LibRedirect GitHub")
    "Messaging / Secure Comms" = @("Telegram","Nekogram","Signal","Threema","Session","Element","Briar","Simplex Chat")
    "Uninstallers / System Tools" = @("Revo Uninstaller","Geek Uninstaller","Uninstalr","Bulk Crap Uninstaller","FindMySoft","Uninstall Tool","Win11Debloat","Windows10Debloater")
    "Mobile Apps / Android / iOS" = @("Android Platform Tools","Brave Android","Firefox Android","Adblock Browser Android","AdGuard Content Blocker","Aura Suite","Firefox Focus","VoiceNote","Pink App","Organdramatraiin","ToLink","NowLookM","Tigtog","Mannic APK","Popcorn Time APK","VideoFlow Player","Bingo Shoppers","Cine Rader","Denmolaryan","Vimo EditFilm","FansLike MovieInfo","MyCinely App","FansLike MovieInfo (2)")
    "Mobile OS / Custom ROMs" = @("LineageOS","CalyxOS","GrapheneOS","CopperheadOS","MicroG GmsCore")
    "iOS Adblock Apps" = @("AdBlock Pro iOS","AdGuard iOS","1Blocker","Brave iOS","Hush Nag Blocker","Firefox Focus iOS","Firefox iOS","Aura iOS")
    "Linux / OS / Utilities" = @("Kali Linux","Lubuntu","Arch Linux","Fedora","Red Hat","Debian","Ventoy","Rufus","Technitium MAC","Quax","OnionShare")
    "Authenticator / 2FA Apps" = @("2FA Authenticator","Microsoft Authenticator","Google Authenticator","Yubico Authenticator","FreeOTP","Proton Authenticator","Authy","Proton 2FA Android","Aegis 2FA","TwoFAS App","Authy Android","Google Authenticator Android","Azure Authenticator","Yubico Auth Android","Ente Auth","FreeOTP Android")
}

# === SHOW CATEGORY MENU ===
function Show-CategoryMenu {
    Write-Host "`n=== Vaporware Toolkit Categories ===`n" -ForegroundColor Cyan
    $i = 1
    foreach ($cat in $categories.Keys) {
        Write-Host "$i. $cat"
        $i++
    }
    Write-Host "`n0. Exit`n"
}

# === SHOW TOOLS MENU ===
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

# === RUN MAIN MENU ===
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

# === MAIN ===
$config = Get-ConfigJson
if ($config) {
    Run-MainMenu -config $config
}
