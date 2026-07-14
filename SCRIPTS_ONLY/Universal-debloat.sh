#!/data/data/com.termux/files/usr/bin/bash

TBIN="/data/data/com.termux/files/usr/bin"
export PATH="$TBIN:/data/data/com.termux/files/usr/sbin:$PATH"

if [ "$(id -u)" != "0" ] && [ -z "$LGTL_ROOT_INHERITED" ]; then
    exec su -c "LGTL_ROOT_INHERITED=1 $TBIN/bash $0"
    exit 1
fi
export LGTL_ROOT_INHERITED=1

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'
W='\033[1;37m'; GR='\033[0;37m'; B='\033[1m'; DIM='\033[2m'; N='\033[0m'

VERSION="2.0"
LOG_DIR="/sdcard/LilGTechLabs/logs"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/lgtl_universal_debloat_$(date +%Y%m%d_%H%M%S).log"

log()  { echo "[$(date '+%H:%M:%S')] $(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"; }
ok()   { echo -e "  ${G}[✓]${N} $1"; log "[OK] $1"; }
err()  { echo -e "  ${R}[✗]${N} $1"; log "[ERR] $1"; }
info() { echo -e "  ${C}[*]${N} $1"; log "[INFO] $1"; }
warn() { echo -e "  ${Y}[!]${N} $1"; log "[WARN] $1"; }
ask()  { printf "${W}  ➤  %s${N}" "$1"; read -r "$2"; }
div()  { echo -e "  ${GR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
pause(){ echo ""; printf "${W}  ➤  Press Enter to continue...${N}"; read -r _D; }

banner() {
    clear; echo ""
    printf "  ${C}╔══════════════════════════════════════════════════╗${N}\n"
    printf "  ${C}║${N}  ${W}Universal Multi-Brand Debloater${N}  ${DIM}v${VERSION}${N}  ${C}║${N}\n"
    printf "  ${C}║${N}  ${DIM}11 Brands • Safe & Aggressive Modes${N}     ${C}║${N}\n"
    printf "  ${C}╠══════════════════════════════════════════════════╣${N}\n"
    printf "  ${C}║${N}  ${DIM}Log: ${GR}%-43s${N}${C}║${N}\n" "$(basename $LOG_FILE)"
    printf "  ${C}╚══════════════════════════════════════════════════╝${N}\n"
    echo ""
}

GOOGLE_BLOAT="
com.google.android.youtube
com.google.android.apps.maps
com.google.android.apps.photos
com.google.android.apps.docs
com.google.android.apps.sheets
com.google.android.apps.slides
com.google.android.apps.magazines
"

SAMSUNG_BLOAT="com.samsung.android.game.gametools com.samsung.android.bixby.service com.samsung.android.app.spage com.samsung.android.app.gamelauncher"
XIAOMI_BLOAT="com.xiaomi.mipicks com.xiaomi.midrive com.xiaomi.cloudservice"
OPPO_BLOAT="com.oppo.cloud com.oppo.cloud.push com.coloros.weather"
MOTOROLA_BLOAT="com.motorola.actions com.motorola.moto"
SONY_BLOAT="com.sonyericsson.textinput com.sonyericsson.xperia.deviceside"
HTCDOTW_BLOAT="com.htc.sense.personalspace"
NOKIA_BLOAT="com.nokia.settings.backup"
REALME_BLOAT="com.realme.powercenter com.realme.logkit"
POCO_BLOAT="com.mi.global.bbs"
VIVO_BLOAT="com.vivo.servicefwmission"
LG_BLOAT="com.lg.app.service com.lg.livesquare"

debloat_all_brands_safe() {
    banner
    echo -e "  ${G}${B}[ SAFE MODE — All 11 Brands ]${N}"; echo ""
    warn "Removes brand-specific bloat. Google apps preserved."
    echo ""
    printf "  ${R}  ➤  Type DEBLOAT to proceed:${N} "; read -r _SAFE
    [ "$_SAFE" != "DEBLOAT" ] && { warn "Aborted."; pause; return; }

    echo ""; info "Scanning and removing bloat from all brands..."
    REMOVED=0
    BRANDS="SAMSUNG XIAOMI OPPO MOTOROLA SONY HTCDOTW NOKIA REALME POCO VIVO LG"

    for BRAND in $BRANDS; do
        eval BLOAT_LIST=\$$BRAND\_BLOAT
        for pkg in $BLOAT_LIST; do
            if pm list packages | grep -q "^package:$pkg"; then
                pm disable-user --user 0 "$pkg" 2>/dev/null && { ok "Disabled: $pkg ($BRAND)"; REMOVED=$((REMOVED+1)); }
            fi
        done
    done

    echo ""; ok "Safe debloat complete. $REMOVED packages disabled."
    log "Safe mode (all brands): $REMOVED"
    pause
}

debloat_all_brands_aggressive() {
    banner
    echo -e "  ${R}${B}[ EXTREME MODE — All 11 Brands + Google ]${N}"; echo ""
    warn "Removes ALL bloat including Google apps."
    warn "Device may become unstable. Use with caution."
    echo ""
    printf "  ${R}  ➤  Type AGGRESSIVE to proceed:${N} "; read -r _AGG
    [ "$_AGG" != "AGGRESSIVE" ] && { warn "Aborted."; pause; return; }

    echo ""; info "Removing all bloat and Google apps..."
    REMOVED=0
    ALL_BLOAT="$GOOGLE_BLOAT $SAMSUNG_BLOAT $XIAOMI_BLOAT $OPPO_BLOAT $MOTOROLA_BLOAT $SONY_BLOAT $HTCDOTW_BLOAT $NOKIA_BLOAT $REALME_BLOAT $POCO_BLOAT $VIVO_BLOAT $LG_BLOAT"

    for pkg in $ALL_BLOAT; do
        if pm list packages | grep -q "^package:$pkg"; then
            pm uninstall --user 0 "$pkg" 2>/dev/null || pm disable-user --user 0 "$pkg" 2>/dev/null
            ok "Removed: $pkg"; REMOVED=$((REMOVED+1))
        fi
    done

    echo ""; ok "Aggressive debloat complete. $REMOVED packages removed."
    log "Aggressive mode (all brands + Google): $REMOVED"
    pause
}

restore_all() {
    banner
    echo -e "  ${C}${B}[ RESTORE ALL PACKAGES ]${N}"; echo ""
    printf "  ${W}  ➤  Re-enable all disabled? (y/N):${N} "; read -r _RESTORE
    [ "$_RESTORE" != "y" ] && [ "$_RESTORE" != "Y" ] && { warn "Aborted."; pause; return; }

    echo ""; info "Re-enabling all packages..."
    pm list packages --disabled-user | sed 's/package://' | while read -r pkg; do
        pm enable "$pkg" 2>/dev/null && echo -e "  ${G}[✓]${N} $pkg"
    done

    ok "Restoration complete."
    log "Restoration: all packages"
    pause
}

view_log() {
    banner
    echo -e "  ${W}${B}[ SESSION LOG ]${N}"; echo ""
    [ -f "$LOG_FILE" ] && tail -40 "$LOG_FILE" | while IFS= read -r line; do
        echo -e "  ${DIM}$line${N}"
    done
    pause
}

main_menu() {
    while true; do
        banner
        echo -e "  ${W}${B}  ◈  BRANDS  ◈${N}"
        div
        echo ""
        echo -e "  ${W}Supported: Samsung, Xiaomi, Oppo, Motorola, Sony, HTC,${N}"
        echo -e "  ${W}Nokia, Realme, Poco, Vivo, LG${N}"
        echo ""
        div
        echo ""
        echo -e "  ${G}[1]${N}  Safe Mode               ${DIM}remove brand bloat only${N}"
        echo -e "  ${R}[2]${N}  ${B}Aggressive Mode${N}         ${DIM}remove everything${N}"
        echo -e "  ${C}[3]${N}  Restore All Packages    ${DIM}re-enable all apps${N}"
        echo -e "  ${GR}[L]${N}  View Log"
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE
        echo ""

        case "$CHOICE" in
            1) debloat_all_brands_safe ;;
            2) debloat_all_brands_aggressive ;;
            3) restore_all ;;
            [Ll]) view_log ;;
            [Xx]) exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

main_menu
