<#
.SYNOPSIS
  Impede bloqueio de tela, desligamento de tela e suspensao por inatividade. Salva os valores atuais e permite desfazer.
.NOTES
  Uso: computador que bloqueia/apaga a tela sozinho (caixa, painel, TV, maquina que roda tarefa longa).
  Muda no plano de energia ativo (rede e bateria): desligar tela, suspender, hibernar, pedir senha ao retomar;
  e no perfil do usuario: protecao de tela e senha ao sair dela. Nada e feito sem escolher 1 ou 2 no menu.
  Antes de mudar, grava os valores atuais em %LOCALAPPDATA%\SaitecToolkit\Nunca-Bloquear-backup.json. A opcao 2 restaura.
  LIMITE: politica de dominio/GPO/Intune pode sobrescrever (bloqueio por inatividade da politica de seguranca
  nao e removido por este script). O script avisa se achar politica; confira no final se a tela ainda bloqueia.
  Bloqueio manual (Win+L) continua funcionando. Roda sem Administrador (perfil do usuario atual).
#>
$Dir    = Join-Path $env:LOCALAPPDATA 'SaitecToolkit'
$Backup = Join-Path $Dir 'Nunca-Bloquear-backup.json'
$Log    = Join-Path $Dir 'Nunca-Bloquear.log'

function Write-Log([string]$msg) {
    try {
        if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Force -Path $Dir | Out-Null }
        Add-Content -Path $Log -Value ("{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg) -ErrorAction Stop
    } catch { }
}

# Configuracoes de energia: nome, subgrupo, alias
$Itens = @(
    @{ N = 'Desligar a tela (segundos)';  Sub = 'SUB_VIDEO'; Set = 'VIDEOIDLE' },
    @{ N = 'Suspender (segundos)';        Sub = 'SUB_SLEEP'; Set = 'STANDBYIDLE' },
    @{ N = 'Hibernar (segundos)';         Sub = 'SUB_SLEEP'; Set = 'HIBERNATEIDLE' },
    @{ N = 'Pedir senha ao retomar (1=sim, 0=nao)'; Sub = 'SUB_NONE'; Set = 'CONSOLELOCK' }
)
$ChavesSS = @('ScreenSaveActive', 'ScreenSaveTimeOut', 'ScreenSaverIsSecure')
$RegSS    = 'HKCU:\Control Panel\Desktop'

# Le CA e CC de uma configuracao. Pega os dois ultimos valores 0x... da saida (independe do idioma).
function Get-Energia([string]$sub, [string]$set) {
    $out = & powercfg.exe /query SCHEME_CURRENT $sub $set 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) { return $null }
    $hex = @([regex]::Matches(($out -join "`n"), '0x[0-9a-fA-F]{8}') | ForEach-Object { $_.Value })
    if ($hex.Count -lt 2) { return $null }
    return @{ AC = [Convert]::ToInt64($hex[$hex.Count - 2], 16); DC = [Convert]::ToInt64($hex[$hex.Count - 1], 16) }
}

function Get-EsquemaAtivo {
    $o = (& powercfg.exe /getactivescheme 2>$null) -join ' '
    if ($o -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { return $Matches[1] }
    return $null
}

function Show-Estado {
    Write-Host ("  {0,-42} {1,12} {2,12}" -f 'Configuracao', 'Na tomada', 'Na bateria')
    foreach ($i in $Itens) {
        $v = Get-Energia $i.Sub $i.Set
        if ($v) { Write-Host ("  {0,-42} {1,12} {2,12}" -f $i.N, $v.AC, $v.DC) }
        else    { Write-Host ("  {0,-42} {1,12}" -f $i.N, 'nao disponivel') -ForegroundColor DarkGray }
    }
    $d = Get-ItemProperty -Path $RegSS -ErrorAction SilentlyContinue
    foreach ($c in $ChavesSS) {
        $val = $null; if ($d -and ($d.PSObject.Properties.Name -contains $c)) { $val = $d.$c }
        if ($null -eq $val) { $val = '(nao definido)' }
        Write-Host ("  Protecao de tela: {0,-22} {1}" -f $c, $val)
    }
    Write-Host "  (0 = nunca; valores em segundos)" -ForegroundColor DarkGray
}

function Test-Politica {
    $achou = @()
    $caminhos = @(
        @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'InactivityTimeoutSecs'),
        @('HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop', 'ScreenSaveTimeOut'),
        @('HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop', 'ScreenSaverIsSecure'),
        @('HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings', '')
    )
    foreach ($c in $caminhos) {
        if ($c[1] -eq '') {
            if (Test-Path $c[0]) { $achou += "$($c[0]) (politica de energia)" }
        } else {
            $p = Get-ItemProperty -Path $c[0] -Name $c[1] -ErrorAction SilentlyContinue
            if ($p) { $achou += "$($c[0]) -> $($c[1]) = $($p.($c[1]))" }
        }
    }
    return $achou
}

function Show-Politica {
    $pol = @(Test-Politica)
    if ($pol.Count -gt 0) {
        Write-Host "  [!] Esta maquina tem politica de bloqueio/energia (GPO, Intune ou similar):" -ForegroundColor DarkYellow
        foreach ($p in $pol) { Write-Host "      $p" -ForegroundColor DarkYellow }
        Write-Host "      A politica pode reaplicar o bloqueio e desfazer o que este script fizer. Fale com quem administra o dominio." -ForegroundColor DarkYellow
    } else {
        Write-Host "  Nenhuma politica de bloqueio encontrada nos locais comuns (isso nao garante: GPO de dominio pode chegar depois)." -ForegroundColor DarkGray
    }
}

function Invoke-Aplicar {
    Write-Host "`n[1/4] Valores atuais" -ForegroundColor Cyan
    Show-Estado
    $esq = Get-EsquemaAtivo
    if (-not $esq) { Write-Host "  Nao consegui identificar o plano de energia ativo. Nada foi alterado." -ForegroundColor Red; return }

    Write-Host "`n[2/4] Backup" -ForegroundColor Cyan
    $fazer = $true
    if (Test-Path $Backup) {
        Write-Host "  Ja existe um backup: $Backup" -ForegroundColor DarkYellow
        Write-Host "  Se esta maquina ja esta em 'nunca bloquear', sobrescrever PERDE os valores originais." -ForegroundColor DarkYellow
        $r = Read-Host "  Sobrescrever o backup com os valores de agora? (S/N)"
        $fazer = ($r -match '^[sS]')
        if (-not $fazer) { Write-Host "  Mantendo o backup antigo (os valores originais continuam salvos)." }
    }
    if ($fazer) {
        $dados = @{ Data = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); Esquema = $esq; Energia = @(); Tela = @{} }
        foreach ($i in $Itens) {
            $v = Get-Energia $i.Sub $i.Set
            if ($v) { $dados.Energia += @{ Sub = $i.Sub; Set = $i.Set; AC = $v.AC; DC = $v.DC } }
        }
        $d = Get-ItemProperty -Path $RegSS -ErrorAction SilentlyContinue
        foreach ($c in $ChavesSS) {
            if ($d -and ($d.PSObject.Properties.Name -contains $c)) { $dados.Tela[$c] = [string]$d.$c } else { $dados.Tela[$c] = $null }
        }
        try {
            if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Force -Path $Dir | Out-Null }
            $dados | ConvertTo-Json -Depth 5 | Set-Content -Path $Backup -Encoding ASCII -ErrorAction Stop
        } catch {
            Write-Host ("  Backup falhou: {0}. Nada foi alterado." -f $_.Exception.Message) -ForegroundColor Red; return
        }
        if (-not (Test-Path $Backup)) { Write-Host "  Backup falhou. Nada foi alterado." -ForegroundColor Red; return }
        Write-Host "  Backup salvo: $Backup" -ForegroundColor Green
    }

    Write-Host "`n[3/4] Aplicando (tudo = 0, nunca)" -ForegroundColor Cyan
    $falhas = 0
    $pulados = @()
    foreach ($i in $Itens) {
        if (-not (Get-Energia $i.Sub $i.Set)) { $pulados += $i.N; continue }
        & powercfg.exe /setacvalueindex $esq $i.Sub $i.Set 0 2>$null
        $a = $LASTEXITCODE
        & powercfg.exe /setdcvalueindex $esq $i.Sub $i.Set 0 2>$null
        if ($a -ne 0 -or $LASTEXITCODE -ne 0) { $falhas++; Write-Host ("  Falhou: {0}" -f $i.N) -ForegroundColor Red }
    }
    & powercfg.exe /setactive $esq 2>$null
    try {
        Set-ItemProperty -Path $RegSS -Name 'ScreenSaveActive'     -Value '0' -ErrorAction Stop
        Set-ItemProperty -Path $RegSS -Name 'ScreenSaverIsSecure'  -Value '0' -ErrorAction Stop
    } catch { $falhas++; Write-Host ("  Falhou protecao de tela: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    Write-Log ("Aplicado (falhas: {0})" -f $falhas)

    Write-Host "`n[4/4] Conferindo" -ForegroundColor Cyan
    Show-Estado
    $ok = $true
    foreach ($i in $Itens) {
        $v = Get-Energia $i.Sub $i.Set
        if ($v -and ($v.AC -ne 0 -or $v.DC -ne 0)) { $ok = $false; Write-Host ("  [!] {0} nao ficou em 0." -f $i.N) -ForegroundColor DarkYellow }
    }
    Show-Politica
    if ($pulados.Count -gt 0) {
        Write-Host ("`n  [!] Nao aplicado (este Windows nao expoe a opcao): {0}" -f ($pulados -join ', ')) -ForegroundColor DarkYellow
        Write-Host "      Se pedir senha ao acordar: Configuracoes > Contas > Opcoes de entrada > 'Exigir entrada' = Nunca." -ForegroundColor DarkYellow
    }
    if ($ok -and $falhas -eq 0 -and $pulados.Count -eq 0) {
        Write-Host "`n  OK: valores aplicados. Para ter certeza, deixe a maquina parada alguns minutos e veja se a tela bloqueia." -ForegroundColor Green
        Write-Host "  Win+L (bloqueio manual) continua funcionando. Para voltar ao normal: opcao 2." -ForegroundColor DarkGray
    } else {
        Write-Host "`n  Nem tudo foi aplicado. Veja os avisos acima (politica de dominio costuma ser a causa)." -ForegroundColor DarkYellow
    }
}

function Invoke-Desfazer {
    if (-not (Test-Path $Backup)) {
        Write-Host "`n  Nao existe backup ($Backup). Nada para restaurar." -ForegroundColor DarkYellow; return
    }
    try { $b = Get-Content -Path $Backup -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
    catch { Write-Host ("`n  Backup ilegivel: {0}" -f $_.Exception.Message) -ForegroundColor Red; return }

    Write-Host ("`n[1/3] Backup de {0}" -f $b.Data) -ForegroundColor Cyan
    foreach ($e in @($b.Energia)) { Write-Host ("  {0}/{1}: tomada {2}, bateria {3}" -f $e.Sub, $e.Set, $e.AC, $e.DC) }
    foreach ($c in $ChavesSS) { Write-Host ("  Protecao de tela {0}: {1}" -f $c, $(if ($null -eq $b.Tela.$c) { '(nao definido)' } else { $b.Tela.$c })) }
    $r = Read-Host "  Restaurar estes valores? (S/N)"
    if ($r -notmatch '^[sS]') { Write-Host "  Cancelado. Nada foi alterado."; return }

    Write-Host "`n[2/3] Restaurando" -ForegroundColor Cyan
    $esq = Get-EsquemaAtivo
    if ($esq -and $esq -ne $b.Esquema) {
        Write-Host "  O plano de energia ativo mudou desde o backup; restaurando no plano ativo agora." -ForegroundColor DarkYellow
    }
    if (-not $esq) { $esq = $b.Esquema }
    $falhas = 0
    foreach ($e in @($b.Energia)) {
        & powercfg.exe /setacvalueindex $esq $e.Sub $e.Set ([int64]$e.AC) 2>$null
        $a = $LASTEXITCODE
        & powercfg.exe /setdcvalueindex $esq $e.Sub $e.Set ([int64]$e.DC) 2>$null
        if ($a -ne 0 -or $LASTEXITCODE -ne 0) { $falhas++; Write-Host ("  Falhou: {0}" -f $e.Set) -ForegroundColor Red }
    }
    & powercfg.exe /setactive $esq 2>$null
    foreach ($c in $ChavesSS) {
        try {
            if ($null -eq $b.Tela.$c) { Remove-ItemProperty -Path $RegSS -Name $c -ErrorAction SilentlyContinue }
            else { Set-ItemProperty -Path $RegSS -Name $c -Value ([string]$b.Tela.$c) -ErrorAction Stop }
        } catch { $falhas++; Write-Host ("  Falhou protecao de tela {0}" -f $c) -ForegroundColor Red }
    }
    Write-Log ("Desfeito (falhas: {0})" -f $falhas)

    Write-Host "`n[3/3] Conferindo" -ForegroundColor Cyan
    Show-Estado
    if ($falhas -eq 0) {
        Write-Host "`n  OK: valores originais restaurados. O arquivo de backup foi mantido: $Backup" -ForegroundColor Green
    } else {
        Write-Host "`n  Restauracao incompleta. Confira em Configuracoes > Sistema > Energia." -ForegroundColor DarkYellow
    }
}

# ---------------------------------------------------------------
# Menu
# ---------------------------------------------------------------
if (-not (Get-Command powercfg.exe -ErrorAction SilentlyContinue)) {
    Write-Host "powercfg nao encontrado. Este script e so para Windows." -ForegroundColor Red; return
}
while ($true) {
    Write-Host "`n=== Nunca bloquear o computador ===" -ForegroundColor Cyan
    Show-Estado
    Write-Host ""
    Write-Host "  1) Aplicar (nunca apagar tela, suspender ou bloquear por inatividade)"
    Write-Host "  2) Desfazer (restaurar os valores salvos)"
    Write-Host "  0) Sair"
    $op = (Read-Host "Escolha").Trim()
    switch ($op) {
        '1' { Invoke-Aplicar }
        '2' { Invoke-Desfazer }
        '0' { Write-Host "Concluido." -ForegroundColor Green; return }
        default { Write-Host "Opcao invalida." -ForegroundColor Red }
    }
}
