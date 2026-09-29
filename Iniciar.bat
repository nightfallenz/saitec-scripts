@echo off
:: Saitec Toolkit - modo pendrive/offline.
:: Rode com duplo clique, SEM "Executar como administrador".
:: Os itens que precisam de Administrador pedem elevacao sozinhos.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0saitec-toolkit.ps1"
