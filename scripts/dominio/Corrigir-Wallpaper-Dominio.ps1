<#
.SYNOPSIS
  Corrige wallpaper de dominio preto ou que nao aplica (imagem do NETLOGON/GPO).
.NOTES
  Uso: fundo preto em vez da imagem da empresa, wallpaper antigo preso.
  Causa comum: cache corrompido (TranscodedWallpaper) ou caminho da GPO inacessivel.
  Rodar como o PROPRIO usuario (nao precisa de Administrador).
#>
if (-not ('Win32.Wp' -as [type])) {
Add-Type -Namespace Win32 -Name Wp -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
'@
}

$pol = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
$caminho = (Get-ItemProperty $pol -Name Wallpaper -ErrorAction SilentlyContinue).Wallpaper

Write-Host "=== Diagnostico ===" -ForegroundColor Cyan
if (-not $caminho) {
    Write-Host "Nenhum wallpaper definido por GPO para este usuario." -ForegroundColor Yellow
    Write-Host "Rodando gpupdate para tentar receber a politica..."
    gpupdate /target:user /force | Out-Null
    $caminho = (Get-ItemProperty $pol -Name Wallpaper -ErrorAction SilentlyContinue).Wallpaper
    if (-not $caminho) {
        Write-Host "A GPO de wallpaper nao chegou. Confira se o usuario esta na OU certa (use o item 'Atualizar GPO')." -ForegroundColor Red
        return
    }
}
$caminho = [Environment]::ExpandEnvironmentVariables($caminho)
Write-Host "Caminho da GPO: $caminho"

if (Test-Path -LiteralPath $caminho) {
    $f = Get-Item -LiteralPath $caminho
    Write-Host ("[ OK ] Arquivo acessivel ({0:N0} KB, {1})" -f ($f.Length/1KB), $f.Extension) -ForegroundColor Green
    if ($f.Length -eq 0) { Write-Host "[FALHA] Arquivo com 0 bytes no servidor." -ForegroundColor Red }
} else {
    Write-Host "[FALHA] O usuario NAO consegue ler o arquivo." -ForegroundColor Red
    if ($caminho -like '\\*') {
        $srv = ($caminho -split '\\')[2]
        $ok = Test-Connection $srv -Count 1 -Quiet
        Write-Host ("        Servidor {0} responde ao ping: {1}" -f $srv, $(if ($ok) {'sim'} else {'NAO'}))
        Write-Host "        Verifique permissao de leitura para Domain Users no compartilhamento e no arquivo."
    }
    Write-Host "Sem acesso ao arquivo, o Windows mostra fundo preto. Corrija o acesso e rode de novo." -ForegroundColor Yellow
    return
}

Write-Host "`n=== Correcao ===" -ForegroundColor Cyan
$themes = Join-Path $env:APPDATA 'Microsoft\Windows\Themes'
Write-Host "Limpando cache do wallpaper (TranscodedWallpaper e CachedFiles)..."
Remove-Item (Join-Path $themes 'TranscodedWallpaper') -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $themes 'CachedFiles\*') -Force -ErrorAction SilentlyContinue

Write-Host "Atualizando politicas do usuario..."
gpupdate /target:user /force | Out-Null

Write-Host "Aplicando a imagem..."
# SPI_SETDESKWALLPAPER = 20; SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 3
$r = [Win32.Wp]::SystemParametersInfo(20, 0, $caminho, 3)
if ($r -ne 0) {
    Write-Host "OK: wallpaper reaplicado." -ForegroundColor Green
} else {
    Write-Host "O Windows recusou aplicar a imagem. Faca logoff/logon; se continuar preto, teste o arquivo em JPG." -ForegroundColor Yellow
}
