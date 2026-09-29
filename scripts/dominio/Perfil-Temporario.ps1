<#
.SYNOPSIS
  Detecta e corrige usuario logando com PERFIL TEMPORARIO (entrada .bak no registro).
.NOTES
  Uso: "Voce foi conectado com um perfil temporario", area de trabalho vazia a cada logon.
  O usuario afetado precisa estar DESLOGADO. Faz backup do registro antes de alterar.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$base = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
$chaves = Get-ChildItem $base | Where-Object { $_.PSChildName -like 'S-1-5-21-*' }

Write-Host "=== Perfis de usuario ===" -ForegroundColor Cyan
foreach ($k in $chaves) {
    $p = Get-ItemProperty $k.PSPath
    $tag = if ($k.PSChildName -like '*.bak') { '  <-- .bak' } else { '' }
    Write-Host ("{0,-60} {1}{2}" -f $k.PSChildName, $p.ProfileImagePath, $tag)
}

$baks = $chaves | Where-Object { $_.PSChildName -like '*.bak' }
if (-not $baks) { Write-Host "`nNenhuma entrada .bak. O perfil temporario tem outra causa (disco cheio, permissao na pasta, antivirus)." -ForegroundColor Yellow; return }

$backup = Join-Path $env:TEMP ("ProfileList_{0}.reg" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
reg export 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' $backup /y | Out-Null
Write-Host "`nBackup do registro salvo em: $backup" -ForegroundColor Gray

foreach ($b in $baks) {
    $sid = $b.PSChildName -replace '\.bak$', ''
    $pasta = (Get-ItemProperty $b.PSPath).ProfileImagePath
    Write-Host ("`nSID {0} -> {1}" -f $sid, $pasta) -ForegroundColor Yellow
    if (-not (Test-Path $pasta)) { Write-Host "A pasta do perfil nao existe mais. Nao da para recuperar por aqui." -ForegroundColor Red; continue }
    if ((Read-Host "Corrigir este perfil? O usuario precisa estar deslogado (S/N)") -notmatch '^[sS]') { continue }

    $novo = Join-Path $base $sid
    if (Test-Path $novo) {
        Remove-Item $novo -Recurse -Force        # entrada temporaria criada pelo Windows
        Write-Host "Entrada temporaria removida."
    }
    Rename-Item -Path $b.PSPath -NewName $sid
    Set-ItemProperty -Path $novo -Name State -Value 0 -Type DWord
    Set-ItemProperty -Path $novo -Name RefCount -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "OK: perfil restaurado. Reinicie a maquina e faca logon com o usuario." -ForegroundColor Green
}
