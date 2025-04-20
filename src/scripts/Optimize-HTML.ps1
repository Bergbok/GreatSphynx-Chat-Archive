$badgeInfoPath = Join-Path $PSScriptRoot '../badges.json'
$htmlPath = Join-Path $PSScriptRoot '../html'
$imagesCssPath = Join-Path $PSScriptRoot '../styles/images.css'
$userColorsCssPath = Join-Path $PSScriptRoot '../styles/username-colors.css'
$thirdPartyEmotePath = Join-Path $PSScriptRoot '../images/emotes/3rd-party'
$twitchDownloaderTemp = Join-Path $env:TEMP 'TwitchDownloader'

if (-not (Test-Path $htmlPath)) { New-Item -ItemType Directory $htmlPath }
if (-not (Test-Path $imagesCssPath)) { Set-Content $imagesCssPath -Value '' -Encoding utf8 }
if (-not (Test-Path $userColorsCssPath)) { Set-Content $userColorsCssPath -Value '' -Encoding utf8 }

$imagesCss = Get-Content $imagesCssPath -Raw
$userColorsCss = Get-Content $userColorsCssPath -Raw

$processedFileCount = 0
$reductions = @()

function Get-BadgeURL {
    param (
        [string]$setID,
        [string]$version
    )

    if ($setID -eq 'subscriber') {
        $array = 'channel'
    } else {
        $array = 'global'
    }

    $versions = & jq ".${array} | map(select(.set_id == `"$setID`")) | .[0].versions" $badgeInfoPath | ConvertFrom-Json

    $requestedVersion = [int]($version -replace '[^0-9]', '')

    $available = $versions | Where-Object { [int]($_.id -replace '[^0-9]', '') -le $requestedVersion }
    if ($available) {
        $fallback = $available | Sort-Object { [int]($_.id -replace '[^0-9]', '') } -Descending | Select-Object -First 1
        return $fallback.image_url_2x
    }
    else {
        throw "Version $version or less for set ID $setID couldn't be found."
    }
}

Get-ChildItem $htmlPath -Filter *.html -Recurse -File | ForEach-Object {
    Write-Host "Optimizing $($_.Name)" -ForegroundColor Green
    $startingSize = (Get-Item -LiteralPath $_.FullName).Length
    $content = Get-Content -LiteralPath $_.FullName -Raw

    $content = $content -replace '(?s)(<title>\s*)(?:\[.*?\]\s*)+(?<title>.*?)<\/title>', {
        $title = ($_.Groups['title'].Value -replace '\r?\n', '').Trim()
        return "<title>$title</title>"
    }

    $content = $content -replace '\.first-(?<emoteID>[\w\d_]+)\s*\{\s*content:url\("data:image/png;base64,\s[^"]+"\);\s*\}', {
        $emoteID = $_.Groups['emoteID'].Value
        return ".first-$emoteID { content:url(`"https://static-cdn.jtvnw.net/emoticons/v2/$emoteID/default/dark/2.0`"); }"
    }

    $content = $content -replace '\.badge-(?<set>[\w\d_-]+)-(?<version>\d+)\s*\{\s*content:url\("data:image\/png;base64,[^"]+"\);\s*\}', {
        $badgeSet = $_.Groups['set'].Value
        $badgeVersion = $_.Groups['version'].Value

        if ($badgeSet -match '^predictions') {
            $badgeVersion = "$($badgeSet.Split('-')[1])-$badgeVersion"
            $badgeSet = $badgeSet.Split('-')[0]
        }

        return ".badge-$badgeSet-$badgeVersion { content:url(`"$(Get-BadgeURL $badgeSet $badgeVersion)`"); }"
    }

    $content = $content -replace '\.third-(?<emoteID>[\w\d_]+)\s*\{\s*content:url\("data:image/png;base64,\s[^"]+"\);\s*\}', {
        $emoteID = $_.Groups['emoteID'].Value
        $emoteFile = Get-ChildItem -Recurse $thirdPartyEmotePath "$($emoteID).*" -File | Select-Object -First 1

        if (-not $emoteFile) {
            $emoteFile = Get-ChildItem -Recurse $twitchDownloaderTemp "$($emoteID)_2.*" -File | Where-Object { $_.Name -match '(\\|\/)(bttv|emotes|ffz|stv)(\\|\/)' } | Select-Object -First 1
            if (-not $emoteFile) {
                throw "Emote file not found for ID: $emoteID"
            }
        }

        $emotePlatform = Split-Path (Split-Path $emoteFile.FullName -Parent) -Leaf

        switch ($emotePlatform) {
            'bttv' { $emoteURL = "https://cdn.betterttv.net/emote/$emoteID/2x.webp" }
            'ffz'  { $emoteURL = "https://cdn.frankerfacez.com/emoticon/$emoteID/2" }
            '7tv'  { $emoteURL = "https://cdn.7tv.app/emote/$emoteID/2x.avif" }
            default { throw "Detected unrecognized emoteplatform ($emotePlatform) for $emoteID" }
        }

        return ".third-$emoteID { content:url(`"$emoteURL`"); }"
    }

    $content = $content -replace '(?s)\/\*!\s*\* Bootstrap.*white-space: pre-wrap;\s*\}\s*', ''

    if ($content -match '(?s)<style>(.*?)<\/style>') {
        $styleContent = $matches[1]
        $rules = $styleContent -split '}' | Where-Object { $_.Trim() -ne '' }

        foreach ($rule in $rules) {
            $rule = $rule.Trim() + ' }'
            if ($imagesCss -notmatch [regex]::Escape($rule)) {
                $imagesCss += "`n$rule"
            }
        }
    }

    $content = $content -replace '"', "'"
    $content = $content -replace '(?m)^\s*$[\r\n]+', ''
    $content = $content -replace '(?m)^\s+|\s+$', ''
    $content = $content -replace '(?s)<script>.*?<\/script>\s*', ''
    $content = $content -replace '(?s)<style>.*?<\/style>\s*', ''
    $content = $content -replace '\bbadge-image\b', 'bi'
    $content = $content -replace '\bcomment-author\b', 'ca'
    $content = $content -replace '\bcomment-root\b', 'cr'
    $content = $content -replace '\bemote-image\b', 'ei'
    $content = $content -replace '\btext-hide\b', 'th'
    $content = $content -replace '<\/span> <\/span>', '</span></span>'
    $content = $content -replace "<base target='_blank'>\s*", ''
    $content = $content -replace "<link href='https:\/\/fonts\.googleapis\.com\/css\?family=Inter' rel='stylesheet'>", '<!-- links -->'
    $content = $content -replace "<span class='ca' >", "<span class='ca'>"
    $content = $content -replace "<span class='comment-message'>", '<span>'
    $content = $content -replace "comment-author' >", "comment-author'>"
    $content = $content -replace "title='<3'><span class='th'><3", "title='&lt;3'><span class='th'>&lt;3"

    # removed emotes:
    $content = $content -replace 'v2\/811237\/default', 'v2/1753160/default' # limesLurk
    $content = $content -replace 'v2\/811246\/default', 'v2/305153302/default' # limesLove
    $content = $content -replace 'v2\/1540702\/default', 'v2/305153297/default' # limesHi
    $content = $content -replace 'v2\/1413957\/default', 'v2/305153404/default' # limesBlank
    $content = $content -replace 'v2\/811243\/default', 'v2/emotesv2_b6981918c6e742099945a65d9f37756c/default' # limesRIP
    $content = $content -replace 'v2\/777644\/default', 'v2/emotesv2_3cbc64fe47d84f93902c3be91d9381e1/default' # limesWot
    $content = $content -replace 'v2\/1538829\/default', 'v2/emotesv2_e9a52a2160f5486c82eb4b6c900144f2/default' # limesNO
    $content = $content -replace 'v2\/1538825\/default', 'v2/emotesv2_de2f0898f71341fa9ca6afa2187db703/default' # limesNani
    $content = $content -replace 'v2\/1454637\/default', 'v2/emotesv2_80021a1327854061993e498557880d72/default' # limesEZ
    $content = $content -replace 'https:\/\/static-cdn\.jtvnw\.net\/emoticons\/v2\/86\/default\/dark\/1\.0', '/emotes/twitch/86.avif' # PogChamp
    $content = $content -replace 'https:\/\/static-cdn\.jtvnw\.net\/emoticons\/v2\/88\/default\/dark\/1\.0', '/emotes/twitch/88.avif' # BibleThump
    $content = $content -replace 'https:\/\/static-cdn\.jtvnw\.net\/emoticons\/v2\/1610298\/default\/dark\/1\.0', 'https://cdn.frankerfacez.com/emote/354747/2' # greats8Crust
    $content = $content -replace 'https:\/\/static-cdn\.jtvnw\.net\/emoticons\/v2\/1610073\/default\/dark\/1\.0', 'https://cdn.frankerfacez.com/emoticon/354746/2' # greats8S

    $content = $content.TrimEnd()

    $content = $content -replace "span class='ca' style='color: #(?<color>[A-Z0-9]{6})'", {
        $hex = $_.Groups['color'].Value
        $class = "c$hex"
        $rule = ".$class { color: #$hex; }"
        if ($userColorsCss -notmatch [regex]::Escape($rule)) {
            $userColorsCss += "`n$rule"
        }
        return "span class='ca $class'"
    }

    Set-Content -LiteralPath $_.FullName -Value $content -Encoding utf8

    $newSize = (Get-Item -LiteralPath $_.FullName).Length
    $reduction = $startingSize - $newSize
    $reductions += $reduction
    Write-Host "Reduced size by $([math]::Round(($reduction)/1024/1024, 2)) MB"
    $processedFileCount++
}

Set-Content $imagesCssPath -Value $imagesCss.Trim() -Encoding utf8
Set-Content $userColorsCssPath -Value $userColorsCss.Trim() -Encoding utf8

$avgReduction = ($reductions | Measure-Object -Average).Average
$maxReduction = ($reductions | Measure-Object -Maximum).Maximum
$totalReduction = ($reductions | Measure-Object -Sum).Sum

Write-Host '---------------------------------' -ForegroundColor Green
Write-Host "Processed $processedFileCount files."
Write-Host "Total reduction: $([math]::Round($totalReduction/1024/1024, 2)) MB"
Write-Host "Average reduction per file: $([math]::Round($avgReduction/1024/1024, 2)) MB"
Write-Host "Maximum reduction: $([math]::Round($maxReduction/1024/1024, 2)) MB"
Write-Host '---------------------------------' -ForegroundColor Green
