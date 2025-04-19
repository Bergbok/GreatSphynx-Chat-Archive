function Format-Title {
    param (
        [string]$title,
        [string]$videoType,
        [string]$duration
    )

    function Get-DurationSeconds {
        param(
            [string]$duration
        )

        $total = 0

        if ($duration -match '(?<hours>\d+)h') { $total += [int]$matches['hours'] * 3600 }
        if ($duration -match '(?<minutes>\d+)m') { $total += [int]$matches['minutes'] * 60 }
        if ($duration -match '(?<seconds>\d+)s') { $total += [int]$matches['seconds'] }

        return $total
    }

    $titlesThatHadToBeShortened = @{
        '≡¥Ö£≡¥Öñ≡¥Öú≡¥Ö£≡¥Öñ ≡¥Öó≡¥Öû≡¥Ö« ≡¥Öù≡¥ÖÜ ≡¥Ö¥≡¥Öû≡¥Ö»≡¥Öû≡¥Öº≡¥ÖÖ≡¥Öñ≡¥Ö¬≡¥Ö¿ ≡¥Ö⌐≡¥Öñ ≡¥Ö«≡¥Öñ≡¥Ö¬≡¥Öº ≡¥Ö¥≡¥ÖÜ≡¥Öû≡¥Öí≡¥Ö⌐≡¥Ö¥' = '≡¥Ö'
    }

    if ($titlesThatHadToBeShortened.ContainsKey($title)) {
        $title = $titlesThatHadToBeShortened[$title]
    }

    if ($title.StartsWith('Clip: ')) {
        $title = '[Clip] ' + $title.Substring(6).Trim()
    }
    elseif ($videoType -eq 'clip') {
        $title = '[Clip] ' + $title
    }
    elseif (($videoType -eq 'highlight') -and ((Get-DurationSeconds $duration) -le 90)) {
        $title = '[Clip] ' + $title
    }

    $title = $title -replace 'Highlight:\s*', ''
    # https://stackoverflow.com/a/31976060
    $title = $title -replace ':', ([char]0xFF1A)    # ：
    $title = $title -replace '"', ([char]0xFF02)    # ＂'
    $title = $title -replace '/', ([char]0x29F8)    # ⧸
    $title = $title -replace '\?', ([char]0xFF1F)   # ？'
    $title = $title -replace '\*', ([char]0x2731)   # ✱'
    $title = $title -replace '\\', ([char]0x29F9)   # ⧹
    $title = $title -replace '\|', ([char]0xFF5C)   # ｜'
    $title = $title -replace '<', ([char]0xFE64)    # ﹤'
    $title = $title -replace '>', ([char]0xFF1E)    # ＞'

    return $title
}
