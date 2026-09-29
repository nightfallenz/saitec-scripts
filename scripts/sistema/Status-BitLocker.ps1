<#
.SYNOPSIS
  Status do BitLocker em todas as unidades e o ID da chave de recuperacao.
.NOTES
  Uso: maquina pedindo chave de recuperacao, conferir se o disco esta criptografado antes de formatar/trocar placa.
  Mostra o ID da chave (para buscar no AD/Intune). A senha de 48 digitos so aparece se voce pedir.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$vols = Get-BitLockerVolume -ErrorAction SilentlyContinue
if (-not $vols) { Write-Host "BitLocker indisponivel nesta edicao do Windows (ex.: Home)." -ForegroundColor Yellow; return }

foreach ($v in $vols) {
    $cor = if ($v.ProtectionStatus -eq 'On') { 'Green' } else { 'Yellow' }
    Write-Host ("`n{0}  Protecao: {1}  Criptografado: {2}%  Metodo: {3}" -f $v.MountPoint, $v.ProtectionStatus, $v.EncryptionPercentage, $v.EncryptionMethod) -ForegroundColor $cor
    foreach ($p in $v.KeyProtector) {
        Write-Host ("   {0,-22} ID: {1}" -f $p.KeyProtectorType, $p.KeyProtectorId)
    }
}

Write-Host "`nPara buscar a chave: AD (Usuarios e Computadores > computador > Recuperacao do BitLocker) ou Intune/Entra, pelo ID acima." -ForegroundColor Gray
if ((Read-Host "`nMostrar a senha de recuperacao (48 digitos) nesta tela? (S/N)") -match '^[sS]') {
    foreach ($v in $vols) {
        $v.KeyProtector | Where-Object KeyProtectorType -eq 'RecoveryPassword' | ForEach-Object {
            Write-Host ("{0}  {1}" -f $v.MountPoint, $_.RecoveryPassword) -ForegroundColor Cyan
        }
    }
    Write-Host "Nao salve a chave em chamado aberto, e-mail ou arquivo compartilhado." -ForegroundColor Yellow
}
