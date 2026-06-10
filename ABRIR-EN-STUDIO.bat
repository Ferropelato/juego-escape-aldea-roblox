@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo.
echo  ============================================
echo   ESCAPE ISLAND - Abrir en Roblox Studio
echo  ============================================
echo.

where rojo >nul 2>&1
if errorlevel 1 (
    echo  AVISO: rojo no esta en PATH. Se usara EscapeIsland.rbxlx si existe.
    goto :open
)

echo  [1/2] Compilando juego limpio (Escape Island)...
rojo build -o EscapeIsland.rbxlx
if errorlevel 1 (
    echo  ERROR al compilar.
    pause
    exit /b 1
)

:open
if not exist "EscapeIsland.rbxlx" (
    echo  No existe EscapeIsland.rbxlx - instala rojo y vuelve a ejecutar.
    pause
    exit /b 1
)

echo  [2/2] Abriendo en Studio...
echo.
echo  El archivo es: EscapeIsland.rbxlx
echo  (icono de Roblox en esta carpeta - doble clic en el .bat lo abre)
echo.
echo  MUY IMPORTANTE en Studio:
echo  - Si aparece Rojo con "MY-ROJO-PROJECT" pulsa ABORT (no Accept)
echo  - Plugin Rojo: desconectado (Disconnect)
echo  - Pulsa F5 para jugar
echo  - En Salida debe decir: Servidor listo. Islas: 2
echo.

if exist "%~dp0EscapeIsland.rbxlx" (
    start "" "%~dp0EscapeIsland.rbxlx"
) else (
    echo  ERROR: No se encontro EscapeIsland.rbxlx
)

timeout /t 4 >nul
pause
