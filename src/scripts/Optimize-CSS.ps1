$htmlPath = Join-Path $PSScriptRoot '../html'
$imagesCssPath = Join-Path $PSScriptRoot '../styles/images.css'
$userColorsCssPath = Join-Path $PSScriptRoot '../styles/username-colors.css'

if (-not (Test-Path $htmlPath)) { New-Item -ItemType Directory $htmlPath }
if (-not (Test-Path $imagesCssPath)) { Set-Content $imagesCssPath -Value '' -Encoding utf8 }
if (-not (Test-Path $userColorsCssPath)) { Set-Content $userColorsCssPath -Value '' -Encoding utf8 }

$imagesCss = Get-Content $imagesCssPath -Raw
$userColorsCss = Get-Content $userColorsCssPath -Raw

function Format-Base62Fixed3 {
    param(
        [int]$n
    )

    $firstChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $restChars  = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

    $div = 62 * 62

    $i0 = [math]::Floor($n / $div)
    if ($i0 -ge $firstChars.Length) {
        throw "Number $n too large (max is $($firstChars.Length * $div - 1))."
    }

    $rem = $n % $div
    $i1  = [math]::Floor($rem / 62)
    $i2  =  $rem % 62

    return '{0}{1}{2}' -f $firstChars[$i0], $restChars[$i1], $restChars[$i2]
}

Write-Host 'Generating class mapping...' -ForegroundColor Green

$mappingBlacklist = @(
    'amp'
    'and'
    'ang'
    'btn'
    'cap'
    'chi'
    'Chi'
    'col'
    'css'
    'cup'
    'deg'
    'dot'
    'eng'
    'ENG'
    'eta'
    'Eta'
    'eth'
    'int'
    'loz'
    'nav'
    'not'
    'phi'
    'Phi'
    'piv'
    'psi'
    'Psi'
    'reg'
    'rho'
    'row'
    'shy'
    'sim'
    'sub'
    'sum'
    'sup'
    'Tab'
    'tau'
    'Tau'
    'uml'
    'yen'
)
$mappingOffset = 0

$mapping = @{}

Select-String -InputObject $imagesCss -Pattern '\.(?<classname>[\w-_]+) \{' -AllMatches | ForEach-Object {
    foreach ($match in $_.Matches) {
        $original = $match.Groups['classname'].Value
        if (-not $mapping.ContainsKey($original)) {
            $new = Format-Base62Fixed3 ($mapping.Count + $mappingOffset + 1)

            if ($mappingBlacklist -ccontains $new) {
                do {
                    $mappingOffset++
                    $new = Format-Base62Fixed3 ($mapping.Count + $mappingOffset)
                } while ($mappingBlacklist -ccontains $new)
            }

            $mapping[$original] = $new
        }
    }
}

$mappingOffset++
$colorMapping = @{}

Select-String -InputObject $userColorsCss -Pattern '\.(?<classname>[\w]+) \{' -AllMatches | ForEach-Object {
    foreach ($match in $_.Matches) {
        $original = $match.Groups['classname'].Value
        if (-not $colorMapping.ContainsKey($original)) {
            $new = Format-Base62Fixed3 ($mapping.Count + $colorMapping.Count + $mappingOffset)

            if ($mappingBlacklist -ccontains $new) {
                do {
                    $mappingOffset++
                    $new = Format-Base62Fixed3 ($mapping.Count + $colorMapping.Count + $mappingOffset)
                } while ($mappingBlacklist -ccontains $new)
            }

            $colorMapping[$original] = $new
        }
    }
}

Write-Host 'Modifying CSS...' -ForegroundColor Green

foreach ($pair in $mapping.GetEnumerator()) {
    $imagesCss = $imagesCss -replace "\.$([regex]::Escape($pair.Key))(?=\s*\{)", ".$($pair.Value)"
}

foreach ($pair in $colorMapping.GetEnumerator()) {
    $userColorsCss = $userColorsCss -replace "\.$($pair.Key)", ".$($pair.Value)"
}

Write-Host 'Writing CSS to files...' -ForegroundColor Green

Set-Content $imagesCssPath -Value $imagesCss.Trim() -Encoding utf8
Set-Content $userColorsCssPath -Value $userColorsCss.Trim() -Encoding utf8

function Update-ClassNames {
    param(
        [string]$html,
        [hashtable]$map
    )

    return [regex]::Replace(
        $html,
        'class=(?<q>["''])(?<vals>.*?)\k<q>',
        {
            param(
                [Text.RegularExpressions.Match]$match
            )
            $quote = $match.Groups['q'].Value
            $classes = $match.Groups['vals'].Value -split '\s+'
            $new = $classes | ForEach-Object {
                if ($map.ContainsKey($_)) {
                    $map[$_]
                } else {
                    $_
                }
            }
            return "class=$quote$($new -join ' ')$quote"
        }
    )
}

Get-ChildItem $htmlPath -Filter *.html -Recurse | ForEach-Object {
    Write-Host "Processing $($_.Name)..." -ForegroundColor Green
    $htmlContent = Get-Content -LiteralPath $_.FullName -Raw
    $htmlContent = Update-ClassNames $htmlContent $mapping
    $htmlContent = Update-ClassNames $htmlContent $colorMapping
    Set-Content -LiteralPath $_.FullName -Value $htmlContent -Encoding utf8
}
