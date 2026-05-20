# Script per avviare Flutter su Chrome senza errori
# Uso: .\run.ps1

Write-Host "🧹 Chiusura Chrome e pulizia build..." -ForegroundColor Cyan
taskkill /F /IM chrome.exe /T 2>$null | Out-Null
Start-Sleep -Milliseconds 500
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "▶️  Avvio Flutter su Chrome..." -ForegroundColor Green
flutter run -d chrome
