@echo off
:: ==========================================================================
::  MANUTENCAO PREVENTIVA E OTIMIZACAO - WINDOWS 10 / 11
::  Executa rotinas via CMD + PowerShell. Requer Administrador.
::  Log salvo em: C:\ManutencaoLogs
:: ==========================================================================
setlocal EnableExtensions EnableDelayedExpansion
title Manutencao Preventiva - Windows 10/11
chcp 65001 >nul

:: ---------- Auto-elevacao para Administrador ----------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permissao de Administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ---------- Log ----------
set "LOGDIR=C:\ManutencaoLogs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "STAMP=%%i"
set "LOG=%LOGDIR%\manutencao_%STAMP%.log"

:MENU
cls
echo ==========================================================
echo       MANUTENCAO PREVENTIVA - WINDOWS 10 / 11
echo ==========================================================
echo   [1] Manutencao COMPLETA (recomendado)
echo   [2] Criar ponto de restauracao
echo   [3] Limpeza de arquivos temporarios e cache
echo   [4] Reparar sistema (DISM + SFC)
echo   [5] Verificar disco (CHKDSK somente leitura)
echo   [6] Otimizar unidades (TRIM em SSD / Desfrag em HD)
echo   [7] Rede: limpar DNS, renovar IP, resetar Winsock
echo   [8] Atualizar Defender e fazer verificacao rapida
echo   [9] Atualizar programas (winget)
echo   [10] Resetar cache do Windows Update
echo   [11] Relatorio de saude (bateria, disco, inicializacao)
echo   [0] Sair
echo ==========================================================
set "OP="
set /p "OP=Escolha uma opcao: "

if "%OP%"=="1"  goto COMPLETA
if "%OP%"=="2"  call :RESTAURACAO & goto FIM
if "%OP%"=="3"  call :LIMPEZA     & goto FIM
if "%OP%"=="4"  call :REPARO      & goto FIM
if "%OP%"=="5"  call :DISCO       & goto FIM
if "%OP%"=="6"  call :OTIMIZAR    & goto FIM
if "%OP%"=="7"  call :REDE        & goto FIM
if "%OP%"=="8"  call :DEFENDER    & goto FIM
if "%OP%"=="9"  call :WINGET      & goto FIM
if "%OP%"=="10" call :WUPDATE     & goto FIM
if "%OP%"=="11" call :RELATORIO   & goto FIM
if "%OP%"=="0"  exit /b
goto MENU

:: ==========================================================================
:COMPLETA
call :LOGMSG "===== INICIO DA MANUTENCAO COMPLETA ====="
call :RESTAURACAO
call :LIMPEZA
call :REPARO
call :DISCO
call :OTIMIZAR
call :REDE
call :DEFENDER
call :WINGET
call :RELATORIO
call :LOGMSG "===== MANUTENCAO COMPLETA FINALIZADA ====="
goto FIM

:: ==========================================================================
:RESTAURACAO
call :LOGMSG "[1] Criando ponto de restauracao..."
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "try { Enable-ComputerRestore -Drive ($env:SystemDrive + '\') -ErrorAction SilentlyContinue;" ^
 "New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' -Force | Out-Null;" ^
 "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' -Name SystemRestorePointCreationFrequency -Value 0 -Type DWord;" ^
 "Checkpoint-Computer -Description 'Manutencao Preventiva' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop;" ^
 "Write-Host 'Ponto de restauracao criado.' } catch { Write-Host ('Aviso: ' + $_.Exception.Message) }" >> "%LOG%" 2>&1
exit /b

:: ==========================================================================
:LIMPEZA
call :LOGMSG "[2] Limpando temporarios, cache e lixeira..."
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$paths = @(($env:TEMP + '\*'), ($env:SystemRoot + '\Temp\*'), ($env:SystemRoot + '\Prefetch\*')," ^
 "($env:LOCALAPPDATA + '\Microsoft\Windows\INetCache\*'), ($env:LOCALAPPDATA + '\CrashDumps\*')," ^
 "($env:ProgramData + '\Microsoft\Windows\WER\ReportArchive\*'), ($env:ProgramData + '\Microsoft\Windows\WER\ReportQueue\*'));" ^
 "$antes = (Get-PSDrive C).Free;" ^
 "foreach ($p in $paths) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue };" ^
 "Clear-RecycleBin -Force -ErrorAction SilentlyContinue;" ^
 "Get-ChildItem ($env:LOCALAPPDATA + '\Microsoft\Windows\Explorer') -Filter 'thumbcache_*.db' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue;" ^
 "$depois = (Get-PSDrive C).Free;" ^
 "Write-Host ('Espaco liberado: {0:N2} MB' -f (($depois - $antes)/1MB))" >> "%LOG%" 2>&1

call :LOGMSG "    Limpando componentes antigos do Windows (WinSxS)..."
dism /Online /Cleanup-Image /StartComponentCleanup >> "%LOG%" 2>&1

call :LOGMSG "    Limpeza de disco automatica (cleanmgr)..."
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$k='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches';" ^
 "Get-ChildItem $k | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name StateFlags0099 -Value 2 -Type DWord -ErrorAction SilentlyContinue }" >> "%LOG%" 2>&1
start /wait "" cleanmgr /sagerun:99
exit /b

:: ==========================================================================
:REPARO
call :LOGMSG "[3] DISM - verificando e reparando imagem do Windows (pode demorar)..."
dism /Online /Cleanup-Image /ScanHealth    >> "%LOG%" 2>&1
dism /Online /Cleanup-Image /RestoreHealth >> "%LOG%" 2>&1
call :LOGMSG "    SFC - verificando arquivos do sistema..."
sfc /scannow >> "%LOG%" 2>&1
exit /b

:: ==========================================================================
:DISCO
call :LOGMSG "[4] Verificando disco C: (somente leitura, sem reiniciar)..."
chkdsk C: /scan >> "%LOG%" 2>&1
powershell -NoProfile -Command ^
 "Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, @{n='GB';e={[math]::Round($_.Size/1GB)}} | Format-Table -AutoSize | Out-String" >> "%LOG%" 2>&1
exit /b

:: ==========================================================================
:OTIMIZAR
call :LOGMSG "[5] Otimizando unidades (TRIM em SSD, desfragmentacao em HD)..."
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | ForEach-Object {" ^
 "Write-Host ('Otimizando ' + $_.DriveLetter + ':'); Optimize-Volume -DriveLetter $_.DriveLetter -Verbose -ErrorAction SilentlyContinue }" >> "%LOG%" 2>&1
exit /b

:: ==========================================================================
:REDE
call :LOGMSG "[6] Manutencao de rede..."
ipconfig /flushdns   >> "%LOG%" 2>&1
ipconfig /release    >> "%LOG%" 2>&1
ipconfig /renew      >> "%LOG%" 2>&1
netsh winsock reset  >> "%LOG%" 2>&1
netsh int ip reset   >> "%LOG%" 2>&1
call :LOGMSG "    Rede redefinida. Recomenda-se reiniciar o PC."
exit /b

:: ==========================================================================
:DEFENDER
call :LOGMSG "[7] Atualizando assinaturas do Defender e verificacao rapida..."
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "try { Update-MpSignature -ErrorAction Stop; Start-MpScan -ScanType QuickScan -ErrorAction Stop; Write-Host 'Verificacao concluida.' }" ^
 "catch { Write-Host ('Defender indisponivel (outro antivirus?): ' + $_.Exception.Message) }" >> "%LOG%" 2>&1
exit /b

:: ==========================================================================
:WINGET
call :LOGMSG "[8] Atualizando programas instalados via winget..."
where winget >nul 2>&1
if %errorlevel% neq 0 (
    call :LOGMSG "    winget nao encontrado. Instale o 'Instalador de Aplicativo' pela Microsoft Store."
    exit /b
)
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --include-unknown >> "%LOG%" 2>&1
exit /b

:: ==========================================================================
:WUPDATE
call :LOGMSG "[9] Resetando cache do Windows Update..."
net stop wuauserv  >> "%LOG%" 2>&1
net stop bits      >> "%LOG%" 2>&1
net stop cryptsvc  >> "%LOG%" 2>&1
if exist "%SystemRoot%\SoftwareDistribution.old" rd /s /q "%SystemRoot%\SoftwareDistribution.old"
if exist "%SystemRoot%\System32\catroot2.old" rd /s /q "%SystemRoot%\System32\catroot2.old"
ren "%SystemRoot%\SoftwareDistribution" SoftwareDistribution.old >> "%LOG%" 2>&1
ren "%SystemRoot%\System32\catroot2" catroot2.old >> "%LOG%" 2>&1
net start cryptsvc >> "%LOG%" 2>&1
net start bits     >> "%LOG%" 2>&1
net start wuauserv >> "%LOG%" 2>&1
call :LOGMSG "    Cache do Windows Update redefinido."
exit /b

:: ==========================================================================
:RELATORIO
call :LOGMSG "[10] Gerando relatorio de saude..."
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$os = Get-CimInstance Win32_OperatingSystem;" ^
 "Write-Host ('Sistema: ' + $os.Caption + ' build ' + $os.BuildNumber);" ^
 "Write-Host ('Ultimo boot: ' + $os.LastBootUpTime);" ^
 "Write-Host ('RAM livre: {0:N1} GB de {1:N1} GB' -f ($os.FreePhysicalMemory/1MB), ($os.TotalVisibleMemorySize/1MB));" ^
 "Get-PSDrive -PSProvider FileSystem | Where-Object Used | ForEach-Object { Write-Host ('Disco {0}: {1:N1} GB livres' -f $_.Name, ($_.Free/1GB)) };" ^
 "Write-Host '--- Programas na inicializacao ---';" ^
 "Get-CimInstance Win32_StartupCommand | Select-Object Name, Location | Format-Table -AutoSize | Out-String | Write-Host;" ^
 "Write-Host '--- Erros criticos do sistema (ultimos 7 dias) ---';" ^
 "Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 15 -ErrorAction SilentlyContinue | Select-Object TimeCreated, ProviderName, Id | Format-Table -AutoSize | Out-String | Write-Host" >> "%LOG%" 2>&1
powercfg /batteryreport /output "%LOGDIR%\bateria_%STAMP%.html" >nul 2>&1
if exist "%LOGDIR%\bateria_%STAMP%.html" call :LOGMSG "    Relatorio de bateria: %LOGDIR%\bateria_%STAMP%.html"
exit /b

:: ==========================================================================
:LOGMSG
echo %~1
echo [%date% %time%] %~1 >> "%LOG%"
exit /b

:FIM
echo.
echo ==========================================================
echo  Concluido. Log salvo em:
echo  %LOG%
echo  Recomenda-se REINICIAR o computador.
echo ==========================================================
set "R="
set /p "R=Deseja abrir o log agora? (S/N): "
if /i "%R%"=="S" start notepad "%LOG%"
set "R="
set /p "R=Voltar ao menu? (S/N): "
if /i "%R%"=="S" goto MENU
exit /b
