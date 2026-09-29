<#
.SYNOPSIS
  Repara a imagem e os arquivos do Windows (DISM RestoreHealth + SFC).
.NOTES
  Uso: telas azuis, apps nativos quebrados, update falhando, erros de DLL.
  Demora de 10 a 40 minutos. Precisa de internet para o DISM baixar arquivos.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

Write-Host "1/3 DISM - verificando a imagem..." -ForegroundColor Cyan
DISM /Online /Cleanup-Image /ScanHealth

Write-Host "`n2/3 DISM - reparando a imagem..." -ForegroundColor Cyan
DISM /Online /Cleanup-Image /RestoreHealth

Write-Host "`n3/3 SFC - verificando arquivos do sistema..." -ForegroundColor Cyan
sfc /scannow

Write-Host "`nConcluido. Se o SFC reportou arquivos que nao conseguiu reparar, veja C:\Windows\Logs\CBS\CBS.log e reinicie o PC." -ForegroundColor Green
