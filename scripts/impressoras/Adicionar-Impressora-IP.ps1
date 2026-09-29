<#
.SYNOPSIS
  Adiciona uma impressora de rede direto pelo IP (porta TCP/IP), usando um driver ja instalado.
.NOTES
  Uso: impressora sem servidor de impressao, reinstalar impressora apos troca de IP.
  Instale o driver do fabricante antes, se ele nao aparecer na lista.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$ip = (Read-Host "IP da impressora (ex.: 192.168.0.50)").Trim()
if ($ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') { Write-Host "IP invalido."; return }

Write-Host "Testando a impressora..." -ForegroundColor Cyan
$ping = Test-Connection $ip -Count 2 -Quiet
$p9100 = (Test-NetConnection $ip -Port 9100 -WarningAction SilentlyContinue).TcpTestSucceeded
Write-Host ("  Ping: {0}   Porta 9100 (RAW): {1}" -f $(if ($ping) {'OK'} else {'sem resposta'}), $(if ($p9100) {'aberta'} else {'fechada'}))
if (-not $ping -and -not $p9100) {
    if ((Read-Host "A impressora nao respondeu. Continuar mesmo assim? (S/N)") -notmatch '^[sS]') { return }
}

$drivers = @(Get-PrinterDriver | Sort-Object Name)
Write-Host "`nDrivers instalados:" -ForegroundColor Cyan
for ($i = 0; $i -lt $drivers.Count; $i++) { Write-Host ("[{0,2}] {1}" -f ($i + 1), $drivers[$i].Name) }
$n = Read-Host "Numero do driver"
if ($n -notmatch '^\d+$' -or [int]$n -lt 1 -or [int]$n -gt $drivers.Count) { Write-Host "Opcao invalida."; return }
$driver = $drivers[[int]$n - 1].Name

$nome = (Read-Host "Nome para a impressora (Enter = '$driver - $ip')").Trim()
if (-not $nome) { $nome = "$driver - $ip" }

$porta = "IP_$ip"
if (-not (Get-PrinterPort -Name $porta -ErrorAction SilentlyContinue)) {
    Add-PrinterPort -Name $porta -PrinterHostAddress $ip
}
try {
    Add-Printer -Name $nome -DriverName $driver -PortName $porta -ErrorAction Stop
    Write-Host "OK: impressora '$nome' adicionada." -ForegroundColor Green
    if ((Read-Host "Imprimir pagina de teste? (S/N)") -match '^[sS]') {
        $wp = Get-CimInstance Win32_Printer | Where-Object Name -eq $nome
        if ($wp) { Invoke-CimMethod -InputObject $wp -MethodName PrintTestPage | Out-Null }
    }
} catch {
    Write-Host ("Falha ao adicionar: {0}" -f $_.Exception.Message) -ForegroundColor Red
}
