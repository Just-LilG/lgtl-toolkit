#!/data/data/com.termux/files/usr/bin/bash

TBIN="/data/data/com.termux/files/usr/bin"
export PATH="$TBIN:/data/data/com.termux/files/usr/sbin:$PATH"
export LD_LIBRARY_PATH="/data/data/com.termux/files/usr/lib:$LD_LIBRARY_PATH"

if [ "$(id -u)" != "0" ] && [ -z "$LGTL_ROOT_INHERITED" ]; then
    exec su -c "LGTL_ROOT_INHERITED=1 $TBIN/bash $0"
    exit 1
fi
export LGTL_ROOT_INHERITED=1

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'
W='\033[1;37m'; GR='\033[0;37m'; M='\033[0;35m'; B='\033[1m'
DIM='\033[2m'; N='\033[0m'

VERSION="2.0"
LOG_DIR="/sdcard/LilGTechLabs/logs"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/lgtl_ai_sense_$(date +%Y%m%d_%H%M%S).log"

log()  { echo "[$(date '+%H:%M:%S')] $(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"; }
ok()   { echo -e "  ${G}[✓]${N} $1"; log "[OK] $1"; }
err()  { echo -e "  ${R}[✗]${N} $1"; log "[ERR] $1"; }
info() { echo -e "  ${C}[*]${N} $1"; log "[INFO] $1"; }
warn() { echo -e "  ${Y}[!]${N} $1"; log "[WARN] $1"; }
ask()  { printf "${W}  ➤  %s${N}" "$1"; read -r "$2"; }
div()  { echo -e "  ${GR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
pause(){ echo ""; printf "${W}  ➤  Press Enter to continue...${N}"; read -r _D; }

type_line() {
    local text="$1" color="${2:-$W}" delay="${3:-0.03}"
    local i=0
    while [ $i -lt ${#text} ]; do
        printf "${color}%s${N}" "${text:$i:1}"; sleep "$delay"; i=$((i+1))
    done
    printf "\n"
}

pulse_bar() {
    local label="$1" steps="${2:-30}"
    printf "  ${DIM}%-34s${N} [" "$label"
    local i=0
    while [ $i -lt $steps ]; do
        local r=$(( (i * 1103515245 + 12345) % 3 ))
        case $r in 0) printf "${G}█${N}" ;; 1) printf "${C}▓${N}" ;; 2) printf "${GR}░${N}" ;; esac
        sleep 0.018; i=$((i+1))
    done
    printf "] ${G}✔${N}\n"
}

scan_check() {
    local label="$1" result="${2:-OK}" color="${3:-$G}"
    printf "  ${C}◈${N} %-34s" "$label"
    local i=0
    while [ $i -lt 6 ]; do printf "${C}·${N}"; sleep 0.05; i=$((i+1)); done
    printf " ${color}%s${N}\n" "$result"
}

boot_anim() {
    clear; echo ""
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.004
    type_line "     LIL G TECH LABS  ·  AI Sense CPU Profile" "$W" 0.022
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.004
    echo ""
    pulse_bar "Initializing CPU controller" 30
    pulse_bar "Loading frequency profiles" 28
    if [ "$(id -u)" = "0" ]; then
        scan_check "Root access" "GRANTED" "$G"
    else
        scan_check "Root access" "LIMITED" "$Y"
    fi
    echo ""; sleep 0.2
}

banner() {
    clear; echo ""
    printf "  ${C}╔══════════════════════════════════════════════════╗${N}\n"
    printf "  ${C}║${N}  ${M}${B}  █████╗ ██╗   ██╗ ██████╗ ███████╗${N}        ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B} ██╔══██╗██║   ██║██╔════╝██╔════╝${N}        ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B} ███████║██║   ██║██║     █████╗${N}          ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B} ██╔══██║██║   ██║██║     ██╔══╝${N}  ${W}AI SENSE${N}  ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B} ██║  ██║╚██████╔╝╚██████╗███████╗${N}  ${DIM}v${VERSION}${N}  ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B} ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝${N}        ${C}║${N}\n"
    printf "  ${C}╠══════════════════════════════════════════════════╣${N}\n"
    printf "  ${C}║${N}  ${DIM}Log:${N} ${GR}%-43s${N}${C}║${N}\n" "$LOG_FILE"
    printf "  ${C}╚══════════════════════════════════════════════════╝${N}\n"
    echo ""
}

get_cpu_info() {
    info "Reading CPU information..."
    echo ""

    CPUS=$(getprop ro.product.cpu.abilist 2>/dev/null | tr ',' '\n' | wc -l)
    MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null | awk '{print $1/1000 " MHz"}')
    MIN_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null | awk '{print $1/1000 " MHz"}')
    CURRENT_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null | awk '{print $1/1000 " MHz"}')
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

    echo -e "  ${W}╭──────────────────────────────────────────╮${N}"
    echo -e "  ${W}│            CPU INFORMATION                │${N}"
    echo -e "  ${W}├──────────────────────────────────────────┤${N}"
    echo -e "  │  ${C}CPUs        ${GR}│${N}  ${W}${CPUS}${N}"
    echo -e "  │  ${C}Max Freq    ${GR}│${N}  ${W}${MAX_FREQ}${N}"
    echo -e "  │  ${C}Min Freq    ${GR}│${N}  ${W}${MIN_FREQ}${N}"
    echo -e "  │  ${C}Current     ${GR}│${N}  ${G}${CURRENT_FREQ}${N}"
    echo -e "  │  ${C}Governor    ${GR}│${N}  ${Y}${GOVERNOR}${N}"
    echo -e "  ${W}╰──────────────────────────────────────────╯${N}"
    echo ""
    log "CPU: $CPUS cores | Max: $MAX_FREQ | Current: $CURRENT_FREQ | Governor: $GOVERNOR"
}

profile_gaming() {
    banner
    echo -e "  ${M}${B}[ AI SENSE — GAMING PROFILE ]${N}"; echo ""
    warn "Maximum performance for gaming."
    warn "Higher battery drain."
    echo ""
    get_cpu_info

    info "Applying Gaming profile..."
    echo ""

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo 3000000 > "$i" 2>/dev/null
    done
    ok "CPU max frequency: 3000 MHz"

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "performance" > "$i" 2>/dev/null
    done
    ok "Governor: performance"

    if [ -f /sys/class/kgsl/kgsl-3d0/max_pwrlevel ]; then
        echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel 2>/dev/null
        ok "GPU max power level set"
    fi

    if [ -f /sys/module/cpuidle/parameters/off ]; then
        echo 1 > /sys/module/cpuidle/parameters/off 2>/dev/null
        ok "CPU idle disabled"
    fi

    echo ""
    div
    ok "Gaming profile active. Enjoy high FPS!"
    log "Gaming profile applied"
    pause
}

profile_social() {
    banner
    echo -e "  ${C}${B}[ AI SENSE — SOCIAL PROFILE ]${N}"; echo ""
    warn "Balanced performance for social apps."
    warn "Medium battery drain."
    echo ""
    get_cpu_info

    info "Applying Social Media profile..."
    echo ""

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo 2400000 > "$i" 2>/dev/null
    done
    ok "CPU max frequency: 2400 MHz"

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "interactive" > "$i" 2>/dev/null || echo "ondemand" > "$i" 2>/dev/null
    done
    ok "Governor: interactive/ondemand"

    if [ -f /sys/class/kgsl/kgsl-3d0/max_pwrlevel ]; then
        echo 2 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel 2>/dev/null
        ok "GPU power level: balanced"
    fi

    if [ -f /sys/module/cpuidle/parameters/off ]; then
        echo 0 > /sys/module/cpuidle/parameters/off 2>/dev/null
        ok "CPU idle enabled"
    fi

    echo ""
    div
    ok "Social Media profile active."
    log "Social profile applied"
    pause
}

profile_media() {
    banner
    echo -e "  ${Y}${B}[ AI SENSE — MEDIA PROFILE ]${N}"; echo ""
    warn "Optimized for streaming & video."
    warn "Focus on sustained performance."
    echo ""
    get_cpu_info

    info "Applying Media profile..."
    echo ""

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo 2800000 > "$i" 2>/dev/null
    done
    ok "CPU max frequency: 2800 MHz"

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "schedutil" > "$i" 2>/dev/null || echo "ondemand" > "$i" 2>/dev/null
    done
    ok "Governor: schedutil/ondemand"

    if [ -f /sys/class/kgsl/kgsl-3d0/max_pwrlevel ]; then
        echo 1 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel 2>/dev/null
        ok "GPU power level: high"
    fi

    echo ""
    div
    ok "Media profile active. Optimized for video streaming."
    log "Media profile applied"
    pause
}

profile_efficiency() {
    banner
    echo -e "  ${G}${B}[ AI SENSE — EFFICIENCY PROFILE ]${N}"; echo ""
    warn "Maximum battery efficiency."
    warn "Reduced performance but extended battery life."
    echo ""
    get_cpu_info

    info "Applying Efficiency profile..."
    echo ""

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo 1600000 > "$i" 2>/dev/null
    done
    ok "CPU max frequency: 1600 MHz"

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "powersave" > "$i" 2>/dev/null
    done
    ok "Governor: powersave"

    if [ -f /sys/class/kgsl/kgsl-3d0/max_pwrlevel ]; then
        echo 5 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel 2>/dev/null
        ok "GPU max power level set to lowest"
    fi

    if [ -f /sys/module/cpuidle/parameters/off ]; then
        echo 0 > /sys/module/cpuidle/parameters/off 2>/dev/null
        ok "CPU idle enabled (aggressive)"
    fi

    echo ""
    div
    ok "Efficiency profile active. Battery saver mode."
    log "Efficiency profile applied"
    pause
}

profile_custom() {
    banner
    echo -e "  ${W}${B}[ AI SENSE — CUSTOM PROFILE ]${N}"; echo ""
    warn "Create your own performance profile."
    echo ""
    get_cpu_info

    ask "Enter max CPU frequency (MHz, e.g., 2400): " MAX_MHZ
    [ -z "$MAX_MHZ" ] && MAX_MHZ=2400

    ask "Enter governor (e.g., performance, interactive, powersave): " GOVERNOR
    [ -z "$GOVERNOR" ] && GOVERNOR="interactive"

    MAX_HZ=$((MAX_MHZ * 1000))

    echo ""
    info "Applying Custom profile ($MAX_MHZ MHz, $GOVERNOR)..."
    echo ""

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo "$MAX_HZ" > "$i" 2>/dev/null
    done
    ok "CPU max frequency: ${MAX_MHZ} MHz"

    for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$GOVERNOR" > "$i" 2>/dev/null
    done
    ok "Governor: $GOVERNOR"

    echo ""
    div
    ok "Custom profile ($MAX_MHZ MHz / $GOVERNOR) active."
    log "Custom profile: ${MAX_MHZ}MHz / $GOVERNOR"
    pause
}

verify_current_profile() {
    banner
    echo -e "  ${C}${B}[ CURRENT CPU PROFILE ]${N}"; echo ""
    get_cpu_info
    pause
}

view_log() {
    banner
    echo -e "  ${W}${B}[ SESSION LOG ]${N}"; echo ""
    if [ ! -f "$LOG_FILE" ]; then
        warn "No log file found."
    else
        div
        tail -50 "$LOG_FILE" | while IFS= read -r line; do
            echo -e "  ${DIM}$line${N}"
        done
        div
    fi
    pause
}

main_menu() {
    boot_anim
    while true; do
        banner
        echo -e "  ${W}${B}  ◈  SELECT PROFILE  ◈${N}"
        echo -e "  ${GR}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${N}"
        echo ""
        echo -e "  ${M}[1]${N}  ${W}Gaming Profile${N}           ${DIM}3000 MHz · performance${N}"
        echo -e "  ${C}[2]${N}  ${W}Social Media Profile${N}     ${DIM}2400 MHz · interactive${N}"
        echo -e "  ${Y}[3]${N}  ${W}Media Profile${N}            ${DIM}2800 MHz · schedutil${N}"
        echo -e "  ${G}[4]${N}  ${W}Efficiency Profile${N}       ${DIM}1600 MHz · powersave${N}"
        echo -e "  ${W}[5]${N}  ${W}Custom Profile${N}           ${DIM}user-defined · advanced${N}"
        echo ""
        echo -e "  ${C}[0]${N}  ${W}View Current Profile${N}     ${DIM}check active settings${N}"
        echo -e "  ${GR}[L]${N}  View Log"
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE; echo ""
        log "Menu: $CHOICE"
        case "$CHOICE" in
            1) profile_gaming ;;
            2) profile_social ;;
            3) profile_media ;;
            4) profile_efficiency ;;
            5) profile_custom ;;
            0) verify_current_profile ;;
            [Ll]) view_log ;;
            [Xx]) echo ""; type_line "  Stay modding. — Lil G Tech Labs" "$GR" 0.03; echo ""; exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

main_menu
