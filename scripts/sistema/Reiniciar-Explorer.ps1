<#
.SYNOPSIS
  Reinicia o Explorer e reconstroi o cache de icones.
.NOTES
  Uso: barra de tarefas congelada, menu Iniciar nao abre, icones em branco ou trocados.
  Fecha as janelas do Explorador abertas.
#>
Write-Host "Encerrando o Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "Limpando cache de icones..." -ForegroundColor Cyan
$exp = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Explorer'
Get-ChildItem $exp -Filter 'iconcache_*.db' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:LOCALAPPDATA 'IconCache.db') -Force -ErrorAction SilentlyContinue

Write-Host "Iniciando o Explorer..." -ForegroundColor Cyan
Start-Process explorer.exe
Write-Host "OK: Explorer reiniciado." -ForegroundColor Green
