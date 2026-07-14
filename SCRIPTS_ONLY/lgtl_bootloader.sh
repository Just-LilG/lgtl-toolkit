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
MTKC="$TBIN/mtkclient"
VERSION="2.0"
WORK_DIR="/sdcard/LilGTechLabs"
LOG_DIR="$WORK_DIR/logs"
BACKUP_DIR="$WORK_DIR/backups"
mkdir -p "$LOG_DIR" "$BACKUP_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/lgtl_bl_$(date +%Y%m%d_%H%M%S).log"

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
    type_line "     LIL G TECH LABS  ·  Bootloader Toolkit" "$W" 0.022
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.004
    echo ""
    pulse_bar "Initializing Fastboot" 30
    pulse_bar "Loading bootloader modules" 28
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
    printf "  ${C}║${N}  ${G}${B}██████╗ ██╗      ██╗ ██╗${N}                       ${C}║${N}\n"
    printf "  ${C}║${N}  ${G}${B}██╔══██╗██║      ██║ ╚═╝${N}                       ${C}║${N}\n"
    printf "  ${C}║${N}  ${G}${B}██████╔╝██║█████╗██║${N}   ${W}Bootloader Manager${N} ${C}║${N}\n"
    printf "  ${C}║${N}  ${G}${B}██╔══██╗██║╚════╝╚═╝${N}                         ${C}║${N}\n"
    printf "  ${C}║${N}  ${G}${B}██████╔╝███████╗ ██╗${N}   ${DIM}v${VERSION}${N}              ${C}║${N}\n"
    printf "  ${C}║${N}  ${G}${B}╚═════╝ ╚══════╝ ╚═╝${N}   ${C}t.me/LilGTechLabs${N}   ${C}║${N}\n"
    printf "  ${C}╠══════════════════════════════════════════════════╣${N}\n"
    printf "  ${C}║${N}  ${DIM}Log:${N} ${GR}%-43s${N}${C}║${N}\n" "$LOG_FILE"
    printf "  ${C}╚══════════════════════════════════════════════════╝${N}\n"
    echo ""
}

wait_fastboot() {
    info "Waiting for Fastboot device..."
    echo -e "  ${GR}  Hold Volume Down + Power to enter Bootloader mode.${N}"
    while ! run_fb getvar product 2>/dev/null; do
        printf "  ${Y}Waiting...${N}\r"; sleep 1
    done
    echo ""
    ok "Fastboot device detected!"; echo ""
}

get_device_info() {
    info "Reading device information..."
    DV_PRODUCT=$(run_fb getvar product 2>/dev/null | tr -d '\r' | grep -oP 'product: \K.*')
    DV_SERIAL=$(run_fb getvar serial 2>/dev/null | tr -d '\r' | grep -oP 'serial: \K.*')
    DV_VERSION=$(run_fb getvar version 2>/dev/null | tr -d '\r' | grep -oP 'version: \K.*')
    DV_BL_STATE=$(run_fb getvar is-userspace 2>/dev/null | tr -d '\r' | grep -oP 'is-userspace: \K.*')
    DV_BOOTLOADER=$(run_fb getvar bootloader-version 2>/dev/null | tr -d '\r' | grep -oP 'bootloader-version: \K.*')

    echo ""
    echo -e "  ${W}╭──────────────────────────────────────────────╮${N}"
    echo -e "  ${W}│           BOOTLOADER INFO                     │${N}"
    echo -e "  ${W}├──────────────────────────────────────────────┤${N}"
    echo -e "  │  ${C}Product        ${GR}│${N}  ${W}${DV_PRODUCT:-unknown}${N}"
    echo -e "  │  ${C}Serial         ${GR}│${N}  ${DIM}${DV_SERIAL:-unknown}${N}"
    echo -e "  │  ${C}BL Version     ${GR}│${N}  ${W}${DV_BOOTLOADER:-unknown}${N}"
    echo -e "  │  ${C}Userspace      ${GR}│${N}  ${DV_BL_STATE:-unknown}"
    echo -e "  ${W}╰──────────────────────────────────────────────╯${N}"
    echo ""
    log "Device: product=$DV_PRODUCT serial=$DV_SERIAL"
}

unlock_bootloader() {
    banner
    echo -e "  ${R}${B}[ UNLOCK BOOTLOADER ]${N}"; echo ""
    warn "This will WIPE all device data."
    warn "User data will be deleted on first boot."
    echo ""
    wait_fastboot
    get_device_info

    printf "  ${R}  ➤  Type UNLOCK to proceed:${N} "; read -r _UNLOCK
    [ "$_UNLOCK" != "UNLOCK" ] && { warn "Aborted."; pause; return; }

    echo ""
    info "Sending unlock command..."
    run_fb oem unlock 2>&1
    sleep 2

    info "Device will reboot and perform initial setup..."
    echo ""
    div
    warn "Do NOT unplug USB during the process."
    warn "Device data is being wiped."
    log "Bootloader unlock initiated"
    pause
}

lock_bootloader() {
    banner
    echo -e "  ${G}${B}[ LOCK BOOTLOADER ]${N}"; echo ""
    warn "Bootloader will be locked."
    warn "OEM lock must be enabled in developer options."
    echo ""
    wait_fastboot
    get_device_info

    printf "  ${W}  ➤  Type LOCK to proceed:${N} "; read -r _LOCK
    [ "$_LOCK" != "LOCK" ] && { warn "Aborted."; pause; return; }

    echo ""
    info "Sending lock command..."
    run_fb oem lock 2>&1
    sleep 2

    info "Bootloader is now locked."
    echo ""
    div
    ok "Bootloader locked. Device will reboot."
    log "Bootloader lock initiated"
    pause
}

flash_bootloader() {
    banner
    echo -e "  ${Y}${B}[ FLASH BOOTLOADER ]${N}"; echo ""
    warn "Flashes bootloader/MLO/XLOADER file."
    warn "Incorrect bootloader can brick the device."
    echo ""
    wait_fastboot
    get_device_info

    printf "  ${W}  Enter path to bootloader .img/.bin file:${N}\n  ${W}  ➤  ${N}"
    read -r BL_FILE
    BL_FILE=$(echo "$BL_FILE" | tr -d '\r\n' | xargs 2>/dev/null)

    if [ ! -f "$BL_FILE" ]; then
        err "File not found: $BL_FILE"
        pause; return
    fi

    ok "Bootloader file: $(basename "$BL_FILE") ($(du -h "$BL_FILE" | cut -f1))"

    printf "  ${R}  ➤  Type FLASH to proceed:${N} "; read -r _FLASH
    [ "$_FLASH" != "FLASH" ] && { warn "Aborted."; pause; return; }

    echo ""
    info "Flashing bootloader..."
    run_fb flash bootloader "$BL_FILE" 2>&1

    echo ""
    div
    ok "Bootloader flashed. Rebooting..."
    run_fb reboot-bootloader 2>/dev/null
    log "Bootloader flash: $BL_FILE"
    pause
}

wipe_userdata() {
    banner
    echo -e "  ${R}${B}[ WIPE USERDATA ]${N}"; echo ""
    warn "This will DELETE all user data and cache."
    warn "Device storage will be cleared."
    echo ""
    wait_fastboot
    get_device_info

    printf "  ${R}  ➤  Type WIPE to confirm:${N} "; read -r _WIPE
    [ "$_WIPE" != "WIPE" ] && { warn "Aborted."; pause; return; }

    echo ""
    info "Wiping userdata..."
    run_fb erase userdata 2>&1
    ok "Userdata erased"

    info "Wiping cache..."
    run_fb erase cache 2>&1
    ok "Cache erased"

    echo ""
    div
    ok "Wipe complete. Device is now clean."
    log "Userdata and cache wiped"
    pause
}

wipe_all() {
    banner
    echo -e "  ${R}${B}[ FULL DEVICE WIPE ]${N}"; echo ""
    warn "This will erase EVERYTHING on the device."
    warn "System, data, cache, and internal storage will be deleted."
    echo ""
    wait_fastboot
    get_device_info

    printf "  ${R}  ➤  Type WIPEALL to confirm:${N} "; read -r _WIPEALL
    [ "$_WIPEALL" != "WIPEALL" ] && { warn "Aborted."; pause; return; }

    echo ""
    info "Wiping all partitions..."
    for part in userdata cache; do
        run_fb erase "$part" 2>&1
    done
    ok "All partitions wiped"

    echo ""
    div
    ok "Full wipe complete."
    log "Full device wipe completed"
    pause
}

format_userdata() {
    banner
    echo -e "  ${Y}${B}[ FORMAT USERDATA ]${N}"; echo ""
    warn "Formats userdata partition with filesystem."
    echo ""
    wait_fastboot
    get_device_info

    ask "Enter filesystem type (ext4 or f2fs): " FS_TYPE
    [ -z "$FS_TYPE" ] && FS_TYPE="ext4"

    printf "  ${W}  ➤  Format to ${FS_TYPE}? (y/N):${N} "; read -r _FORMAT
    [ "$_FORMAT" != "y" ] && [ "$_FORMAT" != "Y" ] && { warn "Aborted."; pause; return; }

    echo ""
    info "Formatting userdata to $FS_TYPE..."
    run_fb format userdata 2>&1

    echo ""
    div
    ok "Userdata formatted to $FS_TYPE"
    log "Userdata formatted: $FS_TYPE"
    pause
}

backup_bootloader() {
    banner
    echo -e "  ${C}${B}[ BACKUP BOOTLOADER ]${N}"; echo ""
    info "Backs up bootloader partition."
    echo ""
    wait_fastboot
    get_device_info

    BACKUP_FILE="$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)_bootloader.img"

    info "Reading bootloader partition size..."
    SIZE_INFO=$(run_fb getvar partition-size:bootloader 2>&1)
    SIZE=$(echo "$SIZE_INFO" | grep -oE '0x[0-9a-f]+' | head -1)

    if [ -z "$SIZE" ]; then
        warn "Could not determine bootloader size. Using fastboot download..."
        run_fb download bootloader 2>/dev/null | xxd -r -p > "$BACKUP_FILE" 2>/dev/null
    else
        info "Downloading bootloader (size: $SIZE)..."
        run_fb download bootloader 2>/dev/null | xxd -r -p > "$BACKUP_FILE" 2>/dev/null
    fi

    if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
        ok "Bootloader backed up: $(du -h "$BACKUP_FILE" | cut -f1)"
        echo -e "  ${DIM}Location: ${BACKUP_FILE}${N}"
        log "Bootloader backup: $BACKUP_FILE"
    else
        warn "Backup may have failed. File not created or is empty."
    fi

    pause
}

reboot_options() {
    banner
    echo -e "  ${M}${B}[ REBOOT OPTIONS ]${N}"; echo ""
    echo ""
    echo -e "  ${C}[1]${N}  Reboot to System"
    echo -e "  ${C}[2]${N}  Reboot to Bootloader"
    echo -e "  ${C}[3]${N}  Reboot to Recovery"
    echo -e "  ${C}[4]${N}  Reboot to EDL (Deep Flash)"
    echo ""
    ask "Choose: " REBOOT_OPT
    echo ""

    case "$REBOOT_OPT" in
        1)
            wait_fastboot
            info "Rebooting to system..."
            run_fb reboot 2>/dev/null
            ok "Device rebooting"
            ;;
        2)
            wait_fastboot
            info "Rebooting to bootloader..."
            run_fb reboot-bootloader 2>/dev/null
            ok "Device rebooting to bootloader"
            ;;
        3)
            wait_fastboot
            info "Rebooting to recovery..."
            run_fb reboot recovery 2>/dev/null
            ok "Device rebooting to recovery"
            ;;
        4)
            wait_fastboot
            info "Attempting to reboot to EDL mode..."
            run_fb oem edl 2>/dev/null || run_fb reboot edl 2>/dev/null
            ok "EDL mode requested"
            ;;
        *)
            warn "Invalid option"
            ;;
    esac
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
        echo -e "  ${W}${B}  ◈  SELECT OPERATION  ◈${N}"
        echo -e "  ${GR}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${N}"
        echo ""
        echo -e "  ${R}[1]${N}  Unlock Bootloader           ${DIM}enables device modifications${N}"
        echo -e "  ${G}[2]${N}  Lock Bootloader             ${DIM}restricts device access${N}"
        echo ""
        echo -e "  ${Y}[3]${N}  Flash Bootloader            ${DIM}replace bootloader image${N}"
        echo -e "  ${C}[4]${N}  Backup Bootloader           ${DIM}save bootloader to file${N}"
        echo ""
        echo -e "  ${R}[5]${N}  Wipe Userdata               ${DIM}clear data partition${N}"
        echo -e "  ${R}[6]${N}  Wipe Cache                  ${DIM}clear cache partition${N}"
        echo -e "  ${R}[7]${N}  Full Wipe (All Data)        ${DIM}complete device wipe${N}"
        echo -e "  ${Y}[8]${N}  Format Userdata             ${DIM}reformat to ext4/f2fs${N}"
        echo ""
        echo -e "  ${M}[9]${N}  Reboot Options              ${DIM}reboot to various modes${N}"
        echo ""
        echo -e "  ${GR}[L]${N}  View Log"
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE; echo ""
        log "Menu: $CHOICE"
        case "$CHOICE" in
            1) unlock_bootloader ;;
            2) lock_bootloader ;;
            3) flash_bootloader ;;
            4) backup_bootloader ;;
            5) wipe_userdata ;;
            6) wipe_userdata ;;
            7) wipe_all ;;
            8) format_userdata ;;
            9) reboot_options ;;
            [Ll]) view_log ;;
            [Xx]) echo ""; type_line "  Stay modding. — Lil G Tech Labs" "$GR" 0.03; echo ""; exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

main_menu
