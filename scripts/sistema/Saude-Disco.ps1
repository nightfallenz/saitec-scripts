<#
.SYNOPSIS
  Saude dos discos: status SMART do Windows, desgaste do SSD, erros de leitura e temperatura.
.NOTES
  Uso: lentidao, travamentos, antes de decidir troca de disco. Nao altera nada.
  Para detalhes completos use o CrystalDiskInfo (item Ferramentas).
  Requer Administrador (contadores de confiabilidade).
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$discos = Get-PhysicalDisk | Sort-Object DeviceId
foreach ($d in $discos) {
    $cor = switch ($d.HealthStatus) { 'Healthy' {'Green'} 'Warning' {'Yellow'} default {'Red'} }
    Write-Host ("`nDisco {0}: {1}  ({2}, {3}, {4:N0} GB)" -f $d.DeviceId, $d.FriendlyName, $d.MediaType, $d.BusType, ($d.Size/1GB)) -ForegroundColor Cyan
    Write-Host ("  Saude: {0}   Operacional: {1}" -f $d.HealthStatus, ($d.OperationalStatus -join ', ')) -ForegroundColor $cor

    $r = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
    if ($r) {
        if ($null -ne $r.Wear)                 { Write-Host ("  Desgaste (SSD):        {0}%" -f $r.Wear) }
        if ($null -ne $r.Temperature)          { Write-Host ("  Temperatura:           {0} C (max {1} C)" -f $r.Temperature, $r.TemperatureMax) }
        if ($null -ne $r.PowerOnHours)         { Write-Host ("  Horas ligado:          {0:N0}" -f $r.PowerOnHours) }
        if ($null -ne $r.ReadErrorsUncorrected){ Write-Host ("  Erros de leitura:      {0}" -f $r.ReadErrorsUncorrected) }
        if ($null -ne $r.WriteErrorsUncorrected){Write-Host ("  Erros de escrita:      {0}" -f $r.WriteErrorsUncorrected) }
        if ($r.Wear -ge 80 -or $r.ReadErrorsUncorrected -gt 0) {
            Write-Host "  ATENCAO: faca backup e programe a troca deste disco." -ForegroundColor Red
        }
    } else {
        Write-Host "  Contadores SMART indisponiveis (comum em USB/RAID). Use o CrystalDiskInfo." -ForegroundColor Gray
    }
}

$ev = Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'disk', 'Ntfs', 'stornvme', 'storahci'; Level = 1, 2, 3; StartTime = (Get-Date).AddDays(-30) } -MaxEvents 10 -ErrorAction SilentlyContinue
if ($ev) {
    Write-Host "`nEventos de disco nos ultimos 30 dias:" -ForegroundColor Yellow
    $ev | Format-Table TimeCreated, ProviderName, Id, @{n='Mensagem';e={($_.Message -split "`n")[0]}} -AutoSize -Wrap
} else {
    Write-Host "`nSem eventos de erro de disco nos ultimos 30 dias." -ForegroundColor Green
}
