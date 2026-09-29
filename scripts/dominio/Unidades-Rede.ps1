<#
.SYNOPSIS
  Mostra as unidades de rede mapeadas, testa o acesso e reconecta as que cairam.
.NOTES
  Uso: unidade com X vermelho, "caminho de rede nao encontrado", pasta do setor sumiu.
  Rodar como o PROPRIO usuario (os mapeamentos sao por usuario).
#>
$mapas = Get-CimInstance Win32_MappedLogicalDisk -ErrorAction SilentlyContinue
$persist = Get-ChildItem 'HKCU:\Network' -ErrorAction SilentlyContinue | ForEach-Object {
    [pscustomobject]@{ Letra = "$($_.PSChildName.ToUpper()):"; Caminho = (Get-ItemProperty $_.PSPath).RemotePath }
}

if (-not $persist -and -not $mapas) { Write-Host "Nenhuma unidade de rede mapeada para este usuario." -ForegroundColor Yellow; return }

Write-Host "=== Unidades de rede ===" -ForegroundColor Cyan
$todas = @($persist) + @($mapas | ForEach-Object { [pscustomobject]@{ Letra = $_.DeviceID; Caminho = $_.ProviderName } }) |
    Where-Object { $_.Caminho } | Sort-Object Letra -Unique

$quebradas = @()
foreach ($u in $todas) {
    $ok = Test-Path -LiteralPath "$($u.Letra)\" -ErrorAction SilentlyContinue
    if ($ok) { Write-Host ("[ OK ] {0} -> {1}" -f $u.Letra, $u.Caminho) -ForegroundColor Green }
    else {
        $srvOk = Test-Path -LiteralPath $u.Caminho -ErrorAction SilentlyContinue
        $motivo = if ($srvOk) { 'caminho acessivel, unidade desconectada' } else { 'sem acesso ao caminho (rede, permissao ou servidor)' }
        Write-Host ("[FALHA] {0} -> {1}  ({2})" -f $u.Letra, $u.Caminho, $motivo) -ForegroundColor Red
        $quebradas += $u
    }
}

if (-not $quebradas) { Write-Host "`nTodas as unidades estao acessiveis." -ForegroundColor Green; return }
if ((Read-Host "`nTentar reconectar as unidades com falha? (S/N)") -notmatch '^[sS]') { return }

foreach ($u in $quebradas) {
    net use $u.Letra /delete /y 2>&1 | Out-Null
    net use $u.Letra $u.Caminho /persistent:yes 2>&1 | Out-Null
    if (Test-Path -LiteralPath "$($u.Letra)\") { Write-Host "Reconectada: $($u.Letra)" -ForegroundColor Green }
    else { Write-Host "Nao reconectou: $($u.Letra). Teste abrir $($u.Caminho) no Explorer para ver o erro." -ForegroundColor Yellow }
}
