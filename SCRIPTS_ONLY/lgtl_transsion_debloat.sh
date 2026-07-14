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
LOG_FILE="$LOG_DIR/lgtl_transsion_$(date +%Y%m%d_%H%M%S).log"

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

banner() {
    clear; echo ""
    printf "  ${C}╔══════════════════════════════════════════════════╗${N}\n"
    printf "  ${C}║${N}  ${W}Transsion Debloater (XOS)${N}  ${DIM}v${VERSION}${N}          ${C}║${N}\n"
    printf "  ${C}║${N}  ${DIM}Infinix • Tecno • Itel${N}                   ${C}║${N}\n"
    printf "  ${C}║${N}  ${DIM}Safe and aggressive removal modes${N}         ${C}║${N}\n"
    printf "  ${C}╠══════════════════════════════════════════════════╣${N}\n"
    printf "  ${C}║${N}  ${DIM}Log: ${GR}%-43s${N}${C}║${N}\n" "$(basename $LOG_FILE)"
    printf "  ${C}╚══════════════════════════════════════════════════╝${N}\n"
    echo ""
}

TRANSSION_BLOAT="
com.transsion.systemui.personalcenter
com.transsion.settingservice
com.transsion.phonemanager
com.transsion.userguide
com.transsion.hilauncher
com.transsion.hicall
com.hispace.hicloud
com.transsion.videoplayer
com.transsion.email
com.transsion.baiduassistant
com.transsion.himoments
com.facebook.katana
com.facebook.system
com.instagram.android
com.whatsapp
com.coloros.weather
com.opera.browser
"

XOS_SYSTEM_BLOAT="
com.coloros.videoeditor
com.coloros.videoplayer
com.coloros.weather2
com.coloros.childrenspace
com.coloros.personalassistant
com.coloros.mine
"

GOOGLE_BLOAT="
com.google.android.apps.maps
com.google.android.apps.docs
com.google.android.apps.sheets
com.google.android.apps.slides
com.google.android.youtube
com.google.android.apps.photos
com.google.android.apps.magazines
"

debloat_safe() {
    banner
    echo -e "  ${G}${B}[ SAFE MODE — Essential Apps Only ]${N}"; echo ""
    warn "Removes third-party bloat only. System apps preserved."
    warn "Safe for device stability."
    echo ""
    printf "  ${R}  ➤  Type DEBLOAT to proceed:${N} "; read -r _SAFE
    [ "$_SAFE" != "DEBLOAT" ] && { warn "Aborted."; pause; return; }

    echo ""; info "Removing third-party bloat..."
    REMOVED=0
    for pkg in $TRANSSION_BLOAT; do
        if pm list packages | grep -q "^package:$pkg"; then
            pm disable-user --user 0 "$pkg" 2>/dev/null
            ok "Disabled: $pkg"; REMOVED=$((REMOVED+1))
        fi
    done

    echo ""; ok "Safe debloat complete. $REMOVED packages disabled."
    log "Safe mode: $REMOVED packages"
    pause
}

debloat_aggressive() {
    banner
    echo -e "  ${R}${B}[ EXTREME MODE — Maximum Cleanup ]${N}"; echo ""
    warn "Removes ALL bloat including system apps."
    warn "May cause system instability. Use with caution."
    echo ""
    printf "  ${R}  ➤  Type AGGRESSIVE to proceed:${N} "; read -r _AGG
    [ "$_AGG" != "AGGRESSIVE" ] && { warn "Aborted."; pause; return; }

    echo ""; info "Removing all bloat..."
    REMOVED=0
    for pkg in $TRANSSION_BLOAT $XOS_SYSTEM_BLOAT $GOOGLE_BLOAT; do
        if pm list packages | grep -q "^package:$pkg"; then
            pm uninstall --user 0 "$pkg" 2>/dev/null || pm disable-user --user 0 "$pkg" 2>/dev/null
            ok "Removed: $pkg"; REMOVED=$((REMOVED+1))
        fi
    done

    echo ""; ok "Aggressive debloat complete. $REMOVED packages removed."
    log "Aggressive mode: $REMOVED packages"
    pause
}

debloat_custom() {
    banner
    echo -e "  ${W}${B}[ CUSTOM MODE ]${N}"; echo ""
    info "Enter package names to remove (one per line)."
    info "Enter 'done' when finished."
    echo ""

    REMOVED=0
    while true; do
        printf "  ${W}Package (or 'done'):${N} "; read -r PKG
        [ "$PKG" = "done" ] && break
        [ -z "$PKG" ] && continue

        if pm list packages | grep -q "^package:$PKG"; then
            pm uninstall --user 0 "$PKG" 2>/dev/null || pm disable-user --user 0 "$PKG" 2>/dev/null
            ok "Removed: $PKG"; REMOVED=$((REMOVED+1))
        else
            warn "Package not found: $PKG"
        fi
    done

    echo ""; ok "Custom removal complete. $REMOVED packages removed."
    log "Custom mode: $REMOVED packages"
    pause
}

restore_bloat() {
    banner
    echo -e "  ${C}${B}[ RESTORE DISABLED PACKAGES ]${N}"; echo ""
    warn "Re-enables all previously disabled packages."
    echo ""
    printf "  ${W}  ➤  Restore all? (y/N):${N} "; read -r _RESTORE
    [ "$_RESTORE" != "y" ] && [ "$_RESTORE" != "Y" ] && { warn "Aborted."; pause; return; }

    echo ""; info "Re-enabling packages..."
    pm list packages --disabled-user | sed 's/package://' | while read -r pkg; do
        pm enable "$pkg" 2>/dev/null
        ok "Enabled: $pkg"
    done

    ok "Restoration complete."
    log "Packages restored"
    pause
}

view_log() {
    banner
    echo -e "  ${W}${B}[ LOG ]${N}"; echo ""
    [ -f "$LOG_FILE" ] && tail -30 "$LOG_FILE" | while IFS= read -r line; do
        echo -e "  ${DIM}$line${N}"
    done
    pause
}

main_menu() {
    while true; do
        banner
        echo -e "  ${W}${B}  ◈  SELECT MODE  ◈${N}"
        div
        echo ""
        echo -e "  ${G}[1]${N}  Safe Mode               ${DIM}third-party bloat only${N}"
        echo -e "  ${R}[2]${N}  ${B}Aggressive Mode${N}         ${DIM}all bloat including system${N}"
        echo -e "  ${W}[3]${N}  Custom Mode             ${DIM}manual package selection${N}"
        echo -e "  ${C}[4]${N}  Restore Packages        ${DIM}re-enable disabled apps${N}"
        echo -e "  ${GR}[L]${N}  View Log"
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE
        echo ""

        case "$CHOICE" in
            1) debloat_safe ;;
            2) debloat_aggressive ;;
            3) debloat_custom ;;
            4) restore_bloat ;;
            [Ll]) view_log ;;
            [Xx]) exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

main_menu
