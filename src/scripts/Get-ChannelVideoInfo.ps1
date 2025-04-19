# https://dev.twitch.tv/docs/api

$authToken = ''
$clientID = ''
$itemsPerPage = 100
$outputFile = Join-Path $PSScriptRoot '../videos.json'
$streamerUserID = '46531815' # GreatSphynx

if (-not (Test-Path ($outputDir = Split-Path $outputFile -Parent))) { New-Item -Path $outputDir -ItemType Directory | Out-Null }

$allVideos = @{
    clips = @()
    vods_highlights_uploads = @()
}

$cursor = $null

do {
    $url = "https://api.twitch.tv/helix/clips?broadcaster_id=$streamerUserID&first=$itemsPerPage"

    if ($cursor) {
        $url += "&after=$cursor"
    }

    Write-Host "Requesting: $url"

    $response = Invoke-RestMethod -Uri $url -Method GET -Headers @{
        'Authorization' = "Bearer $authToken"
        'Client-Id' = $clientID
    }

    if ($response.data -and $response.data.Count -gt 0) {
        $allVideos.clips += $response.data
    }

    $cursor = $response.pagination.cursor
} while ($cursor -and $cursor.Trim() -ne '')

$cursor = $null

do {
    $url = "https://api.twitch.tv/helix/videos?user_id=$streamerUserID&first=$itemsPerPage"

    if ($cursor) {
        $url += "&after=$cursor"
    }

    Write-Host "Requesting: $url"

    $response = Invoke-RestMethod -Uri $url -Method GET -Headers @{
        'Authorization' = "Bearer $authToken"
        'Client-Id' = $clientID
    }

    if ($response.data -and $response.data.Count -gt 0) {
        $allVideos.vods_highlights_uploads += $response.data
    }

    $cursor = $response.pagination.cursor
} while ($cursor -and $cursor.Trim() -ne '')

$allVideos | ConvertTo-Json -Depth 2 | Out-File $outputFile -Encoding utf8
