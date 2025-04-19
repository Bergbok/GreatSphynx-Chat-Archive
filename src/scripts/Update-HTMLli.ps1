$htmlPath = Join-Path $PSScriptRoot '../html'
$clipsHtmlPath = Join-Path $htmlPath 'clips'
$indexHtmlPath = Join-Path $PSScriptRoot '../../index.html'
$thumbnailPath = Join-Path $PSScriptRoot '../images/thumbnails'

if (-not (Test-Path $htmlPath)) { New-Item -ItemType Directory $htmlPath }
if (-not (Test-Path $thumbnailPath)) { New-Item -ItemType Directory $thumbnailPath }

function Get-VideoThumbnail {
    param (
        [string]$filename
    )

    $videoID = $filename -replace '^\[([\w-_]+)\].*$', '$1'

    $thumbnail = (Get-ChildItem -Path $thumbnailPath -Filter "$videoID.*" -File -Recurse | Select-Object -First 1).Name

    if (-not $thumbnail) {
        $thumbnail = 'default.avif'
    }

    return $thumbnail
}

function Get-Title {
    param (
        [string]$filename
    )

    $filenamesThatHadToBeShortened = @{
        '[1852479282] [2023-06-22] ≡¥Ö' = '[1852479282] [2023-06-22] ≡¥Ö£≡¥Öñ≡¥Öú≡¥Ö£≡¥Öñ ≡¥Öó≡¥Öû≡¥Ö« ≡¥Öù≡¥ÖÜ ≡¥Ö¥≡¥Öû≡¥Ö»≡¥Öû≡¥Öº≡¥ÖÖ≡¥Öñ≡¥Ö¬≡¥Ö¿ ≡¥Ö⌐≡¥Öñ ≡¥Ö«≡¥Öñ≡¥Ö¬≡¥Öº ≡¥Ö¥≡¥ÖÜ≡¥Öû≡¥Öí≡¥Ö⌐≡¥Ö¥'
    }

    if ($filenamesThatHadToBeShortened.ContainsKey($filename)) {
        return $filenamesThatHadToBeShortened[$filename]
    }

    return $filename
}

function Format-URL {
    param (
        [string]$url
    )

    $containsSingle = $url -match "'"
    $containsDouble = $url -match '"'

    if ($containsSingle -and -not $containsDouble) {
        return "`"$url`""
    }
    elseif ($containsDouble -and -not $containsSingle) {
        return "'$url'"
    }
    elseif ($containsSingle -and $containsDouble) {
        return "'$($url -replace "'", "&apos;" -replace '"', "&quot;")'"
    }
    else {
        return "'$url'"
    }
}

function Get-ListItems {
    param(
        [string]$TargetPath
    )

    $files = Get-ChildItem $TargetPath -Filter *.html

    $sortedFiles = $files | Sort-Object {
        if ($_.BaseName -match '\b(\d{4}-\d{2}-\d{2})\b') {
            # Parse the date extracted from the filename
            [datetime]::ParseExact($matches[1], 'yyyy-MM-dd', $null)
        }
        else {
            [datetime]::MinValue
        }
    } -Descending

    return $sortedFiles | ForEach-Object {
        $fileName  = $_.Name
        $thumbnail = Get-VideoThumbnail $fileName
        return "`t`t`t`t<li><a href=$(Format-URL "/$fileName")><img src='/thumbnails/$thumbnail' alt='thumbnail' class='tn'/><span class='vt'>$(Get-Title $_.BaseName)</span></a></li>"
    } | Out-String
}

$liVods = Get-ListItems -TargetPath $htmlPath
$liClips = Get-ListItems -TargetPath $clipsHtmlPath

$content = Get-Content -LiteralPath $indexHtmlPath -Raw

$content = $content -replace "(?s)(<ul class='video-group' id='vods-highlights-uploads-list'>).*?(</ul>)", ('$1' + "`n`t`t`t`t" + $liVods.Trim() + "`n`t`t`t" + '$2')
$content = $content -replace "(?s)(<ul class='video-group' id='clips-list'>).*?(</ul>)", ('$1' + "`n`t`t`t`t" + $liClips.Trim() + "`n`t`t`t" + '$2')
$content = $content -replace '    ', "`t"

Set-Content -LiteralPath $indexHtmlPath -Value $content -Encoding utf8

Write-Host "index.html updated successfully." -ForegroundColor Green
