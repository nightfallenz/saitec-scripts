<#
.SYNOPSIS
  Corrige a pesquisa do menu Iniciar que nao abre, nao deixa digitar ou fica em branco.
.NOTES
  Etapas: reinicia os processos do Iniciar/Pesquisa, religa o servico de entrada de texto (ctfmon),
  confere o Windows Search e registra de novo os pacotes do Iniciar e da Pesquisa do usuario.
  Opcional: reconstruir o indice de pesquisa (pede Administrador).
  Rodar como o PROPRIO usuario.
#>
Write-Host "1/5 Reiniciando Iniciar e Pesquisa..." -ForegroundColor Cyan
Get-Process -Name SearchHost, SearchApp, SearchUI, StartMenuExperienceHost, ShellExperienceHost -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "2/5 Conferindo entrada de texto (ctfmon)..." -ForegroundColor Cyan
# Sem o ctfmon a caixa de pesquisa abre mas nao aceita digitacao
if (-not (Get-Process -Name ctfmon -ErrorAction SilentlyContinue)) {
    Start-Process "$env:SystemRoot\System32\ctfmon.exe" -ErrorAction SilentlyContinue
    Write-Host "   ctfmon estava parado e foi iniciado." -ForegroundColor Yellow
} else { Write-Host "   ctfmon rodando." }

Write-Host "3/5 Conferindo servico Windows Search..." -ForegroundColor Cyan
$ws = Get-Service WSearch -ErrorAction SilentlyContinue
if (-not $ws) { Write-Host "   Servico WSearch nao existe nesta maquina." -ForegroundColor Yellow }
elseif ($ws.Status -ne 'Running') {
    Write-Host ("   WSearch esta {0} (inicio: {1}). Sera corrigido na etapa de Administrador, se voce aceitar." -f $ws.Status, $ws.StartType) -ForegroundColor Yellow
} else { Write-Host "   WSearch rodando." }

Write-Host "4/5 Registrando novamente os pacotes do Iniciar e da Pesquisa..." -ForegroundColor Cyan
$pacotes = 'Microsoft.Windows.StartMenuExperienceHost', 'Microsoft.Windows.ShellExperienceHost',
           'Microsoft.Windows.Search', 'MicrosoftWindows.Client.CBS', 'Microsoft.Windows.Cortana'
foreach ($nome in $pacotes) {
    Get-AppxPackage -Name $nome -ErrorAction SilentlyContinue | ForEach-Object {
        $man = Join-Path $_.InstallLocation 'AppxManifest.xml'
        if (Test-Path $man) {
            try { Add-AppxPackage -DisableDevelopmentMode -Register $man -ErrorAction Stop; Write-Host "   OK: $nome" }
            catch { Write-Host "   Em uso, ignorado: $nome" -ForegroundColor DarkGray }
        }
    }
}

Write-Host "5/5 Reabrindo o Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }

Write-Host "`nTeste agora: tecla Windows e digite algo." -ForegroundColor Green
Write-Host "Se continuar falhando, a proxima etapa religa o Windows Search e reconstroi o indice (pede Administrador, leva alguns minutos)."
if ((Read-Host "Reconstruir o indice agora? (S/N)") -match '^[sS]') {
    $cmd = @'
Set-Service WSearch -StartupType Automatic
Stop-Service WSearch -Force -ErrorAction SilentlyContinue
$dir = Join-Path $env:ProgramData 'Microsoft\Search\Data\Applications\Windows'
Remove-Item (Join-Path $dir 'Windows.edb') -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $dir 'Windows.db') -Force -ErrorAction SilentlyContinue
Start-Service WSearch
Write-Host 'Indice apagado e Windows Search reiniciado. A reindexacao roda em segundo plano.' -ForegroundColor Green
Start-Sleep -Seconds 4
'@
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
    try { Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc" -Wait }
    catch { Write-Host "Elevacao cancelada." -ForegroundColor Yellow }
}
