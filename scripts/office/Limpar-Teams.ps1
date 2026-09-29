<#
.SYNOPSIS
  Limpa o cache do Microsoft Teams (novo e classico) do usuario atual.
.NOTES
  Uso: Teams nao abre, tela branca, nao carrega mensagens, loop de login.
  Rodar como o PROPRIO usuario (nao precisa de Administrador). O Teams sera fechado.
  Apos limpar, o usuario pode precisar fazer login de novo.
#>
Write-Host "Fechando o Teams..." -ForegroundColor Cyan
Get-Process -Name ms-teams, Teams, msteams -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Teams novo (app da Store)
$novo = Join-Path $env:LOCALAPPDATA 'Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams'
if (Test-Path $novo) {
    Remove-Item "$novo\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cache do Teams (novo) limpo." -ForegroundColor Green
}

# Teams classico
$classico = Join-Path $env:APPDATA 'Microsoft\Teams'
if (Test-Path $classico) {
    foreach ($p in 'Cache','blob_storage','databases','GPUCache','IndexedDB','Local Storage','tmp','Code Cache','Service Worker') {
        Remove-Item (Join-Path $classico $p) -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Cache do Teams (classico) limpo." -ForegroundColor Green
}

if (-not (Test-Path $novo) -and -not (Test-Path $classico)) {
    Write-Host "Nenhuma pasta do Teams encontrada para este usuario." -ForegroundColor Yellow
    return
}

if ((Read-Host "Abrir o Teams agora? (S/N)") -match '^[sS]') {
    Start-Process 'ms-teams:' -ErrorAction SilentlyContinue
}
