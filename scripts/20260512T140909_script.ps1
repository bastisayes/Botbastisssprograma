Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$games = @{}

function Get-MediaFireGames {
    $url = "https://www.mediafire.com/api/1.5/folder/get_content.php?folder_key=3o9127pseyx49&content_type=files&response_format=json"
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        $data = $response.Content | ConvertFrom-Json
        $files = $data.response.folder_content.files
        foreach ($f in $files) {
            $name = $f.filename -replace '\.zip$', ''
            $games[$name] = @{
                url = $f.links.normal_download
                size = [math]::Round($f.size / 1MB, 2)
                filename = $f.filename
            }
        }
        return $true
    } catch {
        return $false
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Game Fix Downloader"
$form.Size = New-Object System.Drawing.Size(500, 350)
$form.StartPosition = "CenterScreen"
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Command powershell).Source)
$label = New-Object System.Windows.Forms.Label
$label.Text = "Select Game:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(100, 25)
$combo = New-Object System.Windows.Forms.ComboBox
$combo.Location = New-Object System.Drawing.Point(130, 17)
$combo.Size = New-Object System.Drawing.Size(330, 25)
$combo.DropDownStyle = "DropDownList"

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Loading games..."
$statusLabel.Location = New-Object System.Drawing.Point(20, 55)
$statusLabel.Size = New-Object System.Drawing.Size(440, 25)
$statusLabel.ForeColor = "Blue"

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 90)
$progressBar.Size = New-Object System.Drawing.Size(440, 25)
$progressBar.Style = "Continuous"
$progressBar.Visible = $false

$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text = "Download & Extract"
$btnDownload.Location = New-Object System.Drawing.Point(150, 130)
$btnDownload.Size = New-Object System.Drawing.Size(180, 35)
$btnDownload.Enabled = $false

$form.Controls.Add($label)
$form.Controls.Add($combo)
$form.Controls.Add($statusLabel)
$form.Controls.Add($progressBar)
$form.Controls.Add($btnDownload)
$combo.Add_SelectedIndexChanged({
    $btnDownload.Enabled = $true
})

function Start-DownloadExtract {
    $selected = $combo.SelectedItem
    if (-not $selected) { return }

    $gameInfo = $games[$selected]
    if (-not $gameInfo) { return }

    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select destination folder for $selected"
    $folderDialog.ShowNewFolderButton = $true

    if ($folderDialog.ShowDialog() -ne "OK") { return }

    $destPath = $folderDialog.SelectedPath
    $tempFile = Join-Path $env:TEMP $gameInfo.filename

    $btnDownload.Enabled = $false
    $combo.Enabled = $false
    $progressBar.Visible = $true
    $progressBar.Value = 0

    $statusLabel.Text = "Downloading..."
    $statusLabel.ForeColor = "DarkOrange"
    $form.Refresh()

    try {
        $webClient = New-Object System.Net.WebClient

        $webClient.DownloadFileAsync((New-Object System.Uri($gameInfo.url)), $tempFile)

        while ($webClient.IsBusy) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }

        $progressBar.Value = 50
        $statusLabel.Text = "Extracting to: $destPath (overwriting...)"
        $statusLabel.ForeColor = "Green"
        $form.Refresh()

        if (Test-Path $tempFile) {
            Expand-Archive -Path $tempFile -DestinationPath $destPath -Force
            Remove-Item -Path $tempFile -Force
            $progressBar.Value = 100
            $statusLabel.Text = "Done! $selected installed successfully."
            $statusLabel.ForeColor = "Green"
        }
    } catch {
        $statusLabel.Text = "Error: $_"
        $statusLabel.ForeColor = "Red"
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
    }

    $btnDownload.Enabled = $true
    $combo.Enabled = $true
}

$btnDownload.Add_Click({ Start-DownloadExtract })
$form.Add_Shown({
    $form.Update()
$ok = Get-MediaFireGames
    if ($ok) {
        $sorted = $games.Keys | Sort-Object
        $combo.Items.AddRange($sorted)
$statusLabel.Text = "$($sorted.Count) games loaded."
        $statusLabel.ForeColor = "Green"
    } else {
        $statusLabel.Text = "Failed to load games. Check internet."
        $statusLabel.ForeColor = "Red"
    }
})

[void]$form.ShowDialog()
