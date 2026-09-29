<#
.SYNOPSIS
  Sincroniza o relogio com o dominio (ou time.windows.com fora do dominio).
.NOTES
  Uso: hora errada, erro de Kerberos, "nao foi possivel entrar", certificados invalidos no navegador.
  Diferenca maior que 5 minutos para o DC impede o logon no dominio.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$emDominio = (Get-CimInstance Win32_ComputerSystem).PartOfDomain
Write-Host ("Hora local antes: {0}" -f (Get-Date -Format 'dd/MM/yyyy HH:mm:ss'))
Write-Host ("Fuso horario: {0}" -f (Get-TimeZone).DisplayName)

Set-Service w32time -StartupType Automatic
Start-Service w32time -ErrorAction SilentlyContinue

if ($emDominio) {
    Write-Host "Maquina em dominio: sincronizando pela hierarquia do dominio..." -ForegroundColor Cyan
    w32tm /config /syncfromflags:domhier /update | Out-Null
} else {
    Write-Host "Maquina fora do dominio: sincronizando com time.windows.com..." -ForegroundColor Cyan
    w32tm /config /manualpeerlist:"time.windows.com,0x9" /syncfromflags:manual /update | Out-Null
}
Restart-Service w32time
Start-Sleep -Seconds 2
w32tm /resync /force

Write-Host ("`nHora local depois: {0}" -f (Get-Date -Format 'dd/MM/yyyy HH:mm:ss'))
w32tm /query /source
