Push-Location $PSScriptRoot

& Get-ChannelVideoInfo.ps1
& Get-ChatBadges.ps1
& Get-Chats.ps1
& Move-EmptyChats.ps1
& Get-Thumbnails.ps1
& Optimize-HTML.ps1
& Optimize-CSS.ps1
& Update-HTMLli.ps1
& Update-ArchiveStats.ps1

Pop-Location

git add .
git commit -m "chore: add chats" -m "<list new chat files here>"
