$movePath = Join-Path $PSScriptRoot '../empty-chats'
$htmlPath = Join-Path $PSScriptRoot '../html'
$jsonPath = Join-Path $PSScriptRoot '../chat-json'

if (-not (Test-Path $htmlPath)) { New-Item -ItemType Directory $htmlPath }
if (-not (Test-Path $movePath)) { New-Item -ItemType Directory $movePath }
if (-not (Test-Path $jsonPath)) { New-Item -ItemType Directory $jsonPath }

Get-ChildItem $htmlPath -Filter *.html -Recurse | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw

    $isEmptyChat = $content -match "<div id='content'>\n<\/div>"
    if ($isEmptyChat) {
        $correspondingJson = Get-ChildItem -Path $jsonPath ` -Filter "$($_.BaseName).json.gz" ` -Recurse
        Write-Host "Empty chat detected in $($_.Name)" -ForegroundColor Yellow
        Move-Item -LiteralPath $_.FullName -Destination $movePath
        Move-Item -LiteralPath $correspondingJson -Destination $movePath
    }
}
