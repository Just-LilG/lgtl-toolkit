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

ADB="$TBIN/adb"
FASTBOOT="$TBIN/fastboot"
VERSION="2.0"
WORK_DIR="/sdcard/LilGTechLabs"
LOG_DIR="$WORK_DIR/logs"
BACKUP_DIR="$WORK_DIR/backups"
mkdir -p "$LOG_DIR" "$BACKUP_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/lgtl_rom_$(date +%Y%m%d_%H%M%S).log"

log()  { echo "[$(date '+%H:%M:%S')] $(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"; }
ok()   { echo -e "  ${G}[✓]${N} $1"; log "[OK] $1"; }
err()  { echo -e "  ${R}[✗]${N} $1"; log "[ERR] $1"; }
info() { echo -e "  ${C}[*]${N} $1"; log "[INFO] $1"; }
warn() { echo -e "  ${Y}[!]${N} $1"; log "[WARN] $1"; }
ask()  { printf "${W}  ➤  %s${N}" "$1"; read -r "$2"; }
div()  { echo -e "  ${GR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
pause(){ echo ""; printf "${W}  ➤  Press Enter to continue...${N}"; read -r _D; }

run_adb() { "$ADB" -H 127.0.0.1 -P 5037 "$@" 2>/dev/null; }
run_fb()  { "$FASTBOOT" -u "$@" 2>/dev/null; }

if ! "$ADB" -H 127.0.0.1 -P 5037 get-state &>/dev/null; then
    "$ADB" start-server &>/dev/null; sleep 1
fi

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
    type_line "     LIL G TECH LABS  ·  ROM Flash Tool" "$W" 0.022
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.004
    echo ""
    pulse_bar "Initializing ADB/Fastboot" 30
    pulse_bar "Loading flash modules" 28
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
    printf "  ${C}║${N}  ${Y}${B}██████╗  ██████╗ ███╗   ███╗${N}                  ${C}║${N}\n"
    printf "  ${C}║${N}  ${Y}${B}██╔══██╗██╔═══██╗████╗ ████║${N}  ${W}Flash Tool${N}    ${C}║${N}\n"
    printf "  ${C}║${N}  ${Y}${B}██████╔╝██║   ██║██╔████╔██║${N}                  ${C}║${N}\n"
    printf "  ${C}║${N}  ${Y}${B}██╔══██╗██║   ██║██║╚██╔╝██║${N}  ${DIM}v${VERSION}${N}         ${C}║${N}\n"
    printf "  ${C}║${N}  ${Y}${B}██║  ██║╚██████╔╝██║ ╚═╝ ██║${N}  ${C}t.me/LilGTechLabs${N}${C}║${N}\n"
    printf "  ${C}║${N}  ${Y}${B}╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝${N}  ${DIM}@Just_LiLGXX${N}  ${C}║${N}\n"
    printf "  ${C}╠══════════════════════════════════════════════════╣${N}\n"
    printf "  ${C}║${N}  ${DIM}Log:${N} ${GR}%-43s${N}${C}║${N}\n" "$LOG_FILE"
    printf "  ${C}╚══════════════════════════════════════════════════╝${N}\n"
    echo ""
}

wait_adb() {
    info "Waiting for ADB device..."
    echo -e "  ${GR}  USB Debugging must be enabled on target.${N}"
    run_adb wait-for-device 2>/dev/null
    ok "Device connected!"; echo ""
}

wait_fastboot() {
    info "Waiting for Fastboot device..."
    echo -e "  ${GR}  Hold Volume Down + Power to enter Bootloader/EDL mode.${N}"
    while ! run_fb getvar product 2>/dev/null; do
        printf "  ${Y}Waiting...${N}\r"; sleep 1
    done
    echo ""
    ok "Fastboot device detected!"; echo ""
}

get_device_info() {
    DV_BRAND=$(run_adb shell getprop ro.product.brand 2>/dev/null | tr -d '\r')
    DV_MODEL=$(run_adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
    DV_ANDROID=$(run_adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
    DV_SDK=$(run_adb shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')
    DV_PRODUCT=$(run_fb getvar product 2>/dev/null | tr -d '\r')
    echo ""
    echo -e "  ${W}╭──────────────────────────────────────────╮${N}"
    echo -e "  │  ${C}Brand   ${GR}│${N}  ${W}${DV_BRAND:-$DV_PRODUCT}${N}"
    echo -e "  │  ${C}Model   ${GR}│${N}  ${W}${DV_MODEL}${N}"
    echo -e "  │  ${C}Android ${GR}│${N}  ${G}${DV_ANDROID}${N}  ${DIM}(SDK ${DV_SDK})${N}"
    echo -e "  ${W}╰──────────────────────────────────────────╯${N}"
    echo ""
    log "Device: $DV_BRAND $DV_MODEL Android $DV_ANDROID"
}

pick_rom_file() {
    banner
    echo -e "  ${C}${B}[ SELECT ROM FILE ]${N}"; echo ""
    info "Choose ROM file to flash"
    echo ""
    printf "  ${W}  Enter full path to ROM file (.zip):${N}\n  ${W}  ➤  ${N}"
    read -r ROM_FILE
    ROM_FILE=$(echo "$ROM_FILE" | tr -d '\r\n' | xargs 2>/dev/null)

    if [ ! -f "$ROM_FILE" ]; then
        err "File not found: $ROM_FILE"
        pause; return 1
    fi

    ROM_SIZE=$(du -h "$ROM_FILE" | cut -f1)
    ok "ROM selected: $(basename "$ROM_FILE") ($ROM_SIZE)"
    log "ROM: $ROM_FILE"
    return 0
}

pick_partition_file() {
    banner
    echo -e "  ${C}${B}[ SELECT PARTITION IMAGE ]${N}"; echo ""
    info "Choose partition image file to flash"
    echo ""
    printf "  ${W}  Enter full path to image file (.img or .bin):${N}\n  ${W}  ➤  ${N}"
    read -r PART_FILE
    PART_FILE=$(echo "$PART_FILE" | tr -d '\r\n' | xargs 2>/dev/null)

    if [ ! -f "$PART_FILE" ]; then
        err "File not found: $PART_FILE"
        pause; return 1
    fi

    PART_SIZE=$(du -h "$PART_FILE" | cut -f1)
    ok "Image selected: $(basename "$PART_FILE") ($PART_SIZE)"
    log "Partition image: $PART_FILE"
    return 0
}

flash_rom_recovery() {
    banner
    echo -e "  ${G}${B}[ FLASH ROM VIA RECOVERY ]${N}"; echo ""
    warn "Device must be in Recovery mode or fastboot."
    warn "Flashes complete ROM file (.zip)."
    echo ""
    wait_adb
    get_device_info

    if ! pick_rom_file; then return; fi

    printf "  ${R}  ➤  Type CONFIRM to proceed:${N} "; read -r _CONF
    [ "$_CONF" != "CONFIRM" ] && { warn "Aborted."; pause; return; }

    echo ""; info "Flashing ROM via recovery sideload..."
    echo ""

    run_adb reboot recovery
    sleep 3

    info "Waiting for recovery mode..."
    sleep 2

    printf "  ${DIM}Progress: ${N}"
    run_adb sideload "$ROM_FILE" 2>&1 | while read -r line; do
        [ -z "$line" ] || printf "."; sleep 0.05
    done
    echo ""

    ok "ROM sideload complete!"
    info "Rebooting into system..."
    run_adb shell reboot 2>/dev/null
    sleep 2

    echo ""; div
    warn "Device rebooting. This may take 2–5 minutes."
    warn "Do NOT unplug USB or turn off device."
    log "ROM flash via recovery: $ROM_FILE"
    pause
}

flash_rom_fastboot() {
    banner
    echo -e "  ${Y}${B}[ FLASH ROM VIA FASTBOOT ]${N}"; echo ""
    warn "Device must be in Fastboot/Bootloader mode."
    warn "Extracts and flashes individual partitions from ROM .zip."
    echo ""
    wait_fastboot
    get_device_info

    if ! pick_rom_file; then return; fi

    printf "  ${R}  ➤  Type CONFIRM to proceed:${N} "; read -r _CONF
    [ "$_CONF" != "CONFIRM" ] && { warn "Aborted."; pause; return; }

    TMP_EXTRACT="/tmp/rom_extract_$$"
    mkdir -p "$TMP_EXTRACT"

    echo ""; info "Extracting ROM .zip..."
    unzip -q "$ROM_FILE" -d "$TMP_EXTRACT" 2>/dev/null
    ok "ROM extracted"

    PARTITIONS=$(find "$TMP_EXTRACT" -maxdepth 1 -type f \( -name "*.img" -o -name "*.bin" \) | sort)

    if [ -z "$PARTITIONS" ]; then
        warn "No .img/.bin files found in ROM .zip"
        rm -rf "$TMP_EXTRACT"
        pause; return
    fi

    info "Found partition images:"
    echo ""
    for img in $PARTITIONS; do
        PART_NAME=$(basename "$img")
        PART_SZ=$(du -h "$img" | cut -f1)
        echo -e "  ${C}◈${N} ${W}${PART_NAME}${N} ${DIM}(${PART_SZ})${N}"
    done
    echo ""

    printf "  ${W}  ➤  Proceed with flashing all? (y/N):${N} "; read -r _PROCEED
    if [ "$_PROCEED" != "y" ] && [ "$_PROCEED" != "Y" ]; then
        warn "Aborted."; rm -rf "$TMP_EXTRACT"; pause; return
    fi

    echo ""
    FLASH_COUNT=0
    for img in $PARTITIONS; do
        PART_NAME=$(basename "${img%.img}" | sed 's/^img_//')
        PART_SZ=$(du -h "$img" | cut -f1)

        info "Flashing $PART_NAME ($PART_SZ)..."
        run_fb flash "$PART_NAME" "$img" 2>&1 | tail -1
        FLASH_COUNT=$((FLASH_COUNT+1))
        ok "Flashed: $PART_NAME"
    done

    echo ""; div
    ok "All partitions flashed! ($FLASH_COUNT total)"
    info "Rebooting into system..."
    run_fb reboot 2>/dev/null
    sleep 2

    warn "Device rebooting. This may take 2–5 minutes."
    rm -rf "$TMP_EXTRACT"
    log "ROM flash via fastboot: $FLASH_COUNT partitions from $ROM_FILE"
    pause
}

flash_single_partition() {
    banner
    echo -e "  ${C}${B}[ FLASH SINGLE PARTITION ]${N}"; echo ""
    warn "Flashes individual .img/.bin file to any partition."
    warn "Requires Fastboot/Bootloader mode."
    warn "Incorrect partition name can brick device."
    echo ""
    wait_fastboot
    get_device_info

    if ! pick_partition_file; then return; fi

    ask "Enter partition name (e.g., boot, system, recovery, vendor): " PART_NAME
    [ -z "$PART_NAME" ] && { err "No partition name entered."; pause; return; }

    echo ""
    printf "  ${R}  ➤  Type CONFIRM to flash $PART_NAME:${N} "; read -r _CONF
    [ "$_CONF" != "CONFIRM" ] && { warn "Aborted."; pause; return; }

    echo ""
    info "Flashing $PART_NAME..."
    run_fb flash "$PART_NAME" "$PART_FILE" 2>&1

    echo ""
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        ok "Partition $PART_NAME flashed successfully!"
    else
        err "Flash failed with exit code $RESULT"
    fi

    printf "  ${W}  ➤  Reboot now? (y/N):${N} "; read -r _REBOOT
    if [ "$_REBOOT" = "y" ] || [ "$_REBOOT" = "Y" ]; then
        run_fb reboot 2>/dev/null
        ok "Rebooting..."
    fi

    log "Single partition flash: $PART_NAME from $PART_FILE"
    pause
}

list_partitions() {
    banner
    echo -e "  ${M}${B}[ AVAILABLE PARTITIONS ]${N}"; echo ""
    wait_fastboot

    info "Reading partition table..."
    echo ""

    PARTITIONS=$(run_fb getvar all 2>&1 | grep "partition-type" | sed 's/partition-type://' | cut -d':' -f1 | sort -u)

    echo -e "  ${W}Fastboot partition list:${N}"
    div
    echo ""
    echo "$PARTITIONS" | while read -r part; do
        [ -n "$part" ] && echo -e "  ${C}◈${N}  ${W}${part}${N}"
    done
    echo ""
    div

    info "Common partition names:"
    echo ""
    echo -e "  ${C}boot${N}          bootloader kernel + ramdisk"
    echo -e "  ${C}system${N}        main system partition"
    echo -e "  ${C}recovery${N}      custom recovery"
    echo -e "  ${C}vendor${N}        vendor files"
    echo -e "  ${C}userdata${N}      user data (wipes cache)"
    echo -e "  ${C}cache${N}         cache partition"
    echo -e "  ${C}product${N}       product partition (A/B devices)"
    echo ""

    log "Partition list retrieved"
    pause
}

backup_partitions() {
    banner
    echo -e "  ${Y}${B}[ BACKUP PARTITIONS ]${N}"; echo ""
    warn "Backs up critical partitions to $BACKUP_DIR"
    echo ""
    wait_fastboot
    get_device_info

    ask "Enter partition names to backup (space-separated, e.g., boot system vendor): " PARTS_TO_BACKUP
    [ -z "$PARTS_TO_BACKUP" ] && { err "No partitions specified."; pause; return; }

    echo ""
    info "Starting backup..."
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    echo ""

    for part in $PARTS_TO_BACKUP; do
        BACKUP_FILE="$BACKUP_DIR/${BACKUP_TIMESTAMP}_${part}.img"
        info "Backing up $part → $(basename "$BACKUP_FILE")..."
        run_fb getvar partition-size:$part 2>/dev/null | {
            read -r SIZE_LINE
            SIZE=$(echo "$SIZE_LINE" | grep -oE '0x[0-9a-f]+' | head -1)
            if [ -n "$SIZE" ]; then
                run_fb download "$part" 2>/dev/null | xxd -r -p > "$BACKUP_FILE" 2>/dev/null
                if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
                    ok "Backed up: $part ($(du -h "$BACKUP_FILE" | cut -f1))"
                    log "Backup: $BACKUP_FILE"
                else
                    warn "Backup of $part may have failed"
                fi
            fi
        }
    done

    echo ""
    div
    ok "Backup complete. Files in: $BACKUP_DIR"
    log "Backup complete: $PARTS_TO_BACKUP"
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
        echo -e "  ${G}[1]${N}  Flash ROM via Recovery       ${DIM}sideload .zip · ADB mode${N}"
        echo -e "  ${Y}[2]${N}  Flash ROM via Fastboot       ${DIM}extract & flash · bootloader mode${N}"
        echo -e "  ${C}[3]${N}  Flash Single Partition       ${DIM}individual .img files${N}"
        echo ""
        echo -e "  ${M}[4]${N}  List Partitions              ${DIM}show available partitions${N}"
        echo -e "  ${R}[5]${N}  Backup Partitions            ${DIM}backup to ${BACKUP_DIR}${N}"
        echo ""
        echo -e "  ${GR}[L]${N}  View Log"
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE; echo ""
        log "Menu: $CHOICE"
        case "$CHOICE" in
            1) flash_rom_recovery ;;
            2) flash_rom_fastboot ;;
            3) flash_single_partition ;;
            4) list_partitions ;;
            5) backup_partitions ;;
            [Ll]) view_log ;;
            [Xx]) echo ""; type_line "  Stay modding. — Lil G Tech Labs" "$GR" 0.03; echo ""; exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

main_menu
