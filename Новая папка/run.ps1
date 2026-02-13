# run.ps1
$flutterPath = "C:\Users\chiso\flutter\bin\flutter.bat"

Write-Host "=== ЗАПУСК ПРИЛОЖЕНИЯ ===" -ForegroundColor Green

Write-Host "1. Проверка Flutter..." -ForegroundColor Yellow
& $flutterPath --version

Write-Host "`n2. Установка зависимостей..." -ForegroundColor Yellow
& $flutterPath pub get

Write-Host "`n3. Запуск приложения..." -ForegroundColor Yellow
& $flutterPath run -d windows