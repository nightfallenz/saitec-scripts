<#
.SYNOPSIS
  Saitec Toolkit - menu central dos scripts da equipe.
.DESCRIPTION
  Funciona de dois jeitos:
   - Online:   irm https://raw.githubusercontent.com/nightfallenz/saitec-scripts/main/saitec-toolkit.ps1 | iex
   - Pendrive: extraia o .zip do repositorio e rode Iniciar.bat
  Abra o PowerShell como o USUARIO logado (sem "Executar como administrador").
  Os itens marcados [ADM] pedem elevacao (UAC) sozinhos; os itens [USR] rodam no
  perfil do usuario, que e onde ficam cache do Teams, credenciais e OneDrive.
#>

$Repo   = 'nightfallenz/saitec-scripts'
$Branch = 'main'
$Raw    = "https://raw.githubusercontent.com/$Repo/$Branch"

try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

$Local = $PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'scripts'))
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chave | Categoria | Nome | Caminho no repo | Admin? | Descricao
$Itens = @(
    @('1',  'IMPRESSORAS', 'Destravar spooler e limpar fila',       'scripts/impressoras/Reset-Spooler.ps1',             $true,  'Fila presa, nao imprime'),
    @('2',  'IMPRESSORAS', 'Listar / remover impressora e driver',  'scripts/impressoras/Gerenciar-Impressoras.ps1',     $true,  'Driver corrompido, duplicada'),
    @('3',  'IMPRESSORAS', 'Adicionar impressora pelo IP',          'scripts/impressoras/Adicionar-Impressora-IP.ps1',   $true,  'Sem servidor de impressao'),
    @('4',  'REDE',        'Diagnostico de rede (nao altera)',      'scripts/rede/Diagnostico-Rede.ps1',                 $false, 'Gateway, internet, DNS, 443'),
    @('5',  'REDE',        'Reset completo de rede',                'scripts/rede/Reset-Rede.ps1',                       $true,  'DNS, IP, Winsock, proxy'),
    @('6',  'DOMINIO',     'Corrigir wallpaper preto da GPO',       'scripts/dominio/Corrigir-Wallpaper-Dominio.ps1',    $false, 'TranscodedWallpaper, NETLOGON'),
    @('7',  'DOMINIO',     'Atualizar GPO + relatorio',             'scripts/dominio/Atualizar-GPO.ps1',                 $false, 'gpupdate e gpresult HTML'),
    @('8',  'DOMINIO',     'Unidades de rede mapeadas',             'scripts/dominio/Unidades-Rede.ps1',                 $false, 'X vermelho, pasta sumiu'),
    @('9',  'DOMINIO',     'Reparar relacao de confianca',          'scripts/dominio/Reparar-Relacao-Dominio.ps1',       $true,  'Sem sair do dominio'),
    @('10', 'DOMINIO',     'Sincronizar hora',                      'scripts/dominio/Sincronizar-Hora.ps1',              $true,  'Kerberos, hora errada'),
    @('11', 'DOMINIO',     'Corrigir perfil temporario',            'scripts/dominio/Perfil-Temporario.ps1',             $true,  'Entrada .bak no registro'),
    @('12', 'SISTEMA',     'Ficha da maquina para o chamado',       'scripts/sistema/Info-Sistema.ps1',                  $false, 'Serial, modelo, IP, Windows'),
    @('13', 'SISTEMA',     'Reparar Windows (DISM + SFC)',          'scripts/sistema/Reparar-Windows.ps1',               $true,  '10 a 40 min'),
    @('14', 'SISTEMA',     'Resetar Windows Update',                'scripts/sistema/Reset-WindowsUpdate.ps1',           $true,  'Update travado ou com erro'),
    @('15', 'SISTEMA',     'Limpeza rapida de disco',               'scripts/sistema/Limpeza-Rapida.ps1',                $true,  'Temp, dumps, lixeira'),
    @('16', 'SISTEMA',     'Saude dos discos (SMART)',              'scripts/sistema/Saude-Disco.ps1',                   $true,  'Desgaste, erros, temperatura'),
    @('17', 'SISTEMA',     'Status do BitLocker',                   'scripts/sistema/Status-BitLocker.ps1',              $true,  'ID da chave de recuperacao'),
    @('18', 'SISTEMA',     'Inicializacao rapida liga/desliga',     'scripts/sistema/Inicializacao-Rapida.ps1',          $true,  'Uptime alto, update preso'),
    @('19', 'SISTEMA',     'Reiniciar Explorer e cache de icones',  'scripts/sistema/Reiniciar-Explorer.ps1',            $false, 'Barra/menu Iniciar travado'),
    @('20', 'SISTEMA',     'Reparar Store e apps nativos',          'scripts/sistema/Reparar-Store-Apps.ps1',            $false, 'Store, Calculadora, Fotos'),
    @('21', 'SISTEMA',     'Manutencao preventiva completa (.bat)', 'scripts/manutencao/Manutencao_Windows.bat',         $true,  'Menu com todas as rotinas'),
    @('22', 'OFFICE',      'Limpar cache do Teams',                 'scripts/office/Limpar-Teams.ps1',                   $false, 'Tela branca, nao abre'),
    @('23', 'OFFICE',      'Limpar credenciais do Office',          'scripts/office/Limpar-Credenciais-Office.ps1',      $false, 'Outlook pedindo senha'),
    @('24', 'OFFICE',      'Resetar OneDrive',                      'scripts/office/Reset-OneDrive.ps1',                 $false, 'Sincronizacao parada'),
    @('25', 'OFFICE',      'Reparar Office (rapido/online)',        'scripts/office/Reparar-Office.ps1',                 $true,  'Office travando'),
    @('26', 'FERRAMENTAS', 'Instalar ferramentas de suporte',       'scripts/ferramentas/Instalar-Ferramentas.ps1',      $true,  'winget, fontes oficiais'),
    @('27', 'FERRAMENTAS', 'Chris Titus WinUtil (debloat/tweaks)',  'WINUTIL',                                           $true,  'Somente Windows 11')
)

function Get-Script([string]$rel) {
    if ($Local) { return (Join-Path $PSScriptRoot ($rel -replace '/', '\')) }
    $dest = Join-Path $env:TEMP ('saitec-toolkit\' + ($rel -replace '/', '\'))
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Invoke-WebRequest -Uri "$Raw/$rel" -OutFile $dest -UseBasicParsing -ErrorAction Stop
    return $dest
}

function Start-WinUtil {
    $build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
    if ($build -lt 22000) {
        Write-Host "Esta maquina e Windows 10 (build $build). O WinUtil oficialmente suporta so Windows 11." -ForegroundColor Yellow
        if ((Read-Host "Abrir mesmo assim? (S/N)") -notmatch '^[sS]') { return }
    }
    Write-Host "Crie um ponto de restauracao antes de aplicar tweaks (o WinUtil tem essa opcao)." -ForegroundColor Yellow
    $cmd = "irm 'https://christitus.com/win' | iex"
    if ($IsAdmin) { Invoke-Expression $cmd }
    else { Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $cmd" }
}

function Invoke-ToolItem($item) {
    $rel = $item[3]; $precisaAdm = $item[4]
    if ($rel -eq 'WINUTIL') { Start-WinUtil; return }

    try { $path = Get-Script $rel }
    catch { Write-Host "Falha ao baixar $rel : $($_.Exception.Message)" -ForegroundColor Red; return }

    if ($path -like '*.bat') {
        Start-Process -FilePath $path          # o .bat pede elevacao sozinho
        return
    }
    if ($precisaAdm -and -not $IsAdmin) {
        Write-Host "Abrindo em janela de Administrador..." -ForegroundColor Cyan
        $arg = "-NoProfile -ExecutionPolicy Bypass -Command `"& '$path'; Write-Host ''; Read-Host 'Enter para fechar'`""
        try { Start-Process powershell -Verb RunAs -ArgumentList $arg -Wait }
        catch { Write-Host "Elevacao cancelada." -ForegroundColor Yellow }
    } else {
        & ([scriptblock]::Create((Get-Content -Path $path -Raw)))
    }
}

while ($true) {
    Clear-Host
    $modo = if ($Local) { 'pendrive' } else { 'online' }
    $quem = if ($IsAdmin) { 'Administrador' } else { $env:USERNAME }
    Write-Host "==============================================================" -ForegroundColor DarkCyan
    Write-Host "  SAITEC TOOLKIT       |   $env:COMPUTERNAME   |   $quem   |   $modo" -ForegroundColor Cyan
    Write-Host "==============================================================" -ForegroundColor DarkCyan
    $cat = ''
    foreach ($i in $Itens) {
        if ($i[1] -ne $cat) { $cat = $i[1]; Write-Host "`n $cat" -ForegroundColor Yellow }
        $tag = if ($i[4]) { '[ADM]' } else { '[USR]' }
        Write-Host (" {0,3}  {1} {2,-38} {3}" -f $i[0], $tag, $i[2], $i[5])
    }
    Write-Host "`n   0  Sair" -ForegroundColor DarkGray
    if ($IsAdmin) {
        Write-Host "`n Aviso: rodando como Administrador. Itens [USR] vao agir no perfil desta conta, nao no do usuario." -ForegroundColor DarkYellow
    }

    $op = (Read-Host "`n Opcao").Trim()
    if ($op -eq '0' -or $op -eq '') { break }
    $item = $Itens | Where-Object { $_[0] -eq $op } | Select-Object -First 1
    if (-not $item) { continue }

    Write-Host "`n>>> $($item[2])`n" -ForegroundColor Cyan
    Invoke-ToolItem $item
    Read-Host "`n Enter para voltar ao menu" | Out-Null
}
