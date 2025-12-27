# System Scan (system_scan.sh)

Descrição
- Script simples de diagnóstico que coleta informações de saúde do sistema e gera um relatório em `system_scan_reports/`.

Requisitos (recomendado)
- `bash`, `sudo`
- `lsblk`, `df`, `free`, `ps`, `top`, `lscpu`, `dmesg`
- Recomendações opcionais: `lm-sensors` (comando `sensors`), `smartmontools` (`smartctl`), `chkrootkit`, `rkhunter`, `journalctl` (systemd)

Como usar
1. Tornar executável:
   ```sh
   chmod +x system_scan.sh
