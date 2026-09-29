# Saitec Toolkit

Scripts e ferramentas da equipe de suporte em campo (N2) da Saitec. São correções prontas para os problemas que mais aparecem nos chamados, organizadas em um menu único.

## Como usar

### Online (máquina com internet)

Abra o **PowerShell normal**, como o usuário logado, sem "Executar como administrador", e cole:

```powershell
irm https://raw.githubusercontent.com/nightfallenz/saitec-scripts/main/saitec-toolkit.ps1 | iex
```

Nada fica instalado na máquina do cliente. Os scripts são baixados para a pasta temporária só na hora de rodar.

### Pendrive (máquina sem internet)

1. Baixe o kit: **https://github.com/nightfallenz/saitec-scripts/archive/refs/heads/main.zip**
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
| 3 | Rede | `Diagnostico-Rede.ps1` | Primeiro passo em "sem internet". Não altera nada |
| 4 | Rede | `Reset-Rede.ps1` | DNS falhando, rede não identificada. Pede reinício |
| 5 | Sistema | `Info-Sistema.ps1` | Ficha da máquina (serial, modelo, IP) copiada para colar no chamado |
| 6 | Sistema | `Reparar-Windows.ps1` | DISM + SFC: tela azul, erro de DLL, apps nativos quebrados |
| 7 | Sistema | `Reset-WindowsUpdate.ps1` | Update travado ou com erro 0x8024... / 0x800f... |
| 8 | Sistema | `Limpeza-Rapida.ps1` | Disco cheio |
| 9 | Sistema | `Reiniciar-Explorer.ps1` | Barra de tarefas ou menu Iniciar travado, ícones errados |
| 10 | Sistema | `Manutencao_Windows.bat` | Manutenção preventiva completa, com menu próprio e log |
| 11 | Office | `Limpar-Teams.ps1` | Teams com tela branca, não abre, loop de login |
| 12 | Office | `Limpar-Credenciais-Office.ps1` | Outlook pedindo senha em loop, conta errada presa |
| 13 | Office | `Reset-OneDrive.ps1` | Sincronização parada. Não apaga arquivos |
| 14 | Office | `Reparar-Office.ps1` | Reparo rápido ou online do Microsoft 365 |
| 15 | Ferramentas | `Instalar-Ferramentas.ps1` | Instala programas de suporte via winget |
| 16 | Ferramentas | Chris Titus WinUtil | Debloat e otimização. Oficialmente só Windows 11 |

## Ferramentas instaladas pelo menu (item 15)

Todas vêm do catálogo oficial do winget, direto da fonte de cada fabricante.

| Ferramenta | Para que serve | Site oficial |
|---|---|---|
| 7-Zip | Compactar e extrair | https://www.7-zip.org |
| AnyDesk | Acesso remoto | https://anydesk.com |
| TeamViewer | Acesso remoto | https://www.teamviewer.com |
| CrystalDiskInfo | Saúde do SSD/HD (SMART) | https://crystalmark.info |
| Sysinternals Suite | Process Explorer, Autoruns, TCPView | https://learn.microsoft.com/sysinternals |
| Advanced IP Scanner | Varredura da rede | https://www.advanced-ip-scanner.com |
| Notepad++ | Editor de texto e logs | https://notepad-plus-plus.org |
| Rufus | Pendrive bootável | https://rufus.ie |
| WinDirStat | O que está ocupando o disco | https://windirstat.net |
| CPU-Z | CPU, RAM e placa-mãe | https://www.cpuid.com |
| HWiNFO | Sensores e temperaturas | https://www.hwinfo.com |
| PuTTY | SSH, Telnet e serial | https://www.putty.org |
| Wireshark | Captura de pacotes | https://www.wireshark.org |
| PowerToys | Utilitários do Windows | https://learn.microsoft.com/windows/powertoys |
| Chrome, Firefox, Acrobat Reader | Estação de usuário | Sites dos fabricantes |

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
