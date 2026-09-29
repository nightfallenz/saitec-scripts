<#
.SYNOPSIS
  Ficha da maquina para o chamado: hostname, usuario, modelo, serial, Windows, RAM, disco, IP, uptime.
.NOTES
  Copia o resultado para a area de transferencia, pronto para colar no ticket. Nao altera nada.
#>
$cs   = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$os   = Get-CimInstance Win32_OperatingSystem
$cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
$ver  = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
$ips  = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
         Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' }).IPAddress -join ', '
$disco = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    "{0} {1:N0}/{2:N0} GB livres" -f $_.DeviceID, ($_.FreeSpace/1GB), ($_.Size/1GB)
}
$uptime = (Get-Date) - $os.LastBootUpTime
$dominio = if ($cs.PartOfDomain) { $cs.Domain } else { "Grupo de trabalho: $($cs.Workgroup)" }

$ficha = @"
Hostname....: $env:COMPUTERNAME
Usuario.....: $env:USERDOMAIN\$env:USERNAME
Dominio.....: $dominio
Fabricante..: $($cs.Manufacturer)
Modelo......: $($cs.Model)
Serial......: $($bios.SerialNumber)
Windows.....: $($os.Caption) $ver (build $($os.BuildNumber))
Processador.: $($cpu.Name.Trim())
RAM.........: $([math]::Round($cs.TotalPhysicalMemory/1GB)) GB
Discos......: $($disco -join ' | ')
IP..........: $ips
Ligado ha...: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)min
Coletado em.: $(Get-Date -Format 'dd/MM/yyyy HH:mm')
"@

Write-Host $ficha
try { $ficha | Set-Clipboard; Write-Host "`n(Copiado para a area de transferencia)" -ForegroundColor Green } catch {}
