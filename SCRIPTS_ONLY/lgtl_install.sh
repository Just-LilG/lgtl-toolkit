#!/data/data/com.termux/files/usr/bin/bash

TBIN="/data/data/com.termux/files/usr/bin"
export PATH="$TBIN:/data/data/com.termux/files/usr/sbin:$PATH"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'
W='\033[1;37m'; GR='\033[0;37m'; M='\033[0;35m'; B='\033[1m'
DIM='\033[2m'; N='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="3.0"

ok()   { echo -e "  ${G}[✓]${N} $1"; }
err()  { echo -e "  ${R}[✗]${N} $1"; }
info() { echo -e "  ${C}[*]${N} $1"; }
warn() { echo -e "  ${Y}[!]${N} $1"; }
ask()  { printf "${W}  ➤  %s${N}" "$1"; read -r "$2"; }
div()  { echo -e "  ${GR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }

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
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.003
    type_line "        LIL G TECH LABS TOOLKIT v${VERSION}" "$W" 0.015
    type_line "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C" 0.003
    echo ""
}

check_requirements() {
    info "Checking requirements..."
    echo ""

    MISSING=0
    for cmd in su bash adb fastboot; do
        if command -v "$cmd" &>/dev/null || [ -f "$TBIN/$cmd" ]; then
            ok "$cmd"
        else
            warn "$cmd not found"
            MISSING=$((MISSING+1))
        fi
    done

    echo ""
    if [ $MISSING -gt 0 ]; then
        err "Missing $MISSING dependencies. Some tools may not work."
        warn "Install missing tools with: pkg install adb fastboot"
    else
        ok "All requirements met!"
    fi
    echo ""
}

list_tools() {
    banner
    echo -e "  ${W}${B}LGTL TOOLKIT — Available Tools${N}"
    div
    echo ""

    TOOLS=(
        "frp.sh|FRP Bypass Tool|Unlock Google account lock via multiple methods"
        "imei.sh|IMEI Repair Tool|Read, validate, and repair device IMEI"
        "pin_remove.sh|PIN / Pattern Remover|Remove lockscreen without data loss"
        "rom_flash.sh|ROM Flash Utility|Flash complete ROMs or individual partitions"
        "lgtl_bootloader.sh|Bootloader Toolkit|Unlock, lock, flash, and backup bootloader"
        "lgtl_unbrick.sh|Unbrick / Deep Flash|Recover bricked devices via ADB/Fastboot/MTK"
        "lgtl_ai_sense.sh|AI Sense CPU Profiles|Gaming, social, media, efficiency profiles"
        "lgtl_transsion_debloat.sh|Transsion Debloater|Remove bloat from Infinix/Tecno/Itel"
        "Universal-debloat.sh|Universal Debloater|Multi-brand bloat remover (safe + extreme)"
    )

    NUM=1
    for tool_info in "${TOOLS[@]}"; do
        FILE=$(echo "$tool_info" | cut -d'|' -f1)
        NAME=$(echo "$tool_info" | cut -d'|' -f2)
        DESC=$(echo "$tool_info" | cut -d'|' -f3)

        if [ -f "$SCRIPT_DIR/$FILE" ]; then
            echo -e "  ${C}[${NUM}]${N}  ${W}${NAME}${N}"
            echo -e "      ${DIM}${DESC}${N}"
            echo ""
            NUM=$((NUM+1))
        fi
    done

    echo ""
    div
    echo -e "  ${DIM}Directory: ${SCRIPT_DIR}${N}"
    echo -e "  ${DIM}Version: ${VERSION}${N}"
    echo -e "  ${DIM}Channel: t.me/LilGTechLabs${N}"
    echo ""
}

launch_tool() {
    banner
    echo -e "  ${W}${B}Launch Tool${N}"
    div
    echo ""

    TOOLS=(
        "frp.sh" "imei.sh" "pin_remove.sh" "rom_flash.sh"
        "lgtl_bootloader.sh" "lgtl_unbrick.sh" "lgtl_ai_sense.sh"
        "lgtl_transsion_debloat.sh" "Universal-debloat.sh"
    )

    NUM=1
    for tool in "${TOOLS[@]}"; do
        if [ -f "$SCRIPT_DIR/$tool" ]; then
            NAME=$(echo "$tool" | sed 's/.sh$//' | sed 's/_/ /g')
            echo -e "  ${C}[${NUM}]${N}  ${W}${NAME}${N}"
            NUM=$((NUM+1))
        fi
    done

    echo ""
    echo -e "  ${GR}[0]${N}  Back"
    echo -e "  ${GR}[X]${N}  Exit"
    echo ""
    ask "Select tool: " TOOL_NUM
    echo ""

    if [ "$TOOL_NUM" = "0" ] || [ "$TOOL_NUM" = "x" ] || [ "$TOOL_NUM" = "X" ]; then
        return
    fi

    NUM=1
    for tool in "${TOOLS[@]}"; do
        if [ $NUM -eq "$TOOL_NUM" ]; then
            if [ -f "$SCRIPT_DIR/$tool" ]; then
                info "Launching $tool..."
                sleep 1
                bash "$SCRIPT_DIR/$tool"
            else
                err "Tool not found: $tool"
            fi
            return
        fi
        NUM=$((NUM+1))
    done

    warn "Invalid selection."
}

show_permissions() {
    banner
    echo -e "  ${W}${B}Tool Permissions${N}"
    div
    echo ""
    echo -e "  ${C}Root Access Required:${N}"
    echo -e "  • FRP Bypass"
    echo -e "  • IMEI Repair"
    echo -e "  • PIN/Pattern Removal"
    echo -e "  • ROM Flash"
    echo -e "  • Bootloader Unlock/Lock"
    echo -e "  • Deep Flash / Unbrick"
    echo -e "  • CPU Profile Switching"
    echo -e "  • Debloating"
    echo ""
    echo -e "  ${C}USB Debugging Required:${N}"
    echo -e "  • FRP Bypass (ADB method)"
    echo -e "  • IMEI Repair (ADB read)"
    echo -e "  • PIN/Pattern Removal"
    echo -e "  • ROM Flash (sideload)"
    echo ""
    echo -e "  ${C}Bootloader Mode Required:${N}"
    echo -e "  • Bootloader operations"
    echo -e "  • Partition flashing"
    echo -e "  • Deep flash (Fastboot/MTK)"
    echo ""
    ask "Press Enter to continue" _
}

show_about() {
    banner
    echo -e "  ${W}${B}About LGTL Toolkit${N}"
    div
    echo ""
    printf "  ${W}Author${N}: ${G}Lil G${N}\n"
    printf "  ${W}Version${N}: ${G}${VERSION}${N}\n"
    printf "  ${W}Channel${N}: ${C}t.me/LilGTechLabs${N}\n"
    printf "  ${W}Handle${N}: ${C}@Just_LiLGXX${N}\n"
    echo ""
    printf "  ${DIM}Premium Android device technician toolkit for:${N}\n"
    printf "  ${DIM}• FRP / Google Account bypass${N}\n"
    printf "  ${DIM}• IMEI repair and validation${N}\n"
    printf "  ${DIM}• Lockscreen / PIN removal${N}\n"
    printf "  ${DIM}• ROM flashing and management${N}\n"
    printf "  ${DIM}• Bootloader control${N}\n"
    printf "  ${DIM}• Device unbrick and recovery${N}\n"
    printf "  ${DIM}• CPU optimization profiles${N}\n"
    printf "  ${DIM}• Advanced debloating${N}\n"
    echo ""
    div
    echo ""
    ask "Press Enter to continue" _
}

main_menu() {
    while true; do
        banner
        echo -e "  ${W}${B}  ◈  MAIN MENU  ◈${N}"
        div
        echo ""
        echo -e "  ${C}[1]${N}  ${W}View All Tools${N}          ${DIM}browse toolkit${N}"
        echo -e "  ${C}[2]${N}  ${W}Launch Tool${N}             ${DIM}run a tool${N}"
        echo -e "  ${C}[3]${N}  ${W}Check Requirements${N}      ${DIM}verify dependencies${N}"
        echo -e "  ${C}[4]${N}  ${W}Tool Permissions${N}        ${DIM}what each tool needs${N}"
        echo -e "  ${C}[5]${N}  ${W}About LGTL${N}              ${DIM}credits and info${N}"
        echo ""
        echo -e "  ${GR}[X]${N}  Exit"
        echo ""
        div
        ask "Choose: " CHOICE
        echo ""

        case "$CHOICE" in
            1) list_tools; ask "Press Enter to continue" _; clear ;;
            2) launch_tool; clear ;;
            3) check_requirements; ask "Press Enter to continue" _; clear ;;
            4) show_permissions; clear ;;
            5) show_about; clear ;;
            [Xx]) echo ""; type_line "  Stay modding. — Lil G Tech Labs" "$GR" 0.02; echo ""; exit 0 ;;
            *) echo ""; warn "Invalid option."; sleep 1 ;;
        esac
    done
}

main_menu
