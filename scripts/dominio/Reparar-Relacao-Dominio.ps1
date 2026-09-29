<#
.SYNOPSIS
  Testa e repara a relacao de confianca entre a maquina e o dominio, sem tirar do dominio.
.NOTES
  Uso: "A relacao de confianca entre esta estacao de trabalho e o dominio primario falhou".
  Precisa de uma conta com permissao para redefinir a conta de computador no AD.
  Faca logon com conta LOCAL de admin (ou ainda logado) e com rede ate o DC.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$cs = Get-CimInstance Win32_ComputerSystem
if (-not $cs.PartOfDomain) { Write-Host "Esta maquina nao esta em dominio." -ForegroundColor Yellow; return }
Write-Host "Dominio: $($cs.Domain)"

Write-Host "Testando canal seguro com o dominio..." -ForegroundColor Cyan
$ok = $false
try { $ok = Test-ComputerSecureChannel -ErrorAction Stop } catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }

if ($ok) {
    Write-Host "OK: a relacao de confianca esta funcionando. Nada a reparar." -ForegroundColor Green
    return
}

Write-Host "Relacao de confianca QUEBRADA." -ForegroundColor Red
Write-Host "Informe uma conta do dominio com permissao (ex.: DOMINIO\admin.suporte)."
$cred = Get-Credential -Message "Conta do dominio com permissao para redefinir a conta de computador"
if (-not $cred) { return }

try {
    if (Test-ComputerSecureChannel -Repair -Credential $cred -ErrorAction Stop) {
        Write-Host "OK: relacao reparada. Faca logoff e entre com o usuario do dominio." -ForegroundColor Green
    } else {
        Write-Host "O reparo nao funcionou." -ForegroundColor Red
    }
} catch {
    Write-Host ("Falha: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "Alternativa: Reset-ComputerMachinePassword -Credential (DOMINIO\usuario) ou tirar e colocar no dominio."
}
