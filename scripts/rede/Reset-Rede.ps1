<#
.SYNOPSIS
  Redefine a pilha de rede: DNS, IP, Winsock, TCP/IP e proxy do sistema.
.NOTES
  Uso: sem internet com rede conectada, DNS falhando, "rede nao identificada".
  A conexao cai por alguns segundos. Reinicie o PC ao final.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

Write-Host "ATENCAO: a rede vai cair por alguns segundos." -ForegroundColor Yellow
if ((Read-Host "Continuar? (S/N)") -notmatch '^[sS]') { return }

$passos = @(
    @{ t = 'Limpando cache DNS';        c = { ipconfig /flushdns } },
    @{ t = 'Liberando IP';              c = { ipconfig /release } },
    @{ t = 'Renovando IP';              c = { ipconfig /renew } },
    @{ t = 'Resetando Winsock';         c = { netsh winsock reset } },
    @{ t = 'Resetando TCP/IP';          c = { netsh int ip reset } },
    @{ t = 'Resetando proxy WinHTTP';   c = { netsh winhttp reset proxy } },
    @{ t = 'Registrando DNS';           c = { ipconfig /registerdns } }
)
foreach ($p in $passos) {
    Write-Host ("-> {0}..." -f $p.t) -ForegroundColor Cyan
    & $p.c | Out-Null
}

Write-Host "`nOK: rede redefinida. REINICIE o computador para concluir o reset do Winsock/TCP-IP." -ForegroundColor Green
