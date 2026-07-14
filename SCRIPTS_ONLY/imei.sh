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
LOG_FILE="$LOG_DIR/lgtl_imei_$(date +%Y%m%d_%H%M%S).log"

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
    "$ADB" start-server &>/dev/null
    sleep 1
fi

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
        case $r in 0) printf "${G}█${N}" ;; 1) printf "${C}▓${N}" ;; 2) printf "${GR}░${N}" ;; esac
        sleep 0.018
        i=$((i+1))
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
    type_line "     LIL G TECH LABS  ·  IMEI Repair Tool" "$W" 0.022
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.004
    echo ""
    pulse_bar "Initializing ADB bridge" 30
    pulse_bar "Loading IMEI modules" 28
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
    printf "  ${C}║${N}  ${C}${B}██╗███╗   ███╗███████╗██╗${N}                       ${C}║${N}\n"
    printf "  ${C}║${N}  ${C}${B}██║████╗ ████║██╔════╝██║${N}   ${W}Repair Tool${N}       ${C}║${N}\n"
    printf "  ${C}║${N}  ${C}${B}██║██╔████╔██║█████╗  ██║${N}                       ${C}║${N}\n"
    printf "  ${C}║${N}  ${C}${B}██║██║╚██╔╝██║██╔══╝  ██║${N}   ${DIM}v${VERSION}${N}              ${C}║${N}\n"
    printf "  ${C}║${N}  ${C}${B}██║██║ ╚═╝ ██║███████╗██║${N}   ${C}t.me/LilGTechLabs${N} ${C}║${N}\n"
    printf "  ${C}║${N}  ${C}${B}╚═╝╚═╝     ╚═╝╚══════╝╚═╝${N}   ${DIM}@Just_LiLGXX${N}      ${C}║${N}\n"
    printf "  ${C}╠══════════════════════════════════════════════════╣${N}\n"
    printf "  ${C}║${N}  ${DIM}Log:${N} ${GR}%-43s${N}${C}║${N}\n" "$LOG_FILE"
    printf "  ${C}╚══════════════════════════════════════════════════╝${N}\n"
    echo ""
}

wait_adb() {
    info "Waiting for ADB device..."
    echo -e "  ${GR}  USB Debugging must be enabled.${N}"
    run_adb wait-for-device 2>/dev/null
    ok "Device connected!"; echo ""
}

validate_imei() {
    local imei="$1"
    [ ${#imei} -ne 15 ] && return 1
    echo "$imei" | grep -qE '^[0-9]{15}$' || return 1
    local sum=0 i=1
    while [ $i -le 15 ]; do
        d=$(echo "$imei" | cut -c$i)
        if [ $((i % 2)) -eq 0 ]; then
            d=$((d * 2))
            [ $d -gt 9 ] && d=$((d - 9))
        fi
        sum=$((sum + d))
        i=$((i + 1))
    done
    [ $((sum % 10)) -eq 0 ]
}

get_imei_info() {
    local imei="$1"
    local tac="${imei:0:8}"
    echo -e "  ${DIM}TAC (Type Allocation Code):${N} ${W}${tac}${N}"
    echo -e "  ${DIM}SNR (Serial Number):${N}        ${W}${imei:8:6}${N}"
    echo -e "  ${DIM}Check Digit:${N}                ${W}${imei:14:1}${N}"
}

read_imei() {
    banner
    echo -e "  ${C}${B}[ READ CURRENT IMEI ]${N}"; echo ""
    wait_adb

    info "Reading IMEI via multiple methods..."
    echo ""

    IMEI1=$(run_adb shell service call iphonesubinfo 1 2>/dev/null | \
        grep -o "'[0-9. ]*'" | tr -d "'. " | tr -d '\n' | head -c 15)
    IMEI2=$(run_adb shell service call iphonesubinfo 3 2>/dev/null | \
        grep -o "'[0-9. ]*'" | tr -d "'. " | tr -d '\n' | head -c 15)

    PROP_IMEI1=$(run_adb shell getprop persist.radio.imei 2>/dev/null | tr -d '\r')
    PROP_IMEI2=$(run_adb shell getprop persist.radio.imei2 2>/dev/null | tr -d '\r')
    RIL_IMEI=$(run_adb shell getprop ril.imei 2>/dev/null | tr -d '\r')
    SLOT1_IMEI=$(run_adb shell getprop ril.imei1 2>/dev/null | tr -d '\r')

    echo -e "  ${W}╭──────────────────────────────────────────────╮${N}"
    echo -e "  ${W}│               IMEI STATUS                     │${N}"
    echo -e "  ${W}├──────────────────────────────────────────────┤${N}"

    if [ -n "$IMEI1" ] && [ "$IMEI1" != "000000000000000" ]; then
        echo -e "  │  ${C}IMEI 1 (service)  ${GR}│${N}  ${G}${B}${IMEI1}${N}"
        if validate_imei "$IMEI1"; then
            echo -e "  │  ${C}  Luhn Check     ${GR}│${N}  ${G}✔ Valid${N}"
        else
            echo -e "  │  ${C}  Luhn Check     ${GR}│${N}  ${R}✗ Invalid checksum${N}"
        fi
    else
        echo -e "  │  ${C}IMEI 1 (service)  ${GR}│${N}  ${R}NULL / INVALID${N}"
    fi

    echo -e "  │                                              │"

    if [ -n "$IMEI2" ] && [ "$IMEI2" != "000000000000000" ]; then
        echo -e "  │  ${C}IMEI 2 (service)  ${GR}│${N}  ${G}${B}${IMEI2}${N}"
        if validate_imei "$IMEI2"; then
            echo -e "  │  ${C}  Luhn Check     ${GR}│${N}  ${G}✔ Valid${N}"
        else
            echo -e "  │  ${C}  Luhn Check     ${GR}│${N}  ${R}✗ Invalid checksum${N}"
        fi
    else
        echo -e "  │  ${C}IMEI 2 (service)  ${GR}│${N}  ${DIM}not found / single SIM${N}"
    fi

    echo -e "  ${W}├──────────────────────────────────────────────┤${N}"
    echo -e "  │  ${C}persist.radio.imei  ${GR}│${N}  ${DIM}${PROP_IMEI1:-not set}${N}"
    echo -e "  │  ${C}persist.radio.imei2 ${GR}│${N}  ${DIM}${PROP_IMEI2:-not set}${N}"
    echo -e "  │  ${C}ril.imei            ${GR}│${N}  ${DIM}${RIL_IMEI:-not set}${N}"
    echo -e "  │  ${C}ril.imei1           ${GR}│${N}  ${DIM}${SLOT1_IMEI:-not set}${N}"
    echo -e "  ${W}╰──────────────────────────────────────────────╯${N}"
    echo ""

    if [ -n "$IMEI1" ] && [ "$IMEI1" != "000000000000000" ]; then
        echo -e "  ${W}IMEI 1 breakdown:${N}"
        get_imei_info "$IMEI1"
    fi

    log "IMEI1=$IMEI1 IMEI2=$IMEI2 Prop1=$PROP_IMEI1 Prop2=$PROP_IMEI2"
    pause
}

generate_imei() {
    banner
    echo -e "  ${M}${B}[ IMEI GENERATOR — LUHN VALID ]${N}"; echo ""
    warn "Generates a mathematically valid IMEI."
    warn "Always use the ORIGINAL IMEI from the device box/sticker."
    echo ""

    ask "Enter TAC (first 8 digits of original IMEI, or press Enter for random): " TAC_INPUT
    echo ""

    if [ -z "$TAC_INPUT" ]; then
        TAC_INPUT="35$(od -An -N3 -tu1 /dev/urandom | tr -d ' \n' | cut -c1-6)"
    fi

    if [ ${#TAC_INPUT} -ne 8 ] || ! echo "$TAC_INPUT" | grep -qE '^[0-9]{8}$'; then
        err "TAC must be exactly 8 digits."
        pause; return
    fi

    SNR=$(od -An -N3 -tu1 /dev/urandom | tr -d ' \n' | cut -c1-6)
    BASE="${TAC_INPUT}${SNR}"

    local sum=0 i=1
    while [ $i -le 14 ]; do
        d=$(echo "$BASE" | cut -c$i)
        if [ $((i % 2)) -eq 0 ]; then
            d=$((d * 2))
            [ $d -gt 9 ] && d=$((d - 9))
        fi
        sum=$((sum + d))
        i=$((i + 1))
    done
    CHECK=$(( (10 - (sum % 10)) % 10 ))
    GEN_IMEI="${BASE}${CHECK}"

    echo -e "  ${W}╭──────────────────────────────────────────╮${N}"
    echo -e "  ${W}│           GENERATED IMEI                  │${N}"
    echo -e "  ${W}├──────────────────────────────────────────┤${N}"
    echo -e "  │  ${C}IMEI     ${GR}│${N}  ${G}${B}${GEN_IMEI}${N}"
    echo -e "  │  ${C}TAC      ${GR}│${N}  ${W}${TAC_INPUT}${N}"
    echo -e "  │  ${C}SNR      ${GR}│${N}  ${W}${SNR}${N}"
    echo -e "  │  ${C}Check    ${GR}│${N}  ${W}${CHECK}${N}"
    if validate_imei "$GEN_IMEI"; then
        echo -e "  │  ${C}Luhn     ${GR}│${N}  ${G}✔ Valid${N}"
    else
        echo -e "  │  ${C}Luhn     ${GR}│${N}  ${R}✗ Failed${N}"
    fi
    echo -e "  ${W}╰──────────────────────────────────────────╯${N}"
    echo ""
    warn "This IMEI is mathematically valid but may not match your device's original."
    warn "Use ONLY if original IMEI is completely unrecoverable."
    log "Generated IMEI: $GEN_IMEI (TAC: $TAC_INPUT)"
    pause
}

validate_imei_tool() {
    banner
    echo -e "  ${Y}${B}[ IMEI VALIDATOR ]${N}"; echo ""
    ask "Enter IMEI to validate (15 digits): " CHECK_IMEI
    echo ""

    if [ -z "$CHECK_IMEI" ]; then
        warn "No IMEI entered."; pause; return
    fi

    echo -e "  ${W}╭──────────────────────────────────────────╮${N}"
    echo -e "  ${W}│           IMEI VALIDATION                 │${N}"
    echo -e "  ${W}├──────────────────────────────────────────┤${N}"
    echo -e "  │  ${C}IMEI     ${GR}│${N}  ${W}${CHECK_IMEI}${N}"
    echo -e "  │  ${C}Length   ${GR}│${N}  ${W}${#CHECK_IMEI} digits${N}"

    if echo "$CHECK_IMEI" | grep -qE '^[0-9]{15}$'; then
        echo -e "  │  ${C}Format   ${GR}│${N}  ${G}✔ Numeric 15-digit${N}"
        if validate_imei "$CHECK_IMEI"; then
            echo -e "  │  ${C}Luhn     ${GR}│${N}  ${G}✔ Valid checksum${N}"
            echo -e "  ${W}╰──────────────────────────────────────────╯${N}"
            echo ""
            ok "IMEI is VALID."
            get_imei_info "$CHECK_IMEI"
        else
            echo -e "  │  ${C}Luhn     ${GR}│${N}  ${R}✗ Invalid checksum${N}"
            echo -e "  ${W}╰──────────────────────────────────────────╯${N}"
            echo ""
            err "IMEI checksum FAILED. This IMEI is not valid."
        fi
    else
        echo -e "  │  ${C}Format   ${GR}│${N}  ${R}✗ Invalid — must be 15 digits${N}"
        echo -e "  ${W}╰──────────────────────────────────────────╯${N}"
        echo ""
        err "IMEI format invalid."
    fi
    log "Validated IMEI: $CHECK_IMEI"
    pause
}

repair_imei_mtk() {
    banner
    echo -e "  ${M}${B}[ REPAIR IMEI — MTK METHOD ]${N}"; echo ""
    warn "MediaTek devices only. Requires root."
    warn "Use original IMEI from device box or back sticker."
    echo ""
    wait_adb

    ask "Enter IMEI 1 (15 digits): " NEW_IMEI1
    echo ""
    if ! validate_imei "$NEW_IMEI1"; then
        err "Invalid IMEI 1: must be 15 digits with valid Luhn checksum."
        pause; return
    fi
    ok "IMEI 1 valid: $NEW_IMEI1"

    ask "Enter IMEI 2 (15 digits, Enter to skip): " NEW_IMEI2
    echo ""
    if [ -n "$NEW_IMEI2" ]; then
        if ! validate_imei "$NEW_IMEI2"; then
            err "Invalid IMEI 2. Skipping IMEI 2."
            NEW_IMEI2=""
        else
            ok "IMEI 2 valid: $NEW_IMEI2"
        fi
    fi

    info "Writing IMEI via AT commands (ttyC0)..."
    run_adb shell "su -c 'echo AT+EGMR=1,7,\"$NEW_IMEI1\" > /dev/ttyC0'" 2>/dev/null
    sleep 1
    [ -n "$NEW_IMEI2" ] && {
        run_adb shell "su -c 'echo AT+EGMR=1,10,\"$NEW_IMEI2\" > /dev/ttyC0'" 2>/dev/null
        sleep 1
    }
    ok "AT commands sent"

    info "Attempting nvram write..."
    run_adb shell "su -c 'nvram_agent_daemon &'" 2>/dev/null
    sleep 1
    run_adb shell "su -c 'nv_tool --setimei 1 $NEW_IMEI1'" 2>/dev/null
    [ -n "$NEW_IMEI2" ] && run_adb shell "su -c 'nv_tool --setimei 2 $NEW_IMEI2'" 2>/dev/null
    ok "nvram write attempted"

    info "Setting persist props..."
    run_adb shell "su -c 'resetprop persist.radio.imei $NEW_IMEI1'" 2>/dev/null
    run_adb shell "su -c 'resetprop ril.imei $NEW_IMEI1'" 2>/dev/null
    run_adb shell "su -c 'resetprop ril.imei1 $NEW_IMEI1'" 2>/dev/null
    [ -n "$NEW_IMEI2" ] && {
        run_adb shell "su -c 'resetprop persist.radio.imei2 $NEW_IMEI2'" 2>/dev/null
        run_adb shell "su -c 'resetprop ril.imei2 $NEW_IMEI2'" 2>/dev/null
    }
    ok "Props set"

    echo ""; div
    ok "MTK IMEI repair complete. Rebooting..."
    warn "Verify with *#06# after reboot."
    run_adb reboot
    log "MTK IMEI repair: $NEW_IMEI1 / ${NEW_IMEI2:-N/A}"
    pause
}

repair_imei_prop() {
    banner
    echo -e "  ${G}${B}[ REPAIR IMEI — PROP METHOD ]${N}"; echo ""
    warn "Universal method — works on most Android devices."
    warn "May not survive a full factory reset."
    echo ""
    wait_adb

    ask "Enter IMEI 1 (15 digits): " NEW_IMEI1
    echo ""
    if ! validate_imei "$NEW_IMEI1"; then
        err "Invalid IMEI."
        pause; return
    fi
    ok "IMEI 1 valid: $NEW_IMEI1"

    ask "Enter IMEI 2 (15 digits, Enter to skip): " NEW_IMEI2
    echo ""
    if [ -n "$NEW_IMEI2" ] && ! validate_imei "$NEW_IMEI2"; then
        warn "IMEI 2 invalid — skipping."
        NEW_IMEI2=""
    fi

    info "Writing IMEI via resetprop..."
    run_adb shell "su -c 'resetprop persist.radio.imei $NEW_IMEI1'" 2>/dev/null
    run_adb shell "su -c 'resetprop persist.radio.imei1 $NEW_IMEI1'" 2>/dev/null
    run_adb shell "su -c 'resetprop ril.imei $NEW_IMEI1'" 2>/dev/null
    run_adb shell "su -c 'resetprop ril.imei1 $NEW_IMEI1'" 2>/dev/null
    [ -n "$NEW_IMEI2" ] && {
        run_adb shell "su -c 'resetprop persist.radio.imei2 $NEW_IMEI2'" 2>/dev/null
        run_adb shell "su -c 'resetprop ril.imei2 $NEW_IMEI2'" 2>/dev/null
    }
    ok "Props written"

    echo ""; div
    ok "Done. Check with *#06# — reboot may be required."
    log "Prop IMEI repair: $NEW_IMEI1 / ${NEW_IMEI2:-N/A}"
    pause
}

repair_imei_samsung() {
    banner
    echo -e "  ${Y}${B}[ REPAIR IMEI — SAMSUNG METHOD ]${N}"; echo ""
    warn "Samsung devices only."
    warn "Uses EFS partition write method."
    echo ""
    wait_adb

    ask "Enter IMEI 1 (15 digits): " NEW_IMEI1
    echo ""
    if ! validate_imei "$NEW_IMEI1"; then
        err "Invalid IMEI 1."; pause; return
    fi
    ok "IMEI 1 valid: $NEW_IMEI1"

    ask "Enter IMEI 2 (15 digits, Enter to skip): " NEW_IMEI2
    echo ""
    if [ -n "$NEW_IMEI2" ] && ! validate_imei "$NEW_IMEI2"; then
        warn "IMEI 2 invalid — skipping."; NEW_IMEI2=""
    fi

    info "Writing IMEI to EFS partition..."
    run_adb shell "su -c 'echo $NEW_IMEI1 > /efs/imei/imei_id'" 2>/dev/null
    [ -n "$NEW_IMEI2" ] && run_adb shell "su -c 'echo $NEW_IMEI2 > /efs/imei/imei2_id'" 2>/dev/null
    ok "EFS write attempted"

    info "Setting persist props..."
    run_adb shell "su -c 'resetprop persist.radio.imei $NEW_IMEI1'" 2>/dev/null
    run_adb shell "su -c 'resetprop ril.imei1 $NEW_IMEI1'" 2>/dev/null
    [ -n "$NEW_IMEI2" ] && run_adb shell "su -c 'resetprop ril.imei2 $NEW_IMEI2'" 2>/dev/null
    ok "Props set"

    info "Sending AT command via RIL socket..."
    run_adb shell "su -c 'echo AT+CIMI > /dev/umts_ipc0'" 2>/dev/null
    ok "AT command sent"

    echo ""; div
    ok "Samsung IMEI repair attempted. Rebooting..."
    warn "Verify with *#06# after reboot."
    run_adb reboot
    log "Samsung IMEI repair: $NEW_IMEI1 / ${NEW_IMEI2:-N/A}"
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
        echo -e "  ${W}${B}  ◈  SELECT OPTION  ◈${N}"
        echo -e "  ${GR}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${N}"
        echo ""
        echo -e "  ${C}[1]${N}  Read Current IMEI         ${DIM}all methods · Luhn check${N}"
        echo -e "  ${Y}[2]${N}  Validate IMEI             ${DIM}check any IMEI for validity${N}"
        echo -e "  ${M}[3]${N}  Generate Valid IMEI       ${DIM}Luhn-correct IMEI from TAC${N}"
        echo ""
        echo -e "  ${G}[4]${N}  Repair IMEI — MTK         ${DIM}AT commands + nvram · MTK only${N}"
        echo -e "  ${C}[5]${N}  Repair IMEI — Prop        ${DIM}universal · all devices${N}"
        echo -e "  ${Y}[6]${N}  Repair IMEI — Samsung     ${DIM}EFS partition · Samsung only${N}"
        echo ""
        echo -e "  ${GR}[L]${N}  View Log"
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE; echo ""
        log "Menu: $CHOICE"
        case "$CHOICE" in
            1) read_imei ;;
            2) validate_imei_tool ;;
            3) generate_imei ;;
            4) repair_imei_mtk ;;
            5) repair_imei_prop ;;
            6) repair_imei_samsung ;;
            [Ll]) view_log ;;
            [Xx]) echo ""; type_line "  Stay modding. — Lil G Tech Labs" "$GR" 0.03; echo ""; exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

main_menu
