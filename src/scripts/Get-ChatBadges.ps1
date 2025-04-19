# https://dev.twitch.tv/docs/api

$authToken = ''
$clientID = ''
$outputFile = Join-Path $PSScriptRoot '../badges.json'
$streamerUserID = '46531815' # GreatSphynx

if (-not (Test-Path ($outputDir = Split-Path $outputFile -Parent))) { New-Item -Path $outputDir -ItemType Directory | Out-Null }

$allBadges = @{
    global = @()
    channel = @()
}

$allBadges.global = Invoke-RestMethod -Uri 'https://api.twitch.tv/helix/chat/badges/global' -Method GET -Headers @{
    'Authorization' = "Bearer $authToken"
    'Client-Id' = $clientID
}
$allBadges.global = $allBadges.global.data

$allBadges.channel = Invoke-RestMethod -Uri "https://api.twitch.tv/helix/chat/badges?broadcaster_id=$streamerUserID" -Method GET -Headers @{
    'Authorization' = "Bearer $authToken"
    'Client-Id' = $clientID
}
$allBadges.channel = $allBadges.channel.data

$allBadges | ConvertTo-Json -Depth 5 | Out-File $outputFile -Encoding utf8
