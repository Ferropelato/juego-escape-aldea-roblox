@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo  Modo programador: Rojo en vivo (cerrar el otro juego antes)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0iniciar-rojo.ps1"
pause
