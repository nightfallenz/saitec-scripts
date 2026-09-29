<#
.SYNOPSIS
  Abre o reparo do Microsoft 365 / Office (Clique para Executar): rapido ou online.
.NOTES
  Uso: Office travando, fechando sozinho, suplementos quebrados.
  Reparo rapido: offline, poucos minutos. Reparo online: reinstala o Office (precisa de internet, ~30 min).
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$c2r = "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
if (-not (Test-Path $c2r)) {
    Write-Host "Office Clique para Executar nao encontrado. Use Painel de Controle > Programas > Office > Alterar." -ForegroundColor Yellow
    return
}

$cfg = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue
$plat = if ($cfg.Platform) { $cfg.Platform } else { 'x64' }
$cult = if ($cfg.ClientCulture) { $cfg.ClientCulture } else { 'pt-br' }
Write-Host ("Office detectado: {0} {1} ({2})" -f $cfg.ProductReleaseIds, $plat, $cult)

Write-Host "`n[1] Reparo rapido (recomendado primeiro)"
Write-Host "[2] Reparo online (reinstalacao completa)"
$op = Read-Host "Escolha (Enter para sair)"
$tipo = switch ($op) { '1' { 'QuickRepair' } '2' { 'FullRepair' } default { $null } }
if (-not $tipo) { return }

Write-Host "Fechando apps do Office..." -ForegroundColor Cyan
Get-Process -Name OUTLOOK, WINWORD, EXCEL, POWERPNT, MSACCESS, ONENOTE, lync -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

Start-Process -FilePath $c2r -ArgumentList "scenario=Repair platform=$plat culture=$cult RepairType=$tipo forceappshutdown=True DisplayLevel=True"
Write-Host "Reparo iniciado. Acompanhe a janela do Office." -ForegroundColor Green
