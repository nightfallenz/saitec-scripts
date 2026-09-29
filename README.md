# Saitec Toolkit

Scripts e ferramentas da equipe de suporte em campo (N2) da Saitec. São correções prontas para os problemas que mais aparecem nos chamados, organizadas em um menu único.

## Como usar

### Online (máquina com internet)

Abra o **PowerShell normal**, como o usuário logado, sem "Executar como administrador", e cole:

```powershell
irm tinyurl.com/saitec-toolkit | iex
```

Se o tinyurl estiver bloqueado na rede do cliente, use o endereço completo:

```powershell
irm https://raw.githubusercontent.com/nightfallenz/saitec-scripts/main/saitec-toolkit.ps1 | iex
```

Nada fica instalado na máquina do cliente. Os scripts são baixados para a pasta temporária só na hora de rodar.

### Pendrive (máquina sem internet)

**Jeito mais fácil:** em uma máquina com internet, abra o menu online e escolha **29 - Baixar kit para uso offline**. Ele detecta o pendrive, salva o kit na pasta `saitec-toolkit` e pergunta se você quer baixar também os instaladores das ferramentas, que ficam em `saitec-toolkit\instaladores`. Rodar de novo atualiza os scripts e mantém os instaladores já baixados.

**Ou manualmente:**

1. Baixe o kit: **https://tinyurl.com/saitec-kit** (ou https://github.com/nightfallenz/saitec-scripts/archive/refs/heads/main.zip)
2. Extraia no pendrive.
3. Na máquina do cliente, dê dois cliques em **`Iniciar.bat`**.

Atualize o pendrive de vez em quando, baixando o .zip de novo.

### [ADM] e [USR]

| Marca | Roda como | Por quê |
|---|---|---|
| **[ADM]** | Administrador (pede UAC na hora) | Mexe em serviços, drivers e arquivos do sistema |
| **[USR]** | Usuário logado | Cache do Teams, credenciais e OneDrive ficam no perfil do usuário |

Por isso o menu é aberto **sem** elevação. Se você abrir o PowerShell com a sua conta de admin, os itens [USR] vão limpar o **seu** perfil, e não o do usuário.

## O que tem no menu

| # | Categoria | Script | Quando usar |
|---|---|---|---|
| 1 | Impressoras | `Reset-Spooler.ps1` | Fila presa, impressora não imprime |
| 2 | Impressoras | `Gerenciar-Impressoras.ps1` | Driver corrompido, impressora duplicada, reinstalação limpa |
| 3 | Impressoras | `Adicionar-Impressora-IP.ps1` | Instalar impressora de rede direto pelo IP |
| 4 | Rede | `Diagnostico-Rede.ps1` | Primeiro passo em "sem internet". Não altera nada |
| 5 | Rede | `Reset-Rede.ps1` | DNS falhando, rede não identificada. Pede reinício |
| 6 | Domínio | `Corrigir-Wallpaper-Dominio.ps1` | Wallpaper da GPO preto ou não aplica. Testa o acesso ao arquivo do NETLOGON e limpa o `TranscodedWallpaper` |
| 7 | Domínio | `Atualizar-GPO.ps1` | `gpupdate /force` e relatório HTML do `gpresult` |
| 8 | Domínio | `Unidades-Rede.ps1` | Unidade mapeada com X vermelho, pasta do setor sumiu |
| 9 | Domínio | `Reparar-Relacao-Dominio.ps1` | "A relação de confiança... falhou", sem tirar do domínio |
| 10 | Domínio | `Sincronizar-Hora.ps1` | Hora errada, erro de Kerberos no logon |
| 11 | Domínio | `Perfil-Temporario.ps1` | "Conectado com perfil temporário". Faz backup do registro antes |
| 12 | Sistema | `Info-Sistema.ps1` | Ficha da máquina (serial, modelo, IP) copiada para colar no chamado |
| 13 | Sistema | `Reparar-Windows.ps1` | DISM + SFC: tela azul, erro de DLL, apps nativos quebrados |
| 14 | Sistema | `Reset-WindowsUpdate.ps1` | Update travado ou com erro 0x8024... / 0x800f... |
| 15 | Sistema | `Limpeza-Rapida.ps1` | Disco cheio |
| 16 | Sistema | `Saude-Disco.ps1` | Desgaste do SSD, erros de leitura, temperatura, eventos de disco |
| 17 | Sistema | `Status-BitLocker.ps1` | Status e ID da chave de recuperação |
| 18 | Sistema | `Inicializacao-Rapida.ps1` | Uptime alto mesmo desligando, update que nunca termina |
| 19 | Sistema | `Reiniciar-Explorer.ps1` | Barra de tarefas ou menu Iniciar travado, ícones errados |
| 20 | Sistema | `Corrigir-Pesquisa-Iniciar.ps1` | Pesquisa do menu Iniciar não abre, não deixa digitar ou fica em branco |
| 21 | Sistema | `Reparar-Store-Apps.ps1` | Store, Calculadora ou Fotos não abrem |
| 22 | Sistema | `Manutencao_Windows.bat` | Manutenção preventiva completa, com menu próprio e log |
| 23 | Office | `Limpar-Teams.ps1` | Teams com tela branca, não abre, loop de login |
| 24 | Office | `Limpar-Credenciais-Office.ps1` | Outlook pedindo senha em loop, conta errada presa |
| 25 | Office | `Reset-OneDrive.ps1` | Sincronização parada. Não apaga arquivos |
| 26 | Office | `Reparar-Office.ps1` | Reparo rápido ou online do Microsoft 365 |
| 27 | Ferramentas | `Instalar-Ferramentas.ps1` | Instala programas de suporte via winget |
| 28 | Ferramentas | Chris Titus WinUtil | Debloat e otimização. Oficialmente só Windows 11 |
| 29 | Ferramentas | Baixar kit para uso offline | Salva o kit no pendrive ou em uma pasta e, se quiser, baixa os instaladores das ferramentas |

## Ferramentas instaladas pelo menu (item 27)

Todas vêm do catálogo oficial do winget, direto da fonte de cada fabricante. **[OSS]** marca as de código aberto.

| Ferramenta | Para que serve | Site oficial |
|---|---|---|
| 7-Zip [OSS] | Compactar e extrair | https://www.7-zip.org |
| AnyDesk | Acesso remoto | https://anydesk.com |
| TeamViewer | Acesso remoto | https://www.teamviewer.com |
| CrystalDiskInfo [OSS] | Saúde do SSD/HD (SMART) | https://crystalmark.info |
| CrystalDiskMark [OSS] | Velocidade do disco | https://crystalmark.info |
| Sysinternals Suite | Process Explorer, Autoruns, TCPView | https://learn.microsoft.com/sysinternals |
| Advanced IP Scanner | Varredura da rede | https://www.advanced-ip-scanner.com |
| Notepad++ [OSS] | Editor de texto e logs | https://notepad-plus-plus.org |
| Rufus [OSS] | Pendrive bootável | https://rufus.ie |
| WinDirStat [OSS] | O que está ocupando o disco | https://windirstat.net |
| CPU-Z | CPU, RAM e placa-mãe | https://www.cpuid.com |
| HWiNFO | Sensores e temperaturas | https://www.hwinfo.com |
| LibreHardwareMonitor [OSS] | Temperaturas e sensores | https://github.com/LibreHardwareMonitor/LibreHardwareMonitor |
| PuTTY [OSS] | SSH, Telnet e serial | https://www.putty.org |
| WinSCP [OSS] | SFTP, SCP e FTP | https://winscp.net |
| Wireshark [OSS] | Captura de pacotes | https://www.wireshark.org |
| Bulk Crap Uninstaller [OSS] | Desinstalar vários programas e limpar restos | https://www.bcuninstaller.com |
| KeePassXC [OSS] | Cofre de senhas offline | https://keepassxc.org |
| ShareX [OSS] | Print e gravação de tela para o chamado | https://getsharex.com |
| PowerToys [OSS] | Utilitários do Windows | https://learn.microsoft.com/windows/powertoys |
| Windows Terminal [OSS] | Terminal com abas | https://github.com/microsoft/terminal |
| PowerShell 7 [OSS] | Versão atual do PowerShell | https://github.com/PowerShell/PowerShell |
| Firefox [OSS] | Navegador | https://www.mozilla.org/firefox |
| SumatraPDF [OSS] | Leitor de PDF leve | https://www.sumatrapdfreader.org |
| LibreOffice [OSS] | Pacote office gratuito | https://www.libreoffice.org |
| VLC [OSS] | Player de áudio e vídeo | https://www.videolan.org |
| Chrome, Acrobat Reader | Estação de usuário | Sites dos fabricantes |

Há pacotes prontos: **P1** básico de campo, **P2** diagnóstico e **P3** estação de usuário.

## Chris Titus WinUtil

Ferramenta de terceiros para debloat, tweaks e instalação de programas: https://winutil.christitus.com

- Oficialmente suporta só **Windows 11**. No Windows 10, o menu avisa antes de abrir.
- **Crie um ponto de restauração antes** de aplicar tweaks.
- Evite aplicar tweaks em máquinas de domínio sem alinhar com a política da empresa.

## Como adicionar um script

1. Crie o `.ps1` na pasta da categoria, em `scripts/<categoria>/`.
2. Use o mesmo cabeçalho dos outros: `.SYNOPSIS` e `.NOTES` explicando quando usar e se precisa de Administrador.
3. Escreva as mensagens **sem acentos**, porque o PowerShell 5.1 lê arquivo sem BOM como ANSI.
4. Adicione uma linha na lista `$Itens` do `saitec-toolkit.ps1` e na tabela deste README.
5. Teste em uma VM ou máquina de teste antes de subir.

**Nunca** coloque senhas, tokens ou dados de clientes neste repositório. Ele é público.
