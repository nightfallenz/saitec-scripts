<#
.SYNOPSIS
  Destrava o spooler de impressao: para o servico, limpa a fila presa e reinicia.
.NOTES
  Uso: fila travada, "documento com erro", impressora nao imprime nada.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$fila = Join-Path $env:SystemRoot 'System32\spool\PRINTERS'

Write-Host "Trabalhos na fila antes:" -ForegroundColor Cyan
Get-Printer -ErrorAction SilentlyContinue | ForEach-Object {
    $n = @(Get-PrintJob -PrinterName $_.Name -ErrorAction SilentlyContinue).Count
    if ($n -gt 0) { Write-Host ("  {0}: {1} trabalho(s)" -f $_.Name, $n) }
}

Write-Host "Parando o spooler..." -ForegroundColor Cyan
Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
# Processos presos do spooler
Get-Process -Name spoolsv, PrintIsolationHost -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Limpando a fila em $fila ..." -ForegroundColor Cyan
Get-ChildItem -Path $fila -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "Iniciando o spooler..." -ForegroundColor Cyan
Set-Service -Name Spooler -StartupType Automatic
Start-Service -Name Spooler

$s = Get-Service Spooler
if ($s.Status -eq 'Running') {
    Write-Host "OK: spooler rodando e fila limpa." -ForegroundColor Green
} else {
    Write-Host "Spooler nao iniciou (status: $($s.Status)). Verifique o Visualizador de Eventos > PrintService." -ForegroundColor Red
}
