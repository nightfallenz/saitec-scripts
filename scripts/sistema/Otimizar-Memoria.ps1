<#
.SYNOPSIS
  Diagnostico de memoria (RAM e paginacao): mostra quem consome, sinais de problema e acoes opcionais com confirmacao.
.NOTES
  Uso: maquina lenta, "memoria insuficiente", travando com varios programas abertos.
  Nao usa "limpador de RAM": isso nao existe de forma segura. O script mostra os fatos e so age com S/N seu.
  Acoes opcionais (sempre perguntam): reiniciar Explorer, encerrar processo por PID, paginacao automatica.
  Requer Administrador.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red; return
}

$LogDir = Join-Path $env:ProgramData 'SaitecToolkit'
$Log    = Join-Path $LogDir 'Otimizar-Memoria.log'

function Write-Log([string]$msg) {
    try {
        if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
        Add-Content -Path $Log -Value ("{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg) -ErrorAction Stop
    } catch { }
}

function Confirm-SN([string]$pergunta) {
    return ((Read-Host "$pergunta (S/N)") -match '^[sS]')
}

# Processos que nunca devem ser encerrados por aqui
$Protegidos = @('System','Idle','Registry','smss','csrss','wininit','winlogon','services','lsass','svchost','dwm','fontdrvhost','MsMpEng','Memory Compression','explorer','lsm','audiodg','spoolsv','sihost','taskhostw','ctfmon','RuntimeBroker','WmiPrvSE','dllhost','NisSrv','SecurityHealthService','MsSense')

# ---------------------------------------------------------------
# 1) Memoria atual
# ---------------------------------------------------------------
Write-Host "`n[1/4] Memoria e arquivo de paginacao" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$totalGB = $os.TotalVisibleMemorySize / 1MB          # KB -> GB
$livreGB = $os.FreePhysicalMemory / 1MB
$perf = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction SilentlyContinue
if ($perf -and $perf.AvailableMBytes) { $dispGB = $perf.AvailableMBytes / 1024 } else { $dispGB = $livreGB }
$usoGB  = $totalGB - $dispGB
$usoPct = [math]::Round(($usoGB / $totalGB) * 100)

$commitLimGB = $os.TotalVirtualMemorySize / 1MB
$commitUsoGB = ($os.TotalVirtualMemorySize - $os.FreeVirtualMemory) / 1MB
$commitPct   = [math]::Round(($commitUsoGB / $commitLimGB) * 100)

Write-Host ("  RAM total ........ {0:N1} GB" -f $totalGB)
Write-Host ("  RAM disponivel ... {0:N1} GB (livre + cache que o Windows devolve quando precisa)" -f $dispGB)
Write-Host ("  RAM em uso ....... {0:N1} GB ({1}%)" -f $usoGB, $usoPct)
Write-Host ("  Commit ........... {0:N1} GB de {1:N1} GB ({2}%)" -f $commitUsoGB, $commitLimGB, $commitPct)

$pfUso = @(Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue)
$auto  = [bool]$cs.AutomaticManagedPagefile
$pfTotalMB = 0
if ($pfUso.Count -gt 0) {
    foreach ($p in $pfUso) {
        $pfTotalMB += $p.AllocatedBaseSize
        Write-Host ("  Paginacao ........ {0}  tamanho {1} MB, em uso {2} MB" -f $p.Name, $p.AllocatedBaseSize, $p.CurrentUsage)
    }
} else {
    Write-Host "  Paginacao ........ nenhuma ativa" -ForegroundColor DarkYellow
}
if ($auto) { Write-Host "  Gerenciada pelo sistema: sim" } else { Write-Host "  Gerenciada pelo sistema: nao" }

Write-Host "`n  Top 15 processos por memoria (Working Set):" -ForegroundColor Cyan
$procs = @(Get-Process -ErrorAction SilentlyContinue)
$contagem = @{}
foreach ($p in $procs) { $contagem[$p.ProcessName] = 1 + [int]$contagem[$p.ProcessName] }
$top = $procs | Sort-Object WorkingSet64 -Descending | Select-Object -First 15
Write-Host ("  {0,7}  {1,-28} {2,10}  {3}" -f 'PID', 'Processo', 'MB', 'Instancias do mesmo nome')
foreach ($p in $top) {
    Write-Host ("  {0,7}  {1,-28} {2,10:N0}  {3}" -f $p.Id, $p.ProcessName, ($p.WorkingSet64 / 1MB), $contagem[$p.ProcessName])
}
Write-Host "  (navegador com muitas abas aparece em varias linhas: some as linhas do mesmo nome)" -ForegroundColor DarkGray

# ---------------------------------------------------------------
# 2) Inicializacao
# ---------------------------------------------------------------
Write-Host "`n[2/4] Programas que iniciam com o Windows" -ForegroundColor Cyan
$startup = @(Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue)
$pesadosIni = 0
if ($startup.Count -eq 0) {
    Write-Host "  Nenhum encontrado." -ForegroundColor Green
} else {
    foreach ($s in $startup) {
        $mb = 0
        if ($s.Command -match '([^\\"/]+)\.exe') {
            $nome = $Matches[1]
            $mb = [int](($procs | Where-Object { $_.ProcessName -eq $nome } | Measure-Object WorkingSet64 -Sum).Sum / 1MB)
        }
        if ($mb -ge 150) {
            $pesadosIni++
            Write-Host ("  [PESADO {0} MB] {1}  ({2})" -f $mb, $s.Name, $s.User) -ForegroundColor DarkYellow
        } else {
            Write-Host ("  {0}  ({1})" -f $s.Name, $s.User)
        }
    }
    Write-Host ("  Total: {0}. Pesado = ja em execucao usando 150 MB ou mais agora." -f $startup.Count) -ForegroundColor DarkGray
    Write-Host "  Para desligar um: Gerenciador de Tarefas > aba Inicializar (ou Configuracoes > Aplicativos > Inicializacao). Este script nao desliga nada." -ForegroundColor DarkGray
}

# ---------------------------------------------------------------
# 3) Diagnostico
# ---------------------------------------------------------------
Write-Host "`n[3/4] Diagnostico" -ForegroundColor Cyan
$problemas = 0
$pagDesativada = ((-not $auto) -and ($pfUso.Count -eq 0))

if ($pagDesativada) {
    Write-Host "  [!] Paginacao DESATIVADA. Sem ela, o Windows pode travar ou fechar programas quando a RAM acaba." -ForegroundColor Red; $problemas++
} elseif ($pfTotalMB -gt 0 -and $pfTotalMB -lt 1024) {
    Write-Host ("  [!] Paginacao pequena ({0} MB). Pode faltar espaco nos picos de uso." -f $pfTotalMB) -ForegroundColor DarkYellow; $problemas++
}
if ($commitPct -ge 95) {
    Write-Host ("  [!] Commit em {0}%: o sistema esta no limite, risco de erro de memoria insuficiente." -f $commitPct) -ForegroundColor Red; $problemas++
} elseif ($commitPct -ge 85) {
    Write-Host ("  [!] Commit alto ({0}%)." -f $commitPct) -ForegroundColor DarkYellow; $problemas++
}
if ($dispGB -lt 1) {
    Write-Host ("  [!] Menos de 1 GB de RAM disponivel ({0:N1} GB)." -f $dispGB) -ForegroundColor Red; $problemas++
} elseif ($dispGB -lt 2) {
    Write-Host ("  [!] Pouca RAM disponivel ({0:N1} GB)." -f $dispGB) -ForegroundColor DarkYellow; $problemas++
}
$grandes = @($procs | Where-Object { $_.WorkingSet64 -gt 2GB } | Sort-Object WorkingSet64 -Descending)
foreach ($g in $grandes) {
    Write-Host ("  [!] {0} (PID {1}) esta com {2:N1} GB. Se so cresce com o tempo, pode ser vazamento: feche e abra de novo, ou atualize o programa." -f $g.ProcessName, $g.Id, ($g.WorkingSet64 / 1GB)) -ForegroundColor DarkYellow
    $problemas++
}
if ($pesadosIni -ge 3) {
    Write-Host ("  [!] {0} programas pesados iniciam com o Windows." -f $pesadosIni) -ForegroundColor DarkYellow; $problemas++
}
if ($problemas -eq 0) {
    Write-Host "  Nenhum sinal de problema neste momento." -ForegroundColor Green
}
Write-Host "  Obs.: e uma foto do momento. Se o problema aparece so as vezes, rode de novo quando estiver lento." -ForegroundColor DarkGray

# ---------------------------------------------------------------
# 4) Acoes opcionais (nada acontece sem S)
# ---------------------------------------------------------------
Write-Host "`n[4/4] Acoes opcionais (cada uma pede confirmacao)" -ForegroundColor Cyan

# 4a) Explorer
if (Confirm-SN "  Reiniciar o Explorer (barra de tarefas e janelas de pasta piscam por alguns segundos)?") {
    Write-Log "Explorer reiniciado"
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Start-Sleep -Seconds 2
    if (Get-Process -Name explorer -ErrorAction SilentlyContinue) {
        Write-Host "  OK: Explorer em execucao." -ForegroundColor Green
    } else {
        Write-Host "  Explorer nao voltou. Pressione Ctrl+Shift+Esc > Arquivo > Executar nova tarefa > explorer.exe" -ForegroundColor Red
    }
}

# 4b) Encerrar processo por PID
if (Confirm-SN "  Quer encerrar algum processo? (voce escolhe o PID; dados nao salvos serao perdidos)") {
    while ($true) {
        $entrada = (Read-Host "  Digite o PID (ou Enter para terminar)").Trim()
        if ($entrada -eq '') { break }
        if ($entrada -notmatch '^\d+$') { Write-Host "  PID invalido." -ForegroundColor Red; continue }
        $alvo = Get-Process -Id ([int]$entrada) -ErrorAction SilentlyContinue
        if (-not $alvo) { Write-Host "  Nao existe processo com esse PID." -ForegroundColor Red; continue }
        if ($Protegidos -contains $alvo.ProcessName -or $alvo.Id -eq $PID -or $alvo.Id -eq (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId) {
            Write-Host ("  {0} e parte do Windows e nao sera encerrado por aqui." -f $alvo.ProcessName) -ForegroundColor Red; continue
        }
        $antesMB = $alvo.WorkingSet64 / 1MB
        if (-not (Confirm-SN ("  Encerrar {0} (PID {1}, {2:N0} MB)?" -f $alvo.ProcessName, $alvo.Id, $antesMB))) { continue }
        $nomeAlvo = $alvo.ProcessName
        Write-Log ("Encerrar pedido: {0} PID {1}" -f $nomeAlvo, $alvo.Id)
        # Primeiro tenta fechar com educacao (programa pode perguntar se quer salvar)
        if ($alvo.MainWindowHandle -ne [IntPtr]::Zero) {
            [void]$alvo.CloseMainWindow()
            Start-Sleep -Seconds 5
        }
        $alvo.Refresh()
        if (-not $alvo.HasExited) {
            if (Confirm-SN "  Ainda aberto. Forcar o encerramento agora?") {
                Stop-Process -Id $alvo.Id -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
            }
        }
        if (Get-Process -Id ([int]$entrada) -ErrorAction SilentlyContinue) {
            Write-Host ("  {0} continua em execucao." -f $nomeAlvo) -ForegroundColor DarkYellow
        } else {
            Write-Host ("  OK: {0} encerrado (liberou cerca de {1:N0} MB)." -f $nomeAlvo, $antesMB) -ForegroundColor Green
            Write-Log ("Encerrado: {0}" -f $nomeAlvo)
        }
    }
}

# 4c) Paginacao automatica (so se estiver desativada)
if ($pagDesativada) {
    Write-Host "`n  A paginacao esta desativada." -ForegroundColor DarkYellow
    if (Confirm-SN "  Voltar para gerenciada pelo sistema? (exige reiniciar o computador; faz backup da chave de memoria antes)") {
        if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
        $bkp = Join-Path $LogDir ("MemoryManagement-{0}.reg" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
        & reg.exe export 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' $bkp /y | Out-Null
        if (-not (Test-Path $bkp)) {
            Write-Host "  Backup falhou. Nada foi alterado." -ForegroundColor Red
        } else {
            Write-Host "  Backup: $bkp" -ForegroundColor DarkGray
            try {
                Set-CimInstance -InputObject (Get-CimInstance Win32_ComputerSystem) -Property @{ AutomaticManagedPagefile = $true } -ErrorAction Stop
                Write-Log "Paginacao -> gerenciada pelo sistema"
            } catch {
                Write-Host ("  Erro ao alterar: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
            if ([bool](Get-CimInstance Win32_ComputerSystem).AutomaticManagedPagefile) {
                Write-Host "  OK: paginacao gerenciada pelo sistema. REINICIE o computador para valer." -ForegroundColor Green
            } else {
                Write-Host "  Nao foi possivel confirmar a alteracao. Ajuste manual: Sistema > Configuracoes avancadas > Desempenho > Avancado > Memoria virtual." -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "`n  Paginacao: nada a mudar (so oferecemos ajuste quando esta desativada)." -ForegroundColor DarkGray
}

# ---------------------------------------------------------------
# Recomendacoes
# ---------------------------------------------------------------
Write-Host "`nRecomendacoes" -ForegroundColor Cyan
$totalInt = [math]::Round($totalGB)
if ($totalGB -lt 7.5) {
    Write-Host ("  - Esta maquina tem so {0} GB de RAM. Para Windows 10/11 com Office e navegador, o minimo confortavel e 8 GB; o ideal e 16 GB. Upgrade de memoria resolve mais que qualquer script." -f $totalInt) -ForegroundColor DarkYellow
} elseif ($totalGB -lt 15.5 -and ($usoPct -ge 80 -or $dispGB -lt 2)) {
    Write-Host ("  - Com {0} GB e uso alto, subir para 16 GB deve dar folga (confirme o tipo de memoria e se ha slot livre antes de comprar)." -f $totalInt) -ForegroundColor DarkYellow
} elseif ($usoPct -ge 85) {
    Write-Host ("  - A maquina tem {0} GB e mesmo assim esta cheia: provavel programa consumindo demais ou vazamento, nao falta de RAM fisica. Veja a lista de processos acima." -f $totalInt) -ForegroundColor DarkYellow
} else {
    Write-Host ("  - Memoria ({0} GB) parece adequada neste momento." -f $totalInt) -ForegroundColor Green
}
if ($pesadosIni -ge 3) { Write-Host "  - Desligar programas da inicializacao que o usuario nao usa reduz o consumo logo apos ligar." }
if ($grandes.Count -gt 0) { Write-Host "  - Processo acima de 2 GB: feche e reabra; se voltar a crescer, atualize ou reinstale o programa." }
if ($pagDesativada) { Write-Host "  - Reative a paginacao (gerenciada pelo sistema) e reinicie." }
Write-Host "  - Navegador com dezenas de abas e a causa mais comum de RAM cheia: feche abas, ou use a suspensao de abas inativas do navegador."
Write-Host "  - Reiniciar a maquina de vez em quando tambem devolve memoria presa por programas abertos ha dias."
if (Test-Path $Log) { Write-Host ("`nLog das acoes: {0}" -f $Log) -ForegroundColor DarkGray }
Write-Host "`nConcluido." -ForegroundColor Green
