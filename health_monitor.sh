#!/bin/bash

# === Colors ===
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


# Function to draw the dashboard
draw_dashboard() {
  clear
  # System Basics
  HOSTNAME=$(hostname)
  DATE_NOW=$(date "+%Y-%m-%d")
  UPTIME_INFO=$(uptime -p | sed 's/up //')
  REFRESH_RATE=3

  echo -e "╔════════════ SYSTEM HEALTH MONITOR v1.0 ════════════╗  [R]efresh rate: ${REFRESH_RATE}s"
  printf "║ Hostname: %-25s Date: %-10s ║  [F]ilter: All\n" "$HOSTNAME" "$DATE_NOW"
  printf "║ Uptime: %-44s ║  [Q]uit\n" "$UPTIME_INFO"
  echo -e "╚═══════════════════════════════════════════════════════════════════════╝"

  ### CPU USAGE ###
  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
  CPU_WARNING=$(echo "$CPU_USAGE > 80" | bc)
  CPU_BAR=$(generate_bar "$CPU_USAGE")
  CPU_STATUS="[OK]"
  [ "$CPU_USAGE" > 70 ] && CPU_STATUS="[WARNING]"
  
  TOP_CPU_PROCS=$(ps -eo comm,%cpu --sort=-%cpu | head -n 4 | tail -n +2 | awk '{printf "  %s (%s%%)", $1, $2}')

  printf "\nCPU USAGE: %.0f%% %s %s\n" "$CPU_USAGE" "$CPU_BAR" "$CPU_STATUS"
  echo "  Process:$TOP_CPU_PROCS"
# Example for CPU status
CPU_STATUS="${GREEN}[OK]${NC}"
[ "$CPU_USAGE" > 70 ] && CPU_STATUS="${YELLOW}[WARNING]${NC}"
[ "$CPU_USAGE" > 85 ] && CPU_STATUS="${RED}[CRITICAL]${NC}"


  ### MEMORY USAGE ###
  MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
  MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
  MEM_FREE=$(free -m | awk '/Mem:/ {print $4}')
  MEM_CACHE=$(free -m | awk '/Mem:/ {print $6}')
  MEM_BUFF=$(free -m | awk '/Mem:/ {print $7}')
  MEM_PERC=$((MEM_USED * 100 / MEM_TOTAL))
  MEM_BAR=$(generate_bar "$MEM_PERC")
  MEM_STATUS="[OK]"
  [ "$MEM_PERC" -ge 70 ] && MEM_STATUS="[WARNING]"

  printf "\nMEMORY: %.1fGB/%.0fGB (%d%%) %s %s\n" "$(echo "$MEM_USED / 1024" | bc -l)" "$(echo "$MEM_TOTAL / 1024" | bc)" "$MEM_PERC" "$MEM_BAR" "$MEM_STATUS"
  echo "  Free: ${MEM_FREE}MB | Cache: ${MEM_CACHE}MB | Buffers: ${MEM_BUFF}MB"

# Example for Memory status
MEM_STATUS="${GREEN}[OK]${NC}"
[ "$MEM_PERC" > 70 ] && MEM_STATUS="${YELLOW}[WARNING]${NC}"
[ "$MEM_PERC" > 85 ] && MEM_STATUS="${RED}[CRITICAL]${NC}"


  ### DISK USAGE ###
  echo -e "\nDISK USAGE:"
  df -h --output=target,pcent | grep -v "Mounted" | while read -r mount usage; do
    PERC=$(echo "$usage" | tr -d '%')
    BAR=$(generate_bar "$PERC")
    STATUS="[OK]"
    [ "$PERC" -ge 75 ] && STATUS="[WARNING]"
    printf "  %-8s: %-4s %s %s\n" "$mount" "$usage" "$BAR" "$STATUS"
  done

  ### NETWORK STATS ###
  echo -e "\nNETWORK:"
  RX_PREV=$(cat /proc/net/dev | awk '/eth0/ {print $2}')
  TX_PREV=$(cat /proc/net/dev | awk '/eth0/ {print $10}')
  sleep 1
  RX_CUR=$(cat /proc/net/dev | awk '/eth0/ {print $2}')
  TX_CUR=$(cat /proc/net/dev | awk '/eth0/ {print $10}')

  RX_RATE=$(echo "scale=2; ($RX_CUR - $RX_PREV)/1024/1" | bc)
  TX_RATE=$(echo "scale=2; ($TX_CUR - $TX_PREV)/1024/1" | bc)
  RX_BAR=$(generate_bar "$RX_RATE" 20)
  TX_BAR=$(generate_bar "$TX_RATE" 20)

  printf "  eth0 (in) : %.1f MB/s %s [OK]\n" "$RX_RATE" "$RX_BAR"
  printf "  eth0 (out): %.1f MB/s %s [OK]\n" "$TX_RATE" "$TX_BAR"

  ### LOAD AVERAGE ###
  LOAD=$(uptime | awk -F'load average:' '{print $2}')
  echo -e "\nLOAD AVERAGE:$LOAD"

  ### RECENT ALERTS (demo only)
  echo -e "\nRECENT ALERTS:"
  [ "$(echo "$CPU_USAGE > 80" | bc)" -eq 1 ] && echo "[`date +%H:%M:%S`] CPU usage exceeded 80% ($CPU_USAGE%)"
  [ "$MEM_PERC" -ge 75 ] && echo "[`date +%H:%M:%S`] Memory usage exceeded 75% ($MEM_PERC%)"
}

# Generate progress bar

generate_bar() {
  local perc=$1
  local maxlen=${2:-50}
  local filled=$(echo "$perc * $maxlen / 100" | bc)
  local empty=$(echo "$maxlen - $filled" | bc)
  filled=${filled%.*}  # remove decimal part
  empty=${empty%.*}
  printf "%0.s█" $(seq 1 $filled)
  printf "%0.s░" $(seq 1 $empty)
}

# Main loop
while true; do
  draw_dashboard
  read -t 3 -n 1 key
  [[ $key = "q" || $key = "Q" ]] && break
done
