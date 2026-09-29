<#
.SYNOPSIS
  Reseta os componentes do Windows Update (servicos, SoftwareDistribution, catroot2).
.NOTES
  Uso: update travado em %, erro 0x8024xxxx / 0x800f0xxx, "falha ao instalar" repetido.
  O historico de updates exibido fica vazio (os updates instalados continuam).
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$servicos = 'wuauserv', 'bits', 'cryptsvc', 'msiserver', 'usosvc'
Write-Host "Parando servicos..." -ForegroundColor Cyan
foreach ($s in $servicos) { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue }

$pastas = @(
    (Join-Path $env:SystemRoot 'SoftwareDistribution'),
    (Join-Path $env:SystemRoot 'System32\catroot2')
)
foreach ($p in $pastas) {
    $bak = "$p.old"
    if (Test-Path $bak) { Remove-Item $bak -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $p) {
        try { Rename-Item $p $bak -ErrorAction Stop; Write-Host "Renomeado: $p" }
        catch { Write-Host "Nao foi possivel renomear $p (em uso). Reinicie e rode de novo." -ForegroundColor Yellow }
    }
}

Write-Host "Limpando fila do BITS..." -ForegroundColor Cyan
Remove-Item "$env:ALLUSERSPROFILE\Microsoft\Network\Downloader\qmgr*.dat" -Force -ErrorAction SilentlyContinue

Write-Host "Iniciando servicos..." -ForegroundColor Cyan
foreach ($s in $servicos) { Start-Service -Name $s -ErrorAction SilentlyContinue }

Write-Host "Solicitando nova busca de updates..." -ForegroundColor Cyan
Start-Process -FilePath "$env:SystemRoot\System32\UsoClient.exe" -ArgumentList 'StartScan' -ErrorAction SilentlyContinue

Write-Host "`nOK: Windows Update resetado. Abra Configuracoes > Windows Update e clique em Verificar." -ForegroundColor Green
