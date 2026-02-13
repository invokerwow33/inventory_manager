@echo off
echo ===============================
echo  Запуск приложения инвентаризации
echo ===============================
echo.

cd /d "C:\Users\chiso\Desktop\inventory_manager"
"C:\Users\chiso\flutter\bin\flutter.bat" doctor
"C:\Users\chiso\flutter\bin\flutter.bat" pub get
"C:\Users\chiso\flutter\bin\flutter.bat" run -d windows

pause