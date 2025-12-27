#!/usr/bin/env bash
# system_scan.sh - scanner de diagnóstico rápido do sistema

OUTDIR="./system_scan_reports"
TS=$(date +"%Y%m%d_%H%M%S")
OUTFILE="$OUTDIR/system_scan_$TS.txt"
mkdir -p "$OUTDIR"

log() {
  echo "[$(date +"%F %T")] $*" | tee -a "$OUTFILE"
}

log "Início do scan"
log "Usuário: $(whoami)"
log "Host: $(hostname)"
log "Kernel: $(uname -r)"
log "Distribuição: $( { command -v lsb_release >/dev/null 2>&1 && lsb_release -d | cut -f2- -d: || (grep -m1 PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2- || true); } )"
log ""

log "1) Uptime e load"
uptime | tee -a "$OUTFILE"
log ""

log "2) Uso de disco"
df -hT --total | tee -a "$OUTFILE"
log ""
log "Discos detectados (lsblk)"
lsblk -o NAME,TYPE,SIZE,MOUNTPOINT -P | tee -a "$OUTFILE"
log ""

log "3) Uso de memória"
free -h | tee -a "$OUTFILE"
log ""
log "Top 5 processos por memória (ps)"
ps aux --sort=-%mem | head -n 7 | tee -a "$OUTFILE"
log ""

log "4) CPU e load"
lscpu 2>/dev/null | tee -a "$OUTFILE"
top -b -n 1 | head -n 20 | tee -a "$OUTFILE"
log ""

log "5) Temperaturas (se sensors disponível)"
if command -v sensors >/dev/null 2>&1; then
  sensors | tee -a "$OUTFILE"
else
  log "sensors não encontrado; instale lm-sensors para leituras de temperatura"
fi
log ""

log "6) Mensagens do kernel e logs recentes (erros/warnings)"
if command -v journalctl >/dev/null 2>&1; then
  journalctl -p 3 -n 200 --no-pager 2>/dev/null | tee -a "$OUTFILE"
else
  dmesg --level=err,crit,alert,emerg | tail -n 200 | tee -a "$OUTFILE"
fi
log ""

log "7) Unidades do systemd falhando (se systemd presente)"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --failed --no-legend 2>/dev/null | tee -a "$OUTFILE" || log "sem unidades falhadas"
else
  log "systemctl não disponível"
fi
log ""

log "8) SMART (se smartctl disponível) — pode precisar de sudo"
if command -v smartctl >/dev/null 2>&1; then
  for dev in $(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}'); do
    log "SMART teste rápido para $dev"
    smartctl -H "$dev" | tee -a "$OUTFILE"
    smartctl -A "$dev" 2>/dev/null | tee -a "$OUTFILE"
    echo "" >> "$OUTFILE"
  done
else
  log "smartctl não encontrado; instale smartmontools para checks SMART"
fi
log ""

log "9) Checagem de sistemas de arquivos montados (dmesg grep por erros recentes)"
dmesg | tail -n 200 | egrep -i "error|fail|failed|corrupt|I/O" --color=never 2>/dev/null | tee -a "$OUTFILE"
log ""

log "10) Portas/serviços de rede escutando"
if command -v ss >/dev/null 2>&1; then
  ss -tulpen | tee -a "$OUTFILE"
elif command -v netstat >/dev/null 2>&1; then
  netstat -tulpen | tee -a "$OUTFILE"
else
  log "ss/netstat não disponíveis"
fi
log ""

log "11) Entradas de /var/log/syslog ou messages (as últimas linhas)"
if [ -f /var/log/syslog ]; then
  tail -n 200 /var/log/syslog 2>/dev/null | tee -a "$OUTFILE"
elif [ -f /var/log/messages ]; then
  tail -n 200 /var/log/messages 2>/dev/null | tee -a "$OUTFILE"
else
  log "logs padrão não encontrados"
fi
log ""

log "12) Rootkits (chkrootkit/rkhunter) — executa se instalado"
if command -v chkrootkit >/dev/null 2>&1; then
  chkrootkit | tee -a "$OUTFILE"
fi
if command -v rkhunter >/dev/null 2>&1; then
  rkhunter --check --sk --noprompt | tee -a "$OUTFILE"
fi
log ""

log "13) Verificação rápida de permissões/suid"
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f -exec ls -ld {} \; 2>/dev/null | tee -a "$OUTFILE"
log ""

log "Scan concluído. Relatório salvo em $OUTFILE"
log "Observações: alguns comandos requerem root para resultados completos."