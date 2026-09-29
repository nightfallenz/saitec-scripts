<#
.SYNOPSIS
  Instala ferramentas de suporte pelo winget, sempre da fonte oficial.
.NOTES
  Escolha por numero (ex.: 1,3,5), por pacote (P1, P2) ou T para todas.
  Requer Administrador e o winget (Instalador de Aplicativo da Microsoft Store).
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget nao encontrado. Instale o 'Instalador de Aplicativo' pela Microsoft Store e rode de novo." -ForegroundColor Red
    return
}

# Nome | ID winget | Para que serve
$apps = @(
    @('7-Zip',                 '7zip.7zip',                                 'Compactar e extrair [OSS]'),
    @('AnyDesk',               'AnyDesk.AnyDesk',                           'Acesso remoto'),
    @('TeamViewer',            'TeamViewer.TeamViewer',                     'Acesso remoto'),
    @('CrystalDiskInfo',       'CrystalDewWorld.CrystalDiskInfo',           'Saude do SSD/HD (SMART) [OSS]'),
    @('CrystalDiskMark',       'CrystalDewWorld.CrystalDiskMark',           'Velocidade do disco [OSS]'),
    @('Sysinternals Suite',    'Microsoft.Sysinternals.Suite',              'Process Explorer, Autoruns, TCPView'),
    @('Advanced IP Scanner',   'Famatech.AdvancedIPScanner',                'Varredura de IPs na rede'),
    @('Notepad++',             'Notepad++.Notepad++',                       'Editor de texto e logs [OSS]'),
    @('Rufus',                 'Rufus.Rufus',                               'Pendrive bootavel [OSS]'),
    @('WinDirStat',            'WinDirStat.WinDirStat',                     'O que esta ocupando o disco [OSS]'),
    @('CPU-Z',                 'CPUID.CPU-Z',                               'CPU, RAM e placa-mae'),
    @('HWiNFO',                'REALiX.HWiNFO',                             'Sensores e temperaturas'),
    @('LibreHardwareMonitor',  'LibreHardwareMonitor.LibreHardwareMonitor', 'Temperaturas e sensores [OSS]'),
    @('PuTTY',                 'PuTTY.PuTTY',                               'SSH/Telnet/Serial para switches [OSS]'),
    @('WinSCP',                'WinSCP.WinSCP',                             'SFTP/SCP/FTP [OSS]'),
    @('Wireshark',             'WiresharkFoundation.Wireshark',             'Captura de pacotes [OSS]'),
    @('Bulk Crap Uninstaller', 'Klocman.BulkCrapUninstaller',               'Desinstalar em massa e restos [OSS]'),
    @('KeePassXC',             'KeePassXCTeam.KeePassXC',                   'Cofre de senhas offline [OSS]'),
    @('ShareX',                'ShareX.ShareX',                             'Print e gravacao de tela [OSS]'),
    @('PowerToys',             'Microsoft.PowerToys',                       'Utilitarios do Windows [OSS]'),
    @('Windows Terminal',      'Microsoft.WindowsTerminal',                 'Terminal com abas [OSS]'),
    @('PowerShell 7',          'Microsoft.PowerShell',                      'PowerShell atual [OSS]'),
    @('Google Chrome',         'Google.Chrome',                             'Navegador'),
    @('Mozilla Firefox',       'Mozilla.Firefox',                           'Navegador [OSS]'),
    @('Adobe Acrobat Reader',  'Adobe.Acrobat.Reader.64-bit',               'Leitor de PDF'),
    @('SumatraPDF',            'SumatraPDF.SumatraPDF',                     'Leitor de PDF leve [OSS]'),
    @('LibreOffice',           'TheDocumentFoundation.LibreOffice',         'Pacote office gratuito [OSS]'),
    @('VLC',                   'VideoLAN.VLC',                              'Player de audio e video [OSS]')
)
$pacotes = @{
    'P1' = @(1, 2, 4, 8, 11)  # Basico de campo
    'P2' = @(4, 5, 6, 7, 10, 12, 14, 16)  # Diagnostico
    'P3' = @(1, 23, 25)  # Estacao de usuario
}

Write-Host "`n=== Ferramentas de suporte (winget) ===" -ForegroundColor Cyan
for ($i = 0; $i -lt $apps.Count; $i++) {
    Write-Host ("[{0,2}] {1,-23} {2}" -f ($i + 1), $apps[$i][0], $apps[$i][2])
}
Write-Host "`n[P1] Basico de campo: 7-Zip, AnyDesk, CrystalDiskInfo, Notepad++, CPU-Z" -ForegroundColor Yellow
Write-Host "[P2] Diagnostico: CrystalDiskInfo/Mark, Sysinternals, IP Scanner, WinDirStat, HWiNFO, PuTTY, Wireshark" -ForegroundColor Yellow
Write-Host "[P3] Estacao de usuario: 7-Zip, Chrome, Acrobat Reader" -ForegroundColor Yellow
Write-Host "[T]  Todas    ([OSS] = codigo aberto)"

$resp = (Read-Host "`nEscolha (ex.: 1,4,7 ou P1). Enter para sair").Trim().ToUpper()
if (-not $resp) { return }

$sel = if ($resp -eq 'T') { 1..$apps.Count }
       elseif ($pacotes.ContainsKey($resp)) { $pacotes[$resp] }
       else { $resp -split '[,; ]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } }

$sel = $sel | Where-Object { $_ -ge 1 -and $_ -le $apps.Count } | Select-Object -Unique
if (-not $sel) { Write-Host "Nenhuma opcao valida."; return }

$falhas = @()
foreach ($n in $sel) {
    $a = $apps[$n - 1]
    Write-Host ("`n-> Instalando {0}..." -f $a[0]) -ForegroundColor Cyan
    winget install --id $a[1] --exact --silent --accept-package-agreements --accept-source-agreements --source winget
    # 0 = instalado; -1978335189 = ja instalado/sem atualizacao
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) { $falhas += $a[0] }
}

if ($falhas) { Write-Host ("`nNao instalados: {0}" -f ($falhas -join ', ')) -ForegroundColor Yellow }
else { Write-Host "`nOK: tudo instalado." -ForegroundColor Green }
