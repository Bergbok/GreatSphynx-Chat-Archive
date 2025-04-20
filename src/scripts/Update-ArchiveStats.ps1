$htmlPath = Join-Path $PSScriptRoot '../html'
$readmePath = Join-Path $PSScriptRoot '../../README.md'

$htmlFiles   = Get-ChildItem $htmlPath -Filter '*.html' -Recurse
$fileCount   = $htmlFiles.Count

Write-Host "Determining date range..." -ForegroundColor Green

$dates = $htmlFiles | ForEach-Object {
    if ($_.BaseName -match '\b(?<date>\d{4}-\d{2}-\d{2})\b') {
        [datetime]::ParseExact($matches['date'], 'yyyy-MM-dd', $null)
    }
} | Where-Object { $_ -is [datetime] }

$minDate = ($dates | Sort-Object)[0]
$maxDate = ($dates | Sort-Object)[-1]

Write-Host "Determining message count..." -ForegroundColor Green

$totalMessages = 0
foreach ($file in $htmlFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $messages = [regex]::Matches($content, '<pre\s+class\s*=\s*["'']cr["'']')
    $totalMessages += $messages.Count
}

$statsContent = "Video count: $fileCount`nDate range: $($minDate.ToString('yyyy-MM-dd')) -> $($maxDate.ToString('yyyy-MM-dd'))`nMessage count: $($totalMessages.ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('en-US')))"

$readmeContent = Get-Content -LiteralPath $readmePath -Raw

$pattern = '(?s)(<!-- Statistics -->\s*```[^`\n]*\n).*?(```)'
$replacement = '${1}' + $statsContent + "`n" + '${2}'

$readmeUpdated = $readmeContent -replace $pattern, $replacement

Set-Content -LiteralPath $readmePath -Value $readmeUpdated -Encoding utf8

Write-Host "README.md updated with new statistics."
