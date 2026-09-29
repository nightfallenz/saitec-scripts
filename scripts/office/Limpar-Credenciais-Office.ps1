<#
.SYNOPSIS
  Remove credenciais salvas do Office/Teams/OneDrive no Gerenciador de Credenciais do usuario.
.NOTES
  Uso: Outlook pedindo senha em loop, "precisamos que voce entre", conta errada presa no Office.
  Rodar como o PROPRIO usuario. Feche o Office antes. O usuario precisara fazer login de novo.
#>
$padroes = 'MicrosoftOffice', 'msteams', 'OneDrive Cached Credential', 'Microsoft_OC', 'ADAL', 'MSOID', 'Outlook'

$entradas = cmdkey /list | Select-String 'Destino:|Target:' | ForEach-Object {
    ($_ -replace '.*(Destino|Target):\s*', '').Trim()
} | Where-Object {
    $alvo = $_
    $padroes | Where-Object { $alvo -like "*$_*" }
}

if (-not $entradas) { Write-Host "Nenhuma credencial do Office encontrada." -ForegroundColor Yellow; return }

Write-Host "Credenciais encontradas:" -ForegroundColor Cyan
$entradas | ForEach-Object { Write-Host "  $_" }

if ((Read-Host "`nRemover todas as listadas? (S/N)") -notmatch '^[sS]') { return }

Get-Process -Name OUTLOOK, WINWORD, EXCEL, POWERPNT, ms-teams, Teams -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

foreach ($e in $entradas) {
    cmdkey /delete:$e | Out-Null
    Write-Host "Removida: $e" -ForegroundColor Green
}

# Cache de identidade do Office (tokens)
Remove-Item "$env:LOCALAPPDATA\Microsoft\IdentityCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\OneAuth\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nOK: abra o Outlook e faca login novamente." -ForegroundColor Green
