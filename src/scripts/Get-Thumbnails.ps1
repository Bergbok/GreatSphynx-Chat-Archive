$channelInfoPath = Join-Path $PSScriptRoot '../videos.json'
$thumbnailPath = Join-Path $PSScriptRoot '../images/thumbnails'

if (-not (Test-Path $thumbnailPath)) { New-Item -ItemType Directory -Path $thumbnailPath | Out-Null }

$vodEntries = & jq '.vods_highlights_uploads | map({id, thumbnail_url})' $channelInfoPath | ConvertFrom-Json
$clipEntries = & jq '.clips | map({id, thumbnail_url})' $channelInfoPath | ConvertFrom-Json

$entries = $vodEntries + $clipEntries

foreach ($entry in $entries) {
    if ($entry.thumbnail_url -match '\.(\w+)$') {
        $fileExtension = $matches[1]
    }

    $thumbnailPath = Join-Path $thumbnailPath ($entry.id + '.' + $fileExtension)

    $thumbnailUrl = $entry.thumbnail_url -replace 'preview-480x272', 'preview-1280x720'
    $thumbnailUrl = $thumbnailUrl -replace '%{width}x%{height}', '1280x720'

    if (-not (Test-Path $thumbnailPath) -and !($thumbnailUrl -match 'vod-secure.twitch.tv\/_404\/404_processing')) {
        Write-Host "Downloading $thumbnailUrl"
        Invoke-WebRequest -Uri $thumbnailUrl -OutFile $thumbnailPath -UseBasicParsing
    }
}

Push-Location $thumbnailPath

Get-ChildItem | Where-Object {
    $_.Extension -ne '.avif' -and -not (Test-Path ([IO.Path]::ChangeExtension($_.Name, '.avif')))
} | ForEach-Object {
    ffmpeg -i $_.Name ([IO.Path]::ChangeExtension($_.Name, '.avif'))
}

Pop-Location
