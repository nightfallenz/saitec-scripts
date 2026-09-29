<#
.SYNOPSIS
  Forca a atualizacao das GPOs e gera relatorio HTML do que foi aplicado (gpresult).
.NOTES
  Uso: politica nao aplicou (wallpaper, mapeamento, impressora, restricoes).
  Rodar como o PROPRIO usuario para ver as politicas de usuario dele.
#>
Write-Host "Atualizando politicas (computador e usuario)..." -ForegroundColor Cyan
gpupdate /force

$rel = Join-Path $env:TEMP ("gpresult_{0}_{1}.html" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd_HHmm'))
Write-Host "`nGerando relatorio em $rel ..." -ForegroundColor Cyan
gpresult /h $rel /f | Out-Null

if (Test-Path $rel) {
    Write-Host "OK: relatorio gerado. Veja 'GPOs aplicadas' e 'GPOs negadas' para o usuario e o computador." -ForegroundColor Green
    Start-Process $rel
} else {
    Write-Host "Nao foi possivel gerar o relatorio. Resumo em texto:" -ForegroundColor Yellow
    gpresult /r
}

$dc = $env:LOGONSERVER -replace '\\', ''
if ($dc) { Write-Host "Controlador de dominio que autenticou: $dc" }
