. "$PSScriptRoot/Format-Title.ps1"

$channelInfoPath = Join-Path $PSScriptRoot '../videos.json'
$jsonPath = Join-Path $PSScriptRoot '../../chat-json'
$htmlPath = Join-Path $PSScriptRoot '../html'

if (-not (Test-Path ($jsonClipChatPath = Join-Path $jsonPath 'clips'))) { New-Item -ItemType Directory -Path $jsonClipChatPath | Out-Null }
if (-not (Test-Path ($htmlClipChatPath = Join-Path $htmlPath 'clips'))) { New-Item -ItemType Directory -Path $htmlClipChatPath | Out-Null }

function Invoke-Exiting {
    $chatFiles = Get-ChildItem -Path "$jsonPath/*" -Recurse -Include *.json, *.json.gz
    $chatFiles += Get-ChildItem -Path "$htmlPath/*" -Recurse -Include *.html
    foreach ($file in $chatFiles) {
        if ($file.Length -eq 0) {
            Write-Host "`nDeleting empty file: $($file.FullName)"
            [IO.File]::Delete($file.FullName)
        }
    }
}

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Invoke-Exiting } | Out-Null

$vodEntries = & jq '.vods_highlights_uploads | map({id, title, created_at, video_type: .type, duration})' $channelInfoPath | ConvertFrom-Json
$clipEntries = & jq '.clips | map({id, title, created_at, video_type: \"clip\", duration, creator_name})' $channelInfoPath | ConvertFrom-Json

$entries = $vodEntries + $clipEntries

foreach ($entry in $entries) {
    $title = Format-Title $entry.title $entry.video_type $entry.duration
    $yyyymmdd = $entry.created_at.Substring(0, 10)
    $outputFileName = "[$($entry.id)] [$yyyymmdd] $("[$($entry.creator_name)] " -replace '^\[\] $', '')$title" -replace '\s*$', ''

    if ($outputFileName -match ' \[Clip\] ') {
        $outputFileName = $outputFileName -replace ' \[Clip\] ', ' '
        $jsonPath = Join-Path (Join-Path $jsonPath 'clips') ($outputFileName + '.json')
        $htmlPath = Join-Path (Join-Path $htmlPath 'clips') ($outputFileName + '.html')
    }
    else {
        $jsonPath = Join-Path $jsonPath ($outputFileName + '.json')
        $htmlPath = Join-Path $htmlPath ($outputFileName + '.html')
    }

    Write-Host "Downloading chat for $outputFileName"

    # https://github.com/lay295/TwitchDownloader/blob/master/TwitchDownloaderCLI/README.md
    twitchdownloadercli chatdownload --id $entry.id --embed-images --bttv=true --ffz=true --stv=true --banner=false --collision=Exit --compression=Gzip --output $jsonPath
    twitchdownloadercli chatupdate --input ($jsonPath + '.gz') --bttv=true --ffz=true --stv=true --banner=false --collision=Exit --output $htmlPath
}
