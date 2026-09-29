<#
.SYNOPSIS
  Lista impressoras, portas e drivers; permite remover uma impressora e o driver dela.
.NOTES
  Uso: driver corrompido, impressora duplicada, reinstalacao limpa.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$lista = @(Get-Printer | Sort-Object Name)
if ($lista.Count -eq 0) { Write-Host "Nenhuma impressora instalada."; return }

Write-Host "`nImpressoras instaladas:" -ForegroundColor Cyan
for ($i = 0; $i -lt $lista.Count; $i++) {
    $p = $lista[$i]
    Write-Host ("[{0}] {1}" -f ($i + 1), $p.Name) -ForegroundColor Yellow
    Write-Host ("     Driver: {0} | Porta: {1} | Status: {2}" -f $p.DriverName, $p.PortName, $p.PrinterStatus)
}

$op = Read-Host "`nNumero da impressora para REMOVER (Enter para sair)"
if (-not $op) { return }
$idx = [int]$op - 1
if ($idx -lt 0 -or $idx -ge $lista.Count) { Write-Host "Opcao invalida."; return }

$alvo = $lista[$idx]
$conf = Read-Host ("Remover '{0}'? (S/N)" -f $alvo.Name)
if ($conf -notmatch '^[sS]') { return }

Remove-Printer -Name $alvo.Name -ErrorAction Continue
Write-Host "Impressora removida." -ForegroundColor Green

$emUso = Get-Printer | Where-Object DriverName -eq $alvo.DriverName
if (-not $emUso) {
    $conf2 = Read-Host ("Remover tambem o driver '{0}'? (S/N)" -f $alvo.DriverName)
    if ($conf2 -match '^[sS]') {
        Restart-Service Spooler -Force
        try {
            Remove-PrinterDriver -Name $alvo.DriverName -RemoveFromDriverStore -ErrorAction Stop
            Write-Host "Driver removido do sistema." -ForegroundColor Green
        } catch {
            Write-Host ("Nao foi possivel remover o driver: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
            Write-Host "Dica: rode 'printui /s /t2' para remover pela interface."
        }
    }
} else {
    Write-Host "Driver mantido: ainda usado por outra impressora."
}
