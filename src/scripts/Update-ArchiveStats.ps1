$htmlPath = Join-Path $PSScriptRoot '../html'
$readmePath = Join-Path $PSScriptRoot '../../README.md'

$htmlFiles   = Get-ChildItem $htmlPath -Filter '*.html' -Recurse
$fileCount   = $htmlFiles.Count

$dates = $htmlFiles | ForEach-Object {
    if ($_.BaseName -match '\b(?<date>\d{4}-\d{2}-\d{2})\b') {
        [datetime]::ParseExact($matches['date'], 'yyyy-MM-dd', $null)
    }
} | Where-Object { $_ -is [datetime] }

$minDate = ($dates | Sort-Object)[0]
$maxDate = ($dates | Sort-Object)[-1]

$statsContent = "File count: $fileCount`nDate range: $($minDate.ToString('yyyy-MM-dd')) -> $($maxDate.ToString('yyyy-MM-dd'))"

$readmeContent = Get-Content -LiteralPath $readmePath -Raw

$pattern = '(?s)(<!-- Statistics -->\s*```[^`\n]*\n).*?(```)'
$replacement = '${1}' + $statsContent + "`n" + '${2}'

$readmeUpdated = $readmeContent -replace $pattern, $replacement

Set-Content -LiteralPath $readmePath -Value $readmeUpdated -Encoding utf8

Write-Host "README.md updated with new statistics."
