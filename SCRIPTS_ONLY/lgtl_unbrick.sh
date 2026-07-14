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

FASTBOOT="$TBIN/fastboot"
MTKCLIENT="$TBIN/mtkclient"
VERSION="2.0"
WORK_DIR="/sdcard/LilGTechLabs"
LOG_DIR="$WORK_DIR/logs"
BACKUP_DIR="$WORK_DIR/backups"
mkdir -p "$LOG_DIR" "$BACKUP_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/lgtl_unbrick_$(date +%Y%m%d_%H%M%S).log"

log()  { echo "[$(date '+%H:%M:%S')] $(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"; }
ok()   { echo -e "  ${G}[✓]${N} $1"; log "[OK] $1"; }
err()  { echo -e "  ${R}[✗]${N} $1"; log "[ERR] $1"; }
info() { echo -e "  ${C}[*]${N} $1"; log "[INFO] $1"; }
warn() { echo -e "  ${Y}[!]${N} $1"; log "[WARN] $1"; }
ask()  { printf "${W}  ➤  %s${N}" "$1"; read -r "$2"; }
div()  { echo -e "  ${GR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
pause(){ echo ""; printf "${W}  ➤  Press Enter to continue...${N}"; read -r _D; }

run_fb() { "$FASTBOOT" -u "$@" 2>/dev/null; }

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
    type_line "     LIL G TECH LABS  ·  Unbrick / Deep Flash" "$W" 0.022
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.004
    echo ""
    pulse_bar "Initializing recovery mode" 30
    pulse_bar "Loading unbrick modules" 28
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
    printf "  ${C}║${N}  ${R}${B}██╗   ██╗███╗   ██╗██████╗ ██████╗ ██╗${N}      ${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B}██║   ██║████╗  ██║██╔══██╗██╔══██╗██║${N}      ${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B}██║   ██║██╔██╗ ██║██████╔╝██████╔╝██║${N}  ${W}Tool${N}${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B}██║   ██║██║╚██╗██║██╔══██╗██╔══██╗██║${N}      ${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B}╚██████╔╝██║ ╚████║██████╔╝██║  ██║███████╗${N}  ${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B} ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚══════╝${N}  ${C}║${N}\n"
    printf "  ${C}╠══════════════════════════════════════════════════╣${N}\n"
    printf "  ${C}║${N}  ${DIM}Log:${N} ${GR}%-43s${N}${C}║${N}\n" "$LOG_FILE"
    printf "  ${C}║${N}  ${DIM}v${VERSION}${N}  ${C}t.me/LilGTechLabs${N}  ${DIM}@Just_LiLGXX${N}        ${C}║${N}\n"
    printf "  ${C}╚══════════════════════════════════════════════════╝${N}\n"
    echo ""
}

check_brick_type() {
    banner
    echo -e "  ${Y}${B}[ DETECT BRICK TYPE ]${N}"; echo ""
    info "Detecting brick type and recovery options..."
    echo ""

    ADB="$TBIN/adb"
    if "$ADB" -H 127.0.0.1 -P 5037 get-state &>/dev/null 2>&1; then
        echo -e "  ${C}◈${N}  ${G}${B}ADB Mode${N} — Device is alive in ADB"
        echo -e "  ${DIM}    • System boots partially${N}"
        echo -e "  ${DIM}    • USB Debugging may be enabled${N}"
        echo ""
        return 0
    fi

    if run_fb getvar product 2>/dev/null; then
        echo -e "  ${C}◈${N}  ${Y}${B}Fastboot Mode${N} — Device in bootloader"
        echo -e "  ${DIM}    • Bootloader is responding${N}"
        echo -e "  ${DIM}    • Can flash via Fastboot${N}"
        echo ""
        return 1
    fi

    if lsusb 2>/dev/null | grep -i "mediatek\|mtk" >/dev/null; then
        echo -e "  ${C}◈${N}  ${R}${B}Deep Brick (MTK)${N} — MediaTek BROM mode"
        echo -e "  ${DIM}    • Device in download mode (BROM)${N}"
        echo -e "  ${DIM}    • Requires mtkclient${N}"
        echo ""
        return 2
    fi

    echo -e "  ${C}◈${N}  ${R}${B}Critical Brick${N} — No connection detected"
    echo -e "  ${DIM}    • Check USB cable and drivers${N}"
    echo -e "  ${DIM}    • Try different USB port${N}"
    echo -e "  ${DIM}    • May require JTAG / hardware repair${N}"
    echo ""
    return 3
}

recover_adb_mode() {
    banner
    echo -e "  ${G}${B}[ RECOVERY — ADB MODE ]${N}"; echo ""
    warn "Device has partial boot. ADB is responding."
    warn "This is best-case scenario — high success rate."
    echo ""

    ADB="$TBIN/adb"
    info "Waiting for ADB device..."
    "$ADB" -H 127.0.0.1 -P 5037 wait-for-device 2>/dev/null
    ok "Device connected"

    printf "  ${W}  ➤  Enter path to flashable ROM file (.zip):${N}\n  ${W}  ➤  ${N}"
    read -r ROM_FILE
    ROM_FILE=$(echo "$ROM_FILE" | tr -d '\r\n' | xargs 2>/dev/null)

    if [ ! -f "$ROM_FILE" ]; then
        err "ROM file not found: $ROM_FILE"
        pause; return
    fi

    ok "ROM selected: $(basename "$ROM_FILE") ($(du -h "$ROM_FILE" | cut -f1))"

    printf "  ${R}  ➤  Type CONFIRM to flash:${N} "; read -r _CONF
    [ "$_CONF" != "CONFIRM" ] && { warn "Aborted."; pause; return; }

    echo ""
    info "Rebooting to recovery..."
    "$ADB" -H 127.0.0.1 -P 5037 reboot recovery 2>/dev/null
    sleep 3

    info "Sideloading ROM..."
    "$ADB" -H 127.0.0.1 -P 5037 sideload "$ROM_FILE" 2>&1

    echo ""
    div
    ok "ROM flash complete. Rebooting..."
    "$ADB" -H 127.0.0.1 -P 5037 shell reboot 2>/dev/null
    log "ADB mode recovery: $ROM_FILE"
    pause
}

recover_fastboot_mode() {
    banner
    echo -e "  ${Y}${B}[ RECOVERY — FASTBOOT MODE ]${N}"; echo ""
    warn "Device in bootloader but cannot boot system."
    warn "Will flash required partitions from ROM .zip."
    echo ""

    info "Waiting for Fastboot device..."
    while ! run_fb getvar product 2>/dev/null; do
        printf "  ${Y}Waiting...${N}\r"; sleep 1
    done
    echo ""
    ok "Fastboot device detected"

    printf "  ${W}  ➤  Enter path to flashable ROM file (.zip):${N}\n  ${W}  ➤  ${N}"
    read -r ROM_FILE
    ROM_FILE=$(echo "$ROM_FILE" | tr -d '\r\n' | xargs 2>/dev/null)

    if [ ! -f "$ROM_FILE" ]; then
        err "ROM file not found: $ROM_FILE"
        pause; return
    fi

    ok "ROM selected: $(basename "$ROM_FILE") ($(du -h "$ROM_FILE" | cut -f1))"

    TMP_EXTRACT="/tmp/unbrick_rom_$$"
    mkdir -p "$TMP_EXTRACT"

    info "Extracting ROM..."
    unzip -q "$ROM_FILE" -d "$TMP_EXTRACT" 2>/dev/null
    ok "ROM extracted"

    IMAGES=$(find "$TMP_EXTRACT" -maxdepth 1 -type f \( -name "*.img" \) | sort)

    if [ -z "$IMAGES" ]; then
        warn "No .img files found in ROM"
        rm -rf "$TMP_EXTRACT"
        pause; return
    fi

    echo ""
    info "Found partition images:"
    for img in $IMAGES; do
        echo -e "  ${C}◈${N}  $(basename "$img") ($(du -h "$img" | cut -f1))"
    done
    echo ""

    printf "  ${R}  ➤  Type CONFIRM to flash all:${N} "; read -r _CONF
    [ "$_CONF" != "CONFIRM" ] && { warn "Aborted."; rm -rf "$TMP_EXTRACT"; pause; return; }

    echo ""
    for img in $IMAGES; do
        PART=$(basename "$img" | sed 's/.img$//')
        info "Flashing $PART..."
        run_fb flash "$PART" "$img" 2>&1 | tail -1
        ok "Flashed: $PART"
    done

    echo ""
    div
    ok "All partitions flashed. Rebooting..."
    run_fb reboot 2>/dev/null
    rm -rf "$TMP_EXTRACT"
    log "Fastboot mode recovery: $ROM_FILE"
    pause
}

recover_mtk_brom() {
    banner
    echo -e "  ${R}${B}[ RECOVERY — MTK DEEP BRICK (BROM) ]${N}"; echo ""
    warn "Device detected in MediaTek BROM mode."
    warn "This is a deep brick — requires mtkclient."
    warn "High success rate but more complex process."
    echo ""

    if ! command -v "$MTKCLIENT" &>/dev/null; then
        err "mtkclient not found. Install with:"
        echo -e "  ${GR}  pip install mtkclient${N}"
        pause; return
    fi

    printf "  ${W}  ➤  Enter path to MTK scatter file or ROM folder:${N}\n  ${W}  ➤  ${N}"
    read -r MTK_INPUT
    MTK_INPUT=$(echo "$MTK_INPUT" | tr -d '\r\n' | xargs 2>/dev/null)

    if [ -z "$MTK_INPUT" ]; then
        err "No input provided."
        pause; return
    fi

    info "Detected MTK device in BROM mode"
    echo ""
    warn "Device will enter deep flash mode."
    warn "Do NOT unplug USB during process (critical)."
    echo ""

    printf "  ${R}  ➤  Type DEEPFLASH to proceed:${N} "; read -r _DF
    [ "$_DF" != "DEEPFLASH" ] && { warn "Aborted."; pause; return; }

    echo ""
    info "Initiating MTK deep flash..."
    echo ""

    if [ -f "$MTK_INPUT" ]; then
        info "Using scatter file: $(basename "$MTK_INPUT")"
        "$MTKCLIENT" --payload "$MTK_INPUT" 2>&1 | tail -20
    elif [ -d "$MTK_INPUT" ]; then
        info "Using ROM directory: $(basename "$MTK_INPUT")"
        "$MTKCLIENT" --payload "$MTK_INPUT" 2>&1 | tail -20
    fi

    echo ""
    div
    warn "MTK flash process complete."
    warn "Device will reboot once firmware boots."
    log "MTK BROM recovery attempted"
    pause
}

emergency_recovery() {
    banner
    echo -e "  ${R}${B}[ EMERGENCY RECOVERY ]${N}"; echo ""
    warn "Last resort — tries all methods sequentially."
    warn "May take 10+ minutes."
    echo ""

    printf "  ${R}  ➤  Type EMERGENCY to proceed:${N} "; read -r _EMERG
    [ "$_EMERG" != "EMERGENCY" ] && { warn "Aborted."; pause; return; }

    echo ""

    echo -e "  ${Y}Phase 1: Checking ADB...${N}"
    if check_brick_type; then
        recover_adb_mode
        return
    fi

    echo -e "  ${Y}Phase 2: Checking Fastboot...${N}"
    if run_fb getvar product 2>/dev/null; then
        recover_fastboot_mode
        return
    fi

    echo -e "  ${Y}Phase 3: Checking MTK BROM...${N}"
    if lsusb 2>/dev/null | grep -i "mediatek" >/dev/null; then
        recover_mtk_brom
        return
    fi

    err "No recovery method available. Device may require hardware repair."
    log "Emergency recovery: all methods failed"
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
        echo -e "  ${W}${B}  ◈  SELECT RECOVERY METHOD  ◈${N}"
        echo -e "  ${GR}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${N}"
        echo ""
        echo -e "  ${Y}[0]${N}  ${W}Detect Brick Type${N}         ${DIM}scan device status${N}"
        echo ""
        echo -e "  ${G}[1]${N}  ${W}Recovery — ADB Mode${N}       ${DIM}partial boot · high success${N}"
        echo -e "  ${C}[2]${N}  ${W}Recovery — Fastboot Mode${N}   ${DIM}bootloader responds · partition flash${N}"
        echo -e "  ${R}[3]${N}  ${W}Recovery — MTK BROM${N}        ${DIM}deep brick · requires mtkclient${N}"
        echo ""
        echo -e "  ${R}[4]${N}  ${W}${B}Emergency Recovery${N}       ${DIM}try all methods automatically${N}"
        echo ""
        echo -e "  ${GR}[L]${N}  View Log"
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE; echo ""
        log "Menu: $CHOICE"
        case "$CHOICE" in
            0) check_brick_type; pause ;;
            1) recover_adb_mode ;;
            2) recover_fastboot_mode ;;
            3) recover_mtk_brom ;;
            4) emergency_recovery ;;
            [Ll]) view_log ;;
            [Xx]) echo ""; type_line "  Stay modding. — Lil G Tech Labs" "$GR" 0.03; echo ""; exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

main_menu
