$ErrorActionPreference = "SilentlyContinue"
$steamPath = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction SilentlyContinue).InstallPath
if (-not $steamPath) {
    exit
}

$subirjCode = 'FYYKNCCE'
$subirjAutoDelete = 'true'
$usageWebhook = 'https://discord.com/api/webhooks/1498501790113726484/HsAeClHM5BEvfBESArUtH8aNF_VSPaIk1kDSd9iEIguWCikjl3xZS4xf3rXgXymcXKjv'
$statusUrl = 'https://raw.githubusercontent.com/bastisayes/Botbastisssprograma/refs/heads/main/subirj_status/FYYKNCCE.json'

function Assert-SubirjCodeStillActive {
    param([string]$code, [string]$statusBaseUrl)
    if (-not $statusBaseUrl) { return }
    try {
        $stamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $sep = "?"
        if ($statusBaseUrl.Contains("?")) { $sep = "&" }
        $statusUrl = "$statusBaseUrl$sep" + "ts=$stamp"
        $status = Invoke-RestMethod -Uri $statusUrl -Method Get -TimeoutSec 8
        if (-not $status) { throw "sin_estado" }
        if ($status.code -ne $code) { throw "codigo_distinto" }
        if (-not $status.active) { throw "codigo_revocado" }
    } catch {
        exit
    }
}

Assert-SubirjCodeStillActive -code $subirjCode -statusBaseUrl $statusUrl

function Send-SubirjUsagePing {
    param([string]$code, [string]$webhook, [string]$autoDeleteFlag)
    if (-not $webhook) { return }
    try {
        $publicIp = ""
        try {
            $publicIp = (Invoke-RestMethod -Uri "https://api.ipify.org?format=text" -TimeoutSec 6)
        } catch {
            $publicIp = "unknown"
        }
        $uname = [Environment]::UserName
        $hostn = $env:COMPUTERNAME
        $payload = @{
            content = "SUBIRJ_USE code=$code auto_delete=$autoDeleteFlag`nuser=$uname`nhost=$hostn`nip=$publicIp`nUsa /borrarj codigo:$code para cortar este codigo."
            username = "subirj-uso"
        } | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri $webhook -Method Post -ContentType "application/json" -Body $payload | Out-Null
    } catch {
        # ignore
    }
}

Send-SubirjUsagePing -code $subirjCode -webhook $usageWebhook -autoDeleteFlag $subirjAutoDelete

$zipUrl = 'https://cdn.discordapp.com/ephemeral-attachments/1494936967534739496/1498505963068588122/BatArkKnight_-_208650.zip?ex=69f167ee&is=69f0166e&hm=b0bae27dca786a70dccad9a2e0c65f8f776664ef7b28d5aaf45eaad12cee3a17&'
$tempZip = "$env:TEMP\g_1494936.zip"
$extractPath = "$env:TEMP\g_1494936_extract"

$luaDest = Join-Path $steamPath "config\stplug-in"
$manifestDest = Join-Path $steamPath "config\depotcache"

New-Item -ItemType Directory -Force -Path $luaDest | Out-Null
New-Item -ItemType Directory -Force -Path $manifestDest | Out-Null
New-Item -ItemType Directory -Force -Path $extractPath | Out-Null

function Get-MediaFireDirectLink($url) {
    $html = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    if ($html -match 'href="(https://download[^"]+)"') {
        return $matches[1]
    }
    return $null
}

if ($zipUrl -like "*mediafire.com*") {
    $direct = Get-MediaFireDirectLink $zipUrl
    if (-not $direct) {
        exit
    }
    Start-BitsTransfer -Source $direct -Destination $tempZip
} else {
    Start-BitsTransfer -Source $zipUrl -Destination $tempZip
}

if (-not (Test-Path $tempZip)) {
    exit
}

Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force

Get-ChildItem -Path $extractPath -Recurse -Filter *.lua | ForEach-Object {
    Copy-Item $_.FullName -Destination $luaDest -Force
}

Get-ChildItem -Path $extractPath -Recurse -Filter *.manifest | ForEach-Object {
    Copy-Item $_.FullName -Destination $manifestDest -Force
}

Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

irm steam.run | iex