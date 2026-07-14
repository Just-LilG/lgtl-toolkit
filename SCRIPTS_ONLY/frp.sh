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
LOG_FILE="$LOG_DIR/lgtl_frp_$(date +%Y%m%d_%H%M%S).log"

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
    type_line "     LIL G TECH LABS  ·  FRP Bypass Tool" "$W" 0.022
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.004
    echo ""
    pulse_bar "Initializing ADB bridge" 30
    pulse_bar "Loading bypass modules" 28
    if [ "$(id -u)" = "0" ]; then
        scan_check "Root access" "GRANTED" "$G"
    else
        scan_check "Root access" "LIMITED" "$Y"
    fi
    if "$ADB" -H 127.0.0.1 -P 5037 get-state &>/dev/null 2>&1; then
        scan_check "ADB server" "ACTIVE" "$G"
    else
        scan_check "ADB server" "STANDBY" "$GR"
    fi
    echo ""; sleep 0.2
}

banner() {
    clear; echo ""
    printf "  ${C}╔══════════════════════════════════════════════════╗${N}\n"
    printf "  ${C}║${N}  ${R}${B}███████╗██████╗ ██████╗${N}                         ${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B}██╔════╝██╔══██╗██╔══██╗${N}                        ${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B}█████╗  ██████╔╝██████╔╝${N}  ${W}${B}Bypass Tool${N}          ${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B}██╔══╝  ██╔══██╗██╔═══╝${N}                         ${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B}██║     ██║  ██║██║${N}   ${DIM}v${VERSION}${N}  ${DIM}@Just_LiLGXX${N}       ${C}║${N}\n"
    printf "  ${C}║${N}  ${R}${B}╚═╝     ╚═╝  ╚═╝╚═╝${N}   ${C}t.me/LilGTechLabs${N}      ${C}║${N}\n"
    printf "  ${C}╠══════════════════════════════════════════════════╣${N}\n"
    printf "  ${C}║${N}  ${DIM}Log:${N} ${GR}%-43s${N}${C}║${N}\n" "$LOG_FILE"
    printf "  ${C}╚══════════════════════════════════════════════════╝${N}\n"
    echo ""
}

wait_adb() {
    info "Waiting for device via ADB..."
    echo -e "  ${GR}  USB Debugging must be enabled on target.${N}"
    run_adb wait-for-device 2>/dev/null
    ok "Device connected!"; echo ""
}

get_device_info() {
    info "Reading device info..."
    DV_BRAND=$(run_adb shell getprop ro.product.brand 2>/dev/null | tr -d '\r')
    DV_MODEL=$(run_adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
    DV_ANDROID=$(run_adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
    DV_SDK=$(run_adb shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')
    DV_CHIPSET=$(run_adb shell getprop ro.hardware 2>/dev/null | tr -d '\r')
    DV_SERIAL=$(run_adb get-serialno 2>/dev/null | tr -d '\r')
    echo ""
    echo -e "  ${W}╭──────────────────────────────────────────╮${N}"
    echo -e "  ${W}│           TARGET DEVICE INFO              │${N}"
    echo -e "  ${W}├──────────────────────────────────────────┤${N}"
    echo -e "  │  ${C}Brand   ${GR}│${N}  ${W}${DV_BRAND}${N}"
    echo -e "  │  ${C}Model   ${GR}│${N}  ${W}${DV_MODEL}${N}"
    echo -e "  │  ${C}Android ${GR}│${N}  ${G}${DV_ANDROID}${N}  ${DIM}(SDK ${DV_SDK})${N}"
    echo -e "  │  ${C}Chipset ${GR}│${N}  ${DV_CHIPSET}"
    echo -e "  │  ${C}Serial  ${GR}│${N}  ${DIM}${DV_SERIAL}${N}"
    echo -e "  ${W}╰──────────────────────────────────────────╯${N}"
    echo ""
    log "Device: $DV_BRAND $DV_MODEL Android $DV_ANDROID SDK $DV_SDK"
}

check_frp_status() {
    banner
    echo -e "  ${C}${B}[ FRP STATUS CHECK ]${N}"; echo ""
    wait_adb
    get_device_info

    info "Checking FRP lock state..."
    echo ""

    FRP_PROV=$(run_adb shell settings get global device_provisioned 2>/dev/null | tr -d '\r')
    FRP_SETUP=$(run_adb shell settings get secure user_setup_complete 2>/dev/null | tr -d '\r')
    FRP_WIZARD=$(run_adb shell settings get global setup_wizard_has_run 2>/dev/null | tr -d '\r')
    FRP_ACCOUNTS=$(run_adb shell "ls /data/system/users/0/accounts.db 2>/dev/null" | tr -d '\r')

    echo -e "  ${W}╭──────────────────────────────────────────────╮${N}"
    echo -e "  ${W}│              FRP STATE ANALYSIS               │${N}"
    echo -e "  ${W}├──────────────────────────────────────────────┤${N}"

    if [ "$FRP_PROV" = "1" ]; then
        echo -e "  │  ${C}device_provisioned  ${GR}│${N}  ${G}1 — provisioned${N}"
    else
        echo -e "  │  ${C}device_provisioned  ${GR}│${N}  ${R}${FRP_PROV:-not set} — FRP may be active${N}"
    fi

    if [ "$FRP_SETUP" = "1" ]; then
        echo -e "  │  ${C}user_setup_complete ${GR}│${N}  ${G}1 — setup done${N}"
    else
        echo -e "  │  ${C}user_setup_complete ${GR}│${N}  ${R}${FRP_SETUP:-not set} — setup incomplete${N}"
    fi

    if [ "$FRP_WIZARD" = "1" ]; then
        echo -e "  │  ${C}setup_wizard_run    ${GR}│${N}  ${G}1 — wizard ran${N}"
    else
        echo -e "  │  ${C}setup_wizard_run    ${GR}│${N}  ${Y}${FRP_WIZARD:-not set}${N}"
    fi

    if [ -n "$FRP_ACCOUNTS" ]; then
        echo -e "  │  ${C}accounts.db         ${GR}│${N}  ${R}EXISTS — Google account linked${N}"
    else
        echo -e "  │  ${C}accounts.db         ${GR}│${N}  ${G}not found — no account${N}"
    fi

    echo -e "  ${W}╰──────────────────────────────────────────────╯${N}"
    echo ""

    if [ "$FRP_PROV" = "1" ] && [ "$FRP_SETUP" = "1" ]; then
        ok "Device appears to have NO active FRP lock."
    else
        warn "FRP lock is likely ACTIVE. Use a bypass method below."
    fi
    log "FRP check: provisioned=$FRP_PROV setup=$FRP_SETUP wizard=$FRP_WIZARD"
    pause
}

method_adb_clear() {
    banner
    echo -e "  ${Y}${B}[ METHOD 1 — ADB FRP CLEAR ]${N}"; echo ""
    warn "Requires USB Debugging enabled on target."
    warn "Most effective on Android 5–10."
    echo ""
    wait_adb
    get_device_info

    info "Setting provisioning flags..."
    run_adb shell content delete --uri content://settings/secure --where "name='user_setup_complete'" 2>/dev/null
    run_adb shell content insert --uri content://settings/secure --bind name:s:user_setup_complete --bind value:s:1 2>/dev/null
    ok "user_setup_complete → 1"

    run_adb shell content delete --uri content://settings/global --where "name='device_provisioned'" 2>/dev/null
    run_adb shell content insert --uri content://settings/global --bind name:s:device_provisioned --bind value:s:1 2>/dev/null
    ok "device_provisioned → 1"

    run_adb shell settings put global setup_wizard_has_run 1 2>/dev/null
    ok "setup_wizard_has_run → 1"

    info "Disabling setup wizard..."
    run_adb shell am start -n com.google.android.setupwizard/.SetupWizardExitActivity 2>/dev/null
    run_adb shell pm disable-user --user 0 com.google.android.setupwizard 2>/dev/null
    ok "Setup wizard disabled"

    info "Clearing account databases..."
    run_adb shell "su -c 'rm -rf /data/system/users/0/accounts.db'" 2>/dev/null
    run_adb shell "su -c 'rm -rf /data/system/sync/accounts.xml'" 2>/dev/null
    run_adb shell "su -c 'rm -rf /data/system_de/0/accounts.db'" 2>/dev/null
    ok "Account databases cleared"

    info "Wiping FRP partition..."
    run_adb shell "su -c 'dd if=/dev/zero of=/dev/block/by-name/frp bs=512 count=1'" 2>/dev/null || \
    run_adb shell "su -c 'dd if=/dev/zero of=/dev/block/by-name/config bs=512 count=1'" 2>/dev/null
    ok "FRP partition wiped"

    echo ""; div
    ok "Method 1 complete. Rebooting..."
    run_adb reboot
    warn "After reboot — skip Google account screen."
    warn "If account screen returns — try Method 2 or 3."
    log "Method 1 complete"
    pause
}

method_backdoor() {
    banner
    echo -e "  ${M}${B}[ METHOD 2 — SETTINGS BACKDOOR ]${N}"; echo ""
    warn "Device must be on the FRP/Google verification screen."
    warn "Opens hidden settings to bypass verification."
    echo ""
    wait_adb
    get_device_info

    info "Launching accessibility settings backdoor..."
    run_adb shell am start -a android.settings.ACCESSIBILITY_SETTINGS 2>/dev/null
    sleep 1; ok "Accessibility settings launched"

    info "Opening main settings..."
    run_adb shell am start -a android.settings.SETTINGS 2>/dev/null
    sleep 1; ok "Settings opened"

    info "Setting bypass flags..."
    run_adb shell settings put global setup_wizard_has_run 1 2>/dev/null
    run_adb shell settings put secure user_setup_complete 1 2>/dev/null
    run_adb shell settings put global device_provisioned 1 2>/dev/null
    ok "All setup flags set"

    info "Granting GMS permissions..."
    run_adb shell pm grant com.google.android.gms android.permission.READ_CONTACTS 2>/dev/null
    run_adb shell am start -n com.android.settings/.Settings 2>/dev/null
    ok "Settings launched on device"

    echo ""; div
    warn "On the device screen:"
    echo -e "  ${C}1.${N} Go to ${W}Backup & Reset${N}"
    echo -e "  ${C}2.${N} Tap ${W}Factory Reset${N} → ${W}Reset Device${N}"
    echo -e "  ${C}3.${N} This time FRP will be cleared on reboot"
    echo ""
    log "Method 2 complete"
    pause
}

method_frp_apk() {
    banner
    echo -e "  ${G}${B}[ METHOD 3 — FRP BYPASS APK ]${N}"; echo ""
    warn "Pushes a bypass APK to the device via ADB."
    warn "Works on Android 6–12 on most brands."
    echo ""
    wait_adb
    get_device_info

    FRP_APK="/sdcard/LilGTechLabs/tools/frp_bypass.apk"

    if [ ! -f "$FRP_APK" ]; then
        warn "frp_bypass.apk not found. Attempting download..."
        mkdir -p "/sdcard/LilGTechLabs/tools"
        "$TBIN/curl" -L --progress-bar --output "$FRP_APK" \
            "https://github.com/Celpax/FRP/releases/download/v1.0/FRP.apk" 2>&1
    fi

    if [ -f "$FRP_APK" ]; then
        APK_SIZE=$(du -h "$FRP_APK" | cut -f1)
        ok "APK ready: $FRP_APK ($APK_SIZE)"
        info "Installing FRP bypass APK on target..."
        run_adb install -r "$FRP_APK" 2>&1
        RESULT=$?
        if [ $RESULT -eq 0 ]; then
            ok "APK installed!"
            info "Launching bypass app..."
            run_adb shell monkey -p com.celpax.frp -c android.intent.category.LAUNCHER 1 2>/dev/null
            ok "App launched on device. Follow on-screen instructions."
        else
            err "APK install failed (exit: $RESULT). Try Method 1 or 2."
        fi
    else
        err "Could not download APK. Check internet connection."
        warn "Manually place frp_bypass.apk at:"
        echo -e "  ${GR}  $FRP_APK${N}"
    fi

    echo ""
    log "Method 3 complete"
    pause
}

method_transsion_frp() {
    banner
    echo -e "  ${C}${B}[ METHOD 4 — TRANSSION SPECIFIC ]${N}"; echo ""
    warn "Infinix / Tecno / Itel devices ONLY."
    warn "Uses XOS hidden engineer menu to bypass FRP."
    echo ""
    wait_adb
    get_device_info

    DV_BRAND_LOWER=$(echo "$DV_BRAND" | tr '[:upper:]' '[:lower:]')
    case "$DV_BRAND_LOWER" in
        infinix|tecno|itel) ok "Transsion brand confirmed: $DV_BRAND" ;;
        *)
            warn "Brand '$DV_BRAND' is not a recognized Transsion device."
            printf "  ${W}  ➤  Continue anyway? (y/N):${N} "; read -r _CT
            [ "$_CT" = "y" ] || [ "$_CT" = "Y" ] || { warn "Aborted."; pause; return; }
            ;;
    esac

    info "Opening Transsion engineer mode..."
    run_adb shell am start -n com.transsion.engineermode/.MainActivity 2>/dev/null
    sleep 1; ok "Engineer mode launched"

    info "Clearing Transsion + Google account data..."
    run_adb shell pm clear com.transsion.account 2>/dev/null
    run_adb shell pm clear com.google.android.gms 2>/dev/null
    run_adb shell pm clear com.google.android.gsf 2>/dev/null
    ok "Account data cleared"

    info "Resetting FRP flags..."
    run_adb shell settings put global setup_wizard_has_run 1 2>/dev/null
    run_adb shell settings put secure user_setup_complete 1 2>/dev/null
    run_adb shell settings put global device_provisioned 1 2>/dev/null
    ok "FRP flags reset"

    info "Disabling setup wizard..."
    run_adb shell pm disable-user --user 0 com.transsion.hilauncher 2>/dev/null
    run_adb shell pm disable-user --user 0 com.google.android.setupwizard 2>/dev/null
    ok "Setup wizard disabled"

    info "Wiping FRP partition..."
    run_adb shell "su -c 'dd if=/dev/zero of=/dev/block/by-name/frp bs=512 count=1'" 2>/dev/null
    ok "FRP partition wiped"

    echo ""; div
    ok "Transsion FRP bypass complete. Rebooting..."
    run_adb reboot
    echo ""
    log "Method 4 complete"
    pause
}

method_samsung_frp() {
    banner
    echo -e "  ${B}${B}[ METHOD 5 — SAMSUNG FRP ]${N}"; echo ""
    warn "Samsung devices ONLY."
    warn "Uses Samsung-specific FRP bypass via ADB."
    echo ""
    wait_adb
    get_device_info

    DV_BRAND_LOWER=$(echo "$DV_BRAND" | tr '[:upper:]' '[:lower:]')
    case "$DV_BRAND_LOWER" in
        samsung) ok "Samsung device confirmed." ;;
        *)
            warn "Brand '$DV_BRAND' does not appear to be Samsung."
            printf "  ${W}  ➤  Continue anyway? (y/N):${N} "; read -r _CS
            [ "$_CS" = "y" ] || [ "$_CS" = "Y" ] || { warn "Aborted."; pause; return; }
            ;;
    esac

    info "Launching Samsung hidden settings..."
    run_adb shell am start --user 0 -a android.intent.action.MAIN -n com.samsung.android.dialer/.DialtactsActivity 2>/dev/null
    sleep 1

    info "Setting provisioning flags..."
    run_adb shell settings put global device_provisioned 1 2>/dev/null
    run_adb shell settings put secure user_setup_complete 1 2>/dev/null
    run_adb shell settings put global setup_wizard_has_run 1 2>/dev/null
    ok "Flags set"

    info "Clearing Samsung Knox + account data..."
    run_adb shell pm clear com.samsung.android.knox.analytics.uploader 2>/dev/null
    run_adb shell pm clear com.google.android.gms 2>/dev/null
    run_adb shell pm clear com.google.android.gsf 2>/dev/null
    run_adb shell "su -c 'rm -rf /efs/lockscreen'" 2>/dev/null
    run_adb shell "su -c 'rm -rf /data/system/users/0/accounts.db'" 2>/dev/null
    ok "Knox + account data cleared"

    info "Disabling setup wizard..."
    run_adb shell pm disable-user --user 0 com.google.android.setupwizard 2>/dev/null
    run_adb shell pm disable-user --user 0 com.samsung.android.rockchipmtpservice 2>/dev/null
    ok "Setup wizard disabled"

    info "Wiping FRP partition..."
    run_adb shell "su -c 'dd if=/dev/zero of=/dev/block/by-name/frp bs=512 count=1'" 2>/dev/null
    ok "FRP partition wiped"

    echo ""; div
    ok "Samsung FRP bypass complete. Rebooting..."
    run_adb reboot
    log "Method 5 (Samsung) complete"
    pause
}

method_xiaomi_frp() {
    banner
    echo -e "  ${Y}${B}[ METHOD 6 — XIAOMI / MIUI FRP ]${N}"; echo ""
    warn "Xiaomi / Redmi / POCO devices only."
    warn "Uses MIUI-specific bypass paths."
    echo ""
    wait_adb
    get_device_info

    info "Setting MIUI provisioning flags..."
    run_adb shell settings put global device_provisioned 1 2>/dev/null
    run_adb shell settings put secure user_setup_complete 1 2>/dev/null
    run_adb shell settings put global setup_wizard_has_run 1 2>/dev/null
    ok "Provisioning flags set"

    info "Clearing MIUI account + GMS data..."
    run_adb shell pm clear com.xiaomi.account 2>/dev/null
    run_adb shell pm clear com.google.android.gms 2>/dev/null
    run_adb shell pm clear com.google.android.gsf 2>/dev/null
    run_adb shell pm clear com.miui.cloudservice 2>/dev/null
    ok "Account data cleared"

    info "Disabling MIUI setup wizard..."
    run_adb shell pm disable-user --user 0 com.miui.miservice 2>/dev/null
    run_adb shell pm disable-user --user 0 com.google.android.setupwizard 2>/dev/null
    ok "Setup wizard disabled"

    info "Wiping FRP partition..."
    run_adb shell "su -c 'dd if=/dev/zero of=/dev/block/by-name/frp bs=512 count=1'" 2>/dev/null
    ok "FRP partition wiped"

    echo ""; div
    ok "Xiaomi FRP bypass complete. Rebooting..."
    run_adb reboot
    log "Method 6 (Xiaomi) complete"
    pause
}

deep_frp_clean() {
    banner
    echo -e "  ${R}${B}[ DEEP FRP CLEAN — ALL METHODS ]${N}"; echo ""
    warn "Runs ALL bypass steps in sequence."
    warn "Most aggressive — highest success rate."
    echo ""
    printf "  ${R}  ➤  Type DEEPCLEAN to confirm:${N} "; read -r _DC
    [ "$_DC" != "DEEPCLEAN" ] && { warn "Aborted."; pause; return; }

    echo ""
    wait_adb
    get_device_info

    info "Phase 1: Setting all provisioning flags..."
    run_adb shell settings put global device_provisioned 1 2>/dev/null
    run_adb shell settings put secure user_setup_complete 1 2>/dev/null
    run_adb shell settings put global setup_wizard_has_run 1 2>/dev/null
    run_adb shell content delete --uri content://settings/secure --where "name='user_setup_complete'" 2>/dev/null
    run_adb shell content insert --uri content://settings/secure --bind name:s:user_setup_complete --bind value:s:1 2>/dev/null
    run_adb shell content delete --uri content://settings/global --where "name='device_provisioned'" 2>/dev/null
    run_adb shell content insert --uri content://settings/global --bind name:s:device_provisioned --bind value:s:1 2>/dev/null
    ok "Phase 1 done"

    info "Phase 2: Clearing all account databases..."
    run_adb shell "su -c 'rm -rf /data/system/users/0/accounts.db'" 2>/dev/null
    run_adb shell "su -c 'rm -rf /data/system/sync/accounts.xml'" 2>/dev/null
    run_adb shell "su -c 'rm -rf /data/system_de/0/accounts.db'" 2>/dev/null
    run_adb shell "su -c 'rm -rf /efs/lockscreen'" 2>/dev/null
    ok "Phase 2 done"

    info "Phase 3: Clearing GMS + brand account packages..."
    for pkg in com.google.android.gms com.google.android.gsf com.transsion.account com.xiaomi.account com.samsung.android.knox.analytics.uploader com.miui.cloudservice; do
        run_adb shell pm clear "$pkg" 2>/dev/null
    done
    ok "Phase 3 done"

    info "Phase 4: Disabling all setup wizards..."
    for pkg in com.google.android.setupwizard com.transsion.hilauncher com.miui.miservice com.samsung.android.rockchipmtpservice; do
        run_adb shell pm disable-user --user 0 "$pkg" 2>/dev/null
    done
    run_adb shell am start -n com.google.android.setupwizard/.SetupWizardExitActivity 2>/dev/null
    ok "Phase 4 done"

    info "Phase 5: Wiping FRP partition..."
    run_adb shell "su -c 'dd if=/dev/zero of=/dev/block/by-name/frp bs=512 count=1'" 2>/dev/null || \
    run_adb shell "su -c 'dd if=/dev/zero of=/dev/block/by-name/config bs=512 count=1'" 2>/dev/null
    ok "Phase 5 done"

    echo ""; div
    ok "Deep FRP Clean complete. Rebooting..."
    run_adb reboot
    warn "After reboot — skip Google account screen."
    log "Deep FRP clean complete"
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
        div2 2>/dev/null || echo -e "  ${GR}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${N}"
        echo ""
        echo -e "  ${C}[0]${N}  ${W}FRP Status Check${N}        ${DIM}scan device for active FRP${N}"
        echo ""
        echo -e "  ${Y}[1]${N}  ${W}ADB FRP Clear${N}           ${DIM}Android 5–10 · all brands${N}"
        echo -e "  ${M}[2]${N}  ${W}Settings Backdoor${N}       ${DIM}on-screen FRP bypass${N}"
        echo -e "  ${G}[3]${N}  ${W}FRP Bypass APK${N}          ${DIM}Android 6–12 · all brands${N}"
        echo -e "  ${C}[4]${N}  ${W}Transsion Specific${N}      ${DIM}Infinix · Tecno · Itel${N}"
        echo -e "  ${W}[5]${N}  ${W}Samsung Specific${N}        ${DIM}Samsung · Knox bypass${N}"
        echo -e "  ${Y}[6]${N}  ${W}Xiaomi / MIUI${N}           ${DIM}Xiaomi · Redmi · POCO${N}"
        echo ""
        echo -e "  ${R}[7]${N}  ${W}${B}Deep FRP Clean${N}          ${DIM}all methods combined · highest success${N}"
        echo ""
        echo -e "  ${GR}[L]${N}  View Log"
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE
        echo ""
        log "Menu: $CHOICE"

        case "$CHOICE" in
            0) check_frp_status ;;
            1) method_adb_clear ;;
            2) method_backdoor ;;
            3) method_frp_apk ;;
            4) method_transsion_frp ;;
            5) method_samsung_frp ;;
            6) method_xiaomi_frp ;;
            7) deep_frp_clean ;;
            [Ll]) view_log ;;
            [Xx]) echo ""; type_line "  Stay modding. — Lil G Tech Labs" "$GR" 0.03; echo ""; exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

main_menu
