<#
.SYNOPSIS
  Repara a Microsoft Store e os apps nativos do usuario (cache e re-registro).
.NOTES
  Uso: Store nao abre ou nao baixa, Calculadora/Fotos/Ferramenta de Captura nao abrem.
  Rodar como o PROPRIO usuario. Leva alguns minutos.
#>
Write-Host "1/2 Limpando cache da Store (wsreset)..." -ForegroundColor Cyan
Start-Process wsreset.exe -Wait -ErrorAction SilentlyContinue
Get-Process -Name WinStore.App -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "2/2 Registrando novamente os apps do usuario..." -ForegroundColor Cyan
$erros = 0
Get-AppxPackage | Where-Object { $_.InstallLocation -and $_.SignatureKind -in 'System', 'Store' } | ForEach-Object {
    $man = Join-Path $_.InstallLocation 'AppxManifest.xml'
    if (Test-Path $man) {
        try { Add-AppxPackage -DisableDevelopmentMode -Register $man -ErrorAction Stop }
        catch { $erros++ }
    }
}

Write-Host ("`nConcluido. {0} pacote(s) nao puderam ser registrados (normal alguns em uso)." -f $erros) -ForegroundColor Green
Write-Host "Se a Store continuar sem abrir, reinicie o PC e rode o item 'Reparar Windows (DISM + SFC)'."
