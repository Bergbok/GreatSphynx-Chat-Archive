. "$PSScriptRoot/Format-Title.ps1"

$channelInfoPath = Join-Path $PSScriptRoot '../videos.json'
$clipsPath = Join-Path $PSScriptRoot '../videos/clips'
$videoPath = Join-Path $PSScriptRoot '../videos'

if (-not (Test-Path $clipsPath)) { New-Item -ItemType Directory -Path $clipsPath | Out-Null }

function Invoke-Exiting {
    $videoFiles = Get-ChildItem -Path "$videoPath\*" -Recurse -Include *.mp4
    foreach ($file in $videoFiles) {
        if ($file.Length -eq 0) {
            Write-Host "`nDeleting empty file: $($file.FullName)"
            [IO.File]::Delete($file.FullName)
        }
    }
}

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Invoke-Exiting } | Out-Null

$vodEntries = & jq '.vods_highlights_uploads | map({id, title, created_at, video_type: .type, duration})' $channelInfoPath | ConvertFrom-Json
# $clipEntries = & jq '.clips | map({id, title, created_at, video_type: "clip", duration, creator_name})' $channelInfoPath | ConvertFrom-Json

$entries = ($vodEntries + $clipEntries) | Where-Object { $_ -and $_.created_at }

foreach ($entry in $entries) {
    Write-Host "Downloading video for $outputFileName" -ForegroundColor Green

    $title = Format-Title $entry.title $entry.video_type $entry.duration
    $yyyymmdd = $entry.created_at.ToString("yyyy-MM-dd")
    $outputFileName = "[$($entry.id)] [$yyyymmdd] $("[$($entry.creator_name)] " -replace '^\[\] $', '')$title"

    if ($outputFileName -match  '\[Clip\] ') {
        $outputFileName = $outputFileName -replace ' \[Clip\] ', ' '
        $videoPath = Join-Path $clipsPath ($outputFileName + '.mp4')
        twitchdownloadercli clipdownload --id $entry.id --output $videoPath --banner=false --collision=Exit
    }
    else {
        $videoPath = Join-Path $videoPath ($outputFileName + '.mp4')
        twitchdownloadercli videodownload --id $entry.id --output=$videoPath --banner=false --collision=Exit
    }

    Write-Host "`n"
}
