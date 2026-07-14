#!/data/data/com.termux/files/usr/bin/bash

LGTL_VERSION="3.0"
LGTL_AUTHOR="Lil G"
LGTL_CHANNEL="t.me/LilGTechLabs"
LGTL_HANDLE="@Just_LiLGXX"

R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
W='\033[1;37m'
GR='\033[0;37m'
M='\033[0;35m'
B='\033[1m'
DIM='\033[2m'
N='\033[0m'
BLD='\033[1m'
UL='\033[4m'
BG_R='\033[41m'
BG_G='\033[42m'
BG_B='\033[44m'
BG_C='\033[46m'

LGTL_BASE="/sdcard/LilGTechLabs"
LGTL_LOGS="$LGTL_BASE/logs"
LGTL_TOOLS="$LGTL_BASE/tools"
LGTL_BACKUPS="$LGTL_BASE/backups"
LGTL_PICKER="$LGTL_BASE/.picker_files"
LGTL_TMP="$LGTL_BASE/.tmp"
TBIN="/data/data/com.termux/files/usr/bin"
TPRE="/data/data/com.termux/files/usr"
export PATH="$TBIN:$TPRE/sbin:$PATH"
export LD_LIBRARY_PATH="$TPRE/lib:$LD_LIBRARY_PATH"
export TMPDIR="$TPRE/tmp"

mkdir -p "$LGTL_LOGS" "$LGTL_TOOLS" "$LGTL_BACKUPS" "$LGTL_PICKER" "$LGTL_TMP" "$TMPDIR" 2>/dev/null

_LOG_FILE="${_LOG_FILE:-$LGTL_LOGS/lgtl_$(date +%Y%m%d_%H%M%S).log}"

log()  { echo "[$(date '+%H:%M:%S')] $(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$_LOG_FILE"; }
ok()   { echo -e "  ${G}[✓]${N} $1"; log "[OK] $1"; }
err()  { echo -e "  ${R}[✗]${N} $1"; log "[ERR] $1"; }
info() { echo -e "  ${C}[*]${N} $1"; log "[INFO] $1"; }
warn() { echo -e "  ${Y}[!]${N} $1"; log "[WARN] $1"; }
ask()  { printf "${W}  ➤  %s${N}" "$1"; read -r "$2"; log "INPUT[$2]: $(eval echo \$$2)"; }
div()  { echo -e "  ${GR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
div2() { echo -e "  ${C}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${N}"; }
pause(){ echo ""; printf "${W}  ➤  Press Enter to continue...${N}"; read -r _D; }

type_line() {
    local text="$1" color="${2:-$W}" delay="${3:-0.03}"
    local i=0
    while [ $i -lt ${#text} ]; do
        printf "${color}%s${N}" "${text:$i:1}"
        sleep "$delay"
        i=$((i+1))
    done
    printf "\n"
}

pulse_bar() {
    local label="$1" steps="${2:-30}"
    printf "  ${DIM}%-34s${N} [" "$label"
    local i=0
    while [ $i -lt $steps ]; do
        local r=$(( (i * 1103515245 + 12345) % 3 ))
        case $r in
            0) printf "${G}█${N}" ;;
            1) printf "${C}▓${N}" ;;
            2) printf "${GR}░${N}" ;;
        esac
        sleep 0.018
        i=$((i+1))
    done
    printf "] ${G}✔${N}\n"
}

scan_check() {
    local label="$1" result="${2:-OK}" color="${3:-$G}"
    printf "  ${C}◈${N} %-34s" "$label"
    local i=0
    while [ $i -lt 6 ]; do
        printf "${C}·${N}"; sleep 0.05
        i=$((i+1))
    done
    printf " ${color}%s${N}\n" "$result"
}

lgtl_footer() {
    echo ""
    div
    printf "  ${DIM}%s${N}  ${GR}│${N}  ${C}%s${N}  ${GR}│${N}  ${DIM}v%s${N}\n" "$LGTL_AUTHOR" "$LGTL_CHANNEL" "$LGTL_VERSION"
    div
}

confirm_danger() {
    local msg="${1:-Type CONFIRM to proceed}"
    local keyword="${2:-CONFIRM}"
    echo ""
    printf "  ${R}[!]${N} ${W}%s:${N} " "$msg"
    read -r _CDANGER
    [ "$_CDANGER" = "$keyword" ]
}

yn_prompt() {
    local msg="$1"
    printf "  ${W}➤  %s (y/N):${N} " "$msg"
    read -r _YN
    [ "$_YN" = "y" ] || [ "$_YN" = "Y" ]
}

pick_file() {
    local PROMPT="${1:-Select a file}" VAR_NAME="$2"
    local TMP_RAW="$LGTL_TMP/.picker_raw"
    mkdir -p "$LGTL_PICKER" 2>/dev/null
    echo ""
    info "$PROMPT"
    echo ""
    rm -f "$TMP_RAW"
    termux-storage-get "$TMP_RAW"
    local WAIT=0 FSIZE=0
    while [ $WAIT -lt 90 ]; do
        if [ -f "$TMP_RAW" ]; then
            FSIZE=$(stat -c%s "$TMP_RAW" 2>/dev/null || echo 0)
            [ "$FSIZE" -gt 0 ] && break
        fi
        sleep 1; WAIT=$((WAIT+1))
        printf "  ${Y}Waiting for file picker... %ds${N}\r" "$WAIT"
    done
    echo ""
    if [ -f "$TMP_RAW" ] && [ "$FSIZE" -gt 0 ]; then
        local EXT=""
        local MAGIC
        MAGIC=$(xxd -l 4 "$TMP_RAW" 2>/dev/null | head -1)
        case "$MAGIC" in
            *"504b 0304"*) EXT=".zip" ;;
            *"7f45 4c46"*) EXT=".img" ;;
            *"4153 4349"*) EXT=".img" ;;
            *"3a20 7370"*) EXT=".img" ;;
            *"d00d feed"*|*"feed d00d"*) EXT=".img" ;;
        esac
        if [ -z "$EXT" ]; then
            if unzip -l "$TMP_RAW" &>/dev/null; then EXT=".zip"; else EXT=".img"; fi
        fi
        local DEST="$LGTL_PICKER/picked_$(date +%H%M%S)${EXT}"
        cp "$TMP_RAW" "$DEST"
        ok "File received: $(du -h "$DEST" | cut -f1) → $(basename "$DEST")"
        log "File picked: $DEST"
        printf -v "$VAR_NAME" "%s" "$DEST"
        return 0
    fi
    warn "No file selected. Enter path manually:"
    printf "  ${W}  ➤  Path: ${N}"; read -r PICKED
    PICKED=$(echo "$PICKED" | tr -d '\r\n' | xargs 2>/dev/null)
    if [ ! -f "$PICKED" ]; then
        err "File not found: $PICKED"
        printf -v "$VAR_NAME" "%s" ""
        return 1
    fi
    ok "Selected: $(basename "$PICKED") ($(du -h "$PICKED" | cut -f1))"
    printf -v "$VAR_NAME" "%s" "$PICKED"
    return 0
}

pick_file_optional() {
    local PROMPT="${1:-Select a file (optional)}" VAR_NAME="$2"
    echo ""
    info "$PROMPT ${DIM}(optional)${N}"
    if yn_prompt "Open file picker?"; then
        pick_file "$PROMPT" "$VAR_NAME"
    else
        printf -v "$VAR_NAME" "%s" ""
        info "Skipped."
    fi
}

require_root() {
    if [ "$(id -u)" != "0" ] && [ -z "$LGTL_ROOT_INHERITED" ]; then
        exec su -c "LGTL_ROOT_INHERITED=1 $TBIN/bash $0"
        exit 1
    fi
    export LGTL_ROOT_INHERITED=1
}

adb_init() {
    ADB="$TBIN/adb"
    if ! "$ADB" -H 127.0.0.1 -P 5037 get-state &>/dev/null; then
        "$ADB" start-server &>/dev/null
        sleep 1
    fi
}

run_adb() { "$ADB" -H 127.0.0.1 -P 5037 "$@" 2>/dev/null; }

wait_adb() {
    info "Waiting for ADB device..."
    echo -e "  ${GR}  USB Debugging must be enabled on target.${N}"
    run_adb wait-for-device 2>/dev/null
    ok "Device connected!"
    echo ""
}

get_device_info_adb() {
    DV_BRAND=$(run_adb shell getprop ro.product.brand 2>/dev/null | tr -d '\r')
    DV_MODEL=$(run_adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
    DV_ANDROID=$(run_adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
    DV_SDK=$(run_adb shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')
    DV_CHIPSET=$(run_adb shell getprop ro.hardware 2>/dev/null | tr -d '\r')
    DV_SERIAL=$(run_adb get-serialno 2>/dev/null | tr -d '\r')
    DV_ARCH=$(run_adb shell getprop ro.product.cpu.abi 2>/dev/null | tr -d '\r')
    DV_BL=$(run_adb shell getprop ro.boot.flash.locked 2>/dev/null | tr -d '\r')
    OEM_UNLOCK=$(run_adb shell settings get global oem_unlock_allowed 2>/dev/null | tr -d '\r')
    echo ""
    echo -e "  ${W}╭──────────────────────────────────────────╮${N}"
    echo -e "  ${W}│           TARGET DEVICE INFO              │${N}"
    echo -e "  ${W}├──────────────────────────────────────────┤${N}"
    echo -e "  │  ${C}Brand   ${GR}│${N}  ${W}${DV_BRAND}${N}"
    echo -e "  │  ${C}Model   ${GR}│${N}  ${W}${DV_MODEL}${N}"
    echo -e "  │  ${C}Android ${GR}│${N}  ${G}${DV_ANDROID}${N}  ${DIM}(SDK ${DV_SDK})${N}"
    echo -e "  │  ${C}Chipset ${GR}│${N}  ${DV_CHIPSET}"
    echo -e "  │  ${C}Arch    ${GR}│${N}  ${DV_ARCH}"
    echo -e "  │  ${C}Serial  ${GR}│${N}  ${DIM}${DV_SERIAL}${N}"
    echo -e "  ${W}╰──────────────────────────────────────────╯${N}"
    echo ""
    log "Device: $DV_BRAND $DV_MODEL Android $DV_ANDROID SDK $DV_SDK Serial $DV_SERIAL"
}

boot_anim_shared() {
    local tool_name="$1"
    clear
    echo ""
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.005
    type_line "     LIL G TECH LABS  ·  $tool_name" "$W" 0.025
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.005
    echo ""
    pulse_bar "Initializing environment" 30
    pulse_bar "Loading tool modules" 26
    if [ "$(id -u)" = "0" ]; then
        scan_check "Root access" "GRANTED" "$G"
    else
        scan_check "Root access" "LIMITED" "$Y"
    fi
    if "$TBIN/adb" -H 127.0.0.1 -P 5037 get-state &>/dev/null 2>&1; then
        scan_check "ADB connection" "ACTIVE" "$G"
    else
        scan_check "ADB connection" "STANDBY" "$GR"
    fi
    echo ""
    sleep 0.2
}
