# Escape Island — libera el puerto 34872 y sirve ESTE juego (Studio usa 34872 por defecto)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "  ESCAPE ISLAND - Rojo" -ForegroundColor Cyan
Write-Host "  Carpeta: $PSScriptRoot" -ForegroundColor DarkGray
Write-Host ""

function Stop-PortListener($port) {
	$connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
	if (-not $connections) { return }
	foreach ($conn in $connections) {
		$procId = $conn.OwningProcess
		if ($procId -and $procId -ne 0) {
			$proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
			$name = if ($proc) { $proc.ProcessName } else { "PID $procId" }
			Write-Host "  Cerrando $name (puerto $port)..." -ForegroundColor Yellow
			Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
		}
	}
	Start-Sleep -Milliseconds 500
}

# El plugin de Studio casi siempre conecta a 34872 — hay que liberarlo del OTRO juego
Write-Host "  Liberando puerto 34872 (otro Rojo suele estar ahi)..." -ForegroundColor Yellow
Stop-PortListener 34872
Stop-PortListener 34873

# Por si quedo algun rojo.exe colgado
Get-Process -Name "rojo" -ErrorAction SilentlyContinue | ForEach-Object {
	Write-Host "  Cerrando proceso rojo (PID $($_.Id))..." -ForegroundColor Yellow
	Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 1

if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) {
	Write-Host "  ERROR: 'rojo' no esta en el PATH. Ejecuta: aftman install" -ForegroundColor Red
	exit 1
}

Write-Host ""
Write-Host "  Iniciando Escape Island en http://localhost:34872" -ForegroundColor Green
Write-Host "  En Studio: plugin Rojo -> Connect (puerto 34872, el que ya usa por defecto)" -ForegroundColor Green
Write-Host "  Debes ver en Explorer: EscapeIsland, Server, GameUI..." -ForegroundColor Green
Write-Host "  NO debe aparecer AldeaConquest ni el otro proyecto." -ForegroundColor Green
Write-Host ""

rojo serve --port 34872
