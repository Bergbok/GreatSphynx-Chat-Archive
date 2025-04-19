$imagePath = Join-Path $PSScriptRoot '../images'
$badgePath = Join-Path $imagePath 'badges'
$emotePath = Join-Path $imagePath 'emotes'
$twitchEmotePath = Join-Path $emotePath 'twitch'
$thirdPartyEmotePath = Join-Path $emotePath '3rd-party'
$bttvEmotePath = Join-Path $thirdPartyEmotePath 'bttv'
$ffzEmotePath = Join-Path $thirdPartyEmotePath 'ffz'
$7tvEmotePath = Join-Path $thirdPartyEmotePath '7tv'
$imagesCssPath = Join-Path $PSScriptRoot '../styles/images.css'

$badgePath, $twitchEmotePath, $bttvEmotePath, $ffzEmotePath, $7tvEmotePath | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ | Out-Null }
}

$imagesCss = Get-Content $imagesCssPath -Raw

[regex]::Matches($imagesCss, '\.[\w-]+\s*\{\s*content:url\("(?<url>https?://[^"]+)"\)\s*;') | ForEach-Object {
    $match = $_
    $url   = $match.Groups['url'].Value

    switch -Regex ($url) {
        'static-cdn\.jtvnw\.net.*\/badges\/.*\/(?<id>[a-z0-9-]+)\/\d$' {
            $imagePlatform = 'Twitch'
            $imageID = $matches['id']
            $destFolder = $badgePath
        }
        'static-cdn\.jtvnw\.net.*\/emoticons\/v2\/(?<id>[\w]+)\/default\/dark\/\d.0$' {
            $imagePlatform = 'Twitch'
            $imageID = $matches['id']
            $destFolder = $twitchEmotePath
        }
        'betterttv\.net.*\/(?<id>[a-z0-9]+)\/2x\.webp$' {
            $imagePlatform = 'BTTV'
            $imageID = $matches['id']
            $destFolder = $bttvEmotePath
        }
        'frankerfacez\.com.*\/(?<id>[0-9]+)\/\d$' {
            $imagePlatform = 'FFZ'
            $imageID = $matches['id']
            $destFolder = $ffzEmotePath
        }
        '7tv\.app.*\/(?<id>[A-Z0-9]+)\/\dx\.avif$' {
            $imagePlatform = '7TV'
            $imageID = $matches['id']
            $destFolder = $7tvEmotePath
        }
        default {
            throw "Unrecognized URL: $url"
        }
    }

    if (-not (Test-Path (Join-Path $destFolder ($imageID + '.*')))) {
        Write-Host "Downloading $imagePlatform image ($imageID)" -ForegroundColor Green
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -Method Head
        $contentType = $response.Headers['Content-Type']
        $extension = switch ($contentType) {
            'image/gif'  { '.gif' }
            'image/png'  { '.png' }
            'image/jpeg' { '.jpg' }
            'image/webp' { '.webp' }
            'image/avif' { '.avif' }
            default {
                '.unknown'
            }
        }
        $outPath = Join-Path $destFolder ($imageID + $extension)
        Invoke-WebRequest -Uri $url -OutFile $outPath -UseBasicParsing
    }
    else {
        Write-Host "Skipping $imagePlatform image ($imageID)" -ForegroundColor DarkGray
    }
}

Get-ChildItem $imagePath -Filter *.unknown -Recurse | ForEach-Object {
    $imageData = Get-Content $_.FullName -Raw

    if ($imageData -match '.(\w+)\s') {
        $newFileExtension = ".$($matches[1].ToLower())"
        Write-Host "Changing $($_.Name) to $newFileExtension" -ForegroundColor Green
        Rename-Item -Path $_.FullName -NewName ($_.BaseName + $newFileExtension) -Force
    }
    else {
        Write-Error "Couldn't determine file type for $($_.Name)"
    }
}

Push-Location $emotePath

Get-ChildItem -Directory -Recurse | ForEach-Object {
    Push-Location $_.FullName

    Get-ChildItem -File | Where-Object {
        $o = [IO.Path]::ChangeExtension($_.Name, '.avif')
        $_.Extension -ne '.avif' -and -not (Test-Path $o)
    } | ForEach-Object {
        if ($_.Extension -eq '.webp') {
            $i = 'frame_%04d.png'
            magick $_.Name -coalesce $i

            $delays = magick identify -format "%s:%T`n" $_.Name

            $fileList = @()
            $lastIdx  = 0

            foreach ($line in $delays -split "`n") {
                $parts = $line -split ':'
                $idx   = [int]$parts[0]
                $delay = ([int]$parts[1]) / 100.0

                $fileList += "file 'frame_{0:D4}.png'" -f $idx
                $fileList += "duration $delay"
                $lastIdx = $idx
            }

            $fileList += "file 'frame_{0:D4}.png'" -f $lastIdx

            $fileList | Set-Content filelist.txt

            ffmpeg -f concat -i filelist.txt -c:v libaom-av1 -map 0 -map 0 -filter:0 'format=yuv420p' -filter:1 'format=yuva444p,alphaextract' -cpu-used 0 -b:v 0 -crf 21 -r 60 $o

            Remove-Item frame_*.png, filelist.txt
        }
        else {
            ffmpeg -i $_.Name -map 0 -map 0 -filter:0 'format=yuv420p' -filter:1 'format=yuva444p,alphaextract' -crf 21 $o
        }

        if ((Get-Item $o).Length -eq 0) {
            Write-Error "`n$o is empty, deleting..."
            Remove-Item $o
        }
    }

    Pop-Location
}

Pop-Location
