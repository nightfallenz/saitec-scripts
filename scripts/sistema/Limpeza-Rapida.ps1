<#
.SYNOPSIS
  Limpeza rapida: temporarios do usuario e do Windows, cache de miniaturas, dumps e lixeira.
.NOTES
  Uso: disco cheio, lentidao por falta de espaco. Leva 1 a 3 minutos.
  Para manutencao completa use o Manutencao_Windows.bat.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$antes = (Get-PSDrive C).Free

$alvos = @(
    "$env:TEMP\*",
    "$env:SystemRoot\Temp\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
    "$env:LOCALAPPDATA\CrashDumps\*",
    "$env:ProgramData\Microsoft\Windows\WER\ReportArchive\*",
    "$env:ProgramData\Microsoft\Windows\WER\ReportQueue\*",
    "$env:SystemRoot\Minidump\*"
)
foreach ($a in $alvos) {
    Write-Host "Limpando $a" -ForegroundColor DarkGray
    Remove-Item -Path $a -Recurse -Force -ErrorAction SilentlyContinue
}

# Temporarios de todos os perfis
Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -Path (Join-Path $_.FullName 'AppData\Local\Temp\*') -Recurse -Force -ErrorAction SilentlyContinue
}

Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter 'thumbcache_*.db' -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

$depois = (Get-PSDrive C).Free
Write-Host ("`nOK: {0:N0} MB liberados. Livre agora: {1:N1} GB" -f (($depois - $antes)/1MB), ($depois/1GB)) -ForegroundColor Green
