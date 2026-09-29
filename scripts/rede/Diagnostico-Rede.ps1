<#
.SYNOPSIS
  Diagnostico rapido de rede, em camadas: placa -> gateway -> internet -> DNS -> HTTPS.
.NOTES
  Uso: primeiro passo em chamado de "sem internet". Nao altera nada.
#>
function Teste($nome, [scriptblock]$bloco) {
    try { $ok = & $bloco } catch { $ok = $false }
    if ($ok) { Write-Host ("[ OK ] {0}" -f $nome) -ForegroundColor Green }
    else     { Write-Host ("[FALHA] {0}" -f $nome) -ForegroundColor Red }
    return [bool]$ok
}

Write-Host "`n=== Adaptadores ativos ===" -ForegroundColor Cyan
Get-NetAdapter | Where-Object Status -eq 'Up' |
    Format-Table Name, InterfaceDescription, LinkSpeed, MacAddress -AutoSize

$cfg = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1
if (-not $cfg) {
    Write-Host "Nenhum adaptador com gateway. Verifique cabo/Wi-Fi ou DHCP." -ForegroundColor Red
    return
}
$ip  = $cfg.IPv4Address.IPAddress
$gw  = $cfg.IPv4DefaultGateway.NextHop
$dns = ($cfg.DNSServer | Where-Object AddressFamily -eq 2).ServerAddresses -join ', '
Write-Host ("IP: {0}  Gateway: {1}  DNS: {2}" -f $ip, $gw, $dns)
if ($ip -like '169.254.*') { Write-Host "IP APIPA (169.254): o DHCP nao respondeu." -ForegroundColor Red }

Write-Host "`n=== Testes ===" -ForegroundColor Cyan
Teste "Gateway responde ($gw)"          { Test-Connection $gw -Count 2 -Quiet } | Out-Null
Teste "Internet por IP (8.8.8.8)"        { Test-Connection 8.8.8.8 -Count 2 -Quiet } | Out-Null
Teste "DNS resolve (www.microsoft.com)"  { [bool](Resolve-DnsName www.microsoft.com -ErrorAction Stop) } | Out-Null
Teste "HTTPS porta 443 (www.google.com)" { (Test-NetConnection www.google.com -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded } | Out-Null

$proxy = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue)
if ($proxy.ProxyEnable -eq 1) { Write-Host ("`nProxy do usuario ATIVO: {0}" -f $proxy.ProxyServer) -ForegroundColor Yellow }

Write-Host "`nLeitura: falha no gateway = problema local (cabo, Wi-Fi, switch). Gateway OK e 8.8.8.8 falha = link/firewall. IP OK e DNS falha = servidor DNS." -ForegroundColor Gray
