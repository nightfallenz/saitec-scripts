<#
.SYNOPSIS
  Reseta o OneDrive do usuario atual (reconstroi a sincronizacao sem apagar arquivos).
.NOTES
  Uso: OneDrive parado em "processando alteracoes", icones de sincronizacao sumidos, erros de sync.
  Rodar como o PROPRIO usuario. Os arquivos locais e na nuvem sao mantidos.
#>
$caminhos = @(
    "$env:LOCALAPPDATA\Microsoft\OneDrive\onedrive.exe",
    "$env:ProgramFiles\Microsoft OneDrive\onedrive.exe",
    "${env:ProgramFiles(x86)}\Microsoft OneDrive\onedrive.exe"
)
$exe = $caminhos | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) { Write-Host "OneDrive nao encontrado." -ForegroundColor Yellow; return }

Write-Host "Resetando OneDrive ($exe)..." -ForegroundColor Cyan
Start-Process $exe -ArgumentList '/reset'
Start-Sleep -Seconds 15

if (-not (Get-Process -Name OneDrive -ErrorAction SilentlyContinue)) {
    Write-Host "Reabrindo o OneDrive..." -ForegroundColor Cyan
    Start-Process $exe
}
Write-Host "OK: OneDrive resetado. A ressincronizacao pode levar alguns minutos." -ForegroundColor Green
