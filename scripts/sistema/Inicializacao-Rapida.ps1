<#
.SYNOPSIS
  Liga ou desliga a Inicializacao Rapida (Fast Startup) do Windows.
.NOTES
  Uso: "ligado ha 30 dias" mesmo desligando todo dia, updates que nunca terminam,
  drivers/dispositivos que so voltam com reinicio, dual boot, Wake-on-LAN falhando.
  Com Fast Startup ligado, "Desligar" nao reinicia o kernel de verdade.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$k = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
$atual = (Get-ItemProperty $k -Name HiberbootEnabled -ErrorAction SilentlyContinue).HiberbootEnabled
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Host ("Inicializacao rapida: {0}" -f $(if ($atual -eq 1) {'LIGADA'} else {'desligada'}))
Write-Host ("Kernel ligado ha: {0}d {1}h" -f $uptime.Days, $uptime.Hours)

Write-Host "`n[1] Desligar Inicializacao Rapida (recomendado em empresa)"
Write-Host "[2] Ligar Inicializacao Rapida"
switch (Read-Host "Escolha (Enter para sair)") {
    '1' { Set-ItemProperty $k -Name HiberbootEnabled -Value 0 -Type DWord; Write-Host "OK: desligada. Vale a partir do proximo desligamento." -ForegroundColor Green }
    '2' { powercfg /hibernate on; Set-ItemProperty $k -Name HiberbootEnabled -Value 1 -Type DWord; Write-Host "OK: ligada." -ForegroundColor Green }
}
