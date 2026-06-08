#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
#   🔥 MR DP BHAI - PHOTO & PDF POWER TOOL v3.0 (FIXED EDITION)
#   Engineer: MR DP BHAI | Telegram: t.me/mrdpbhai
#   Advanced Lock/Unlock | PDF/Photo Security System
#   Termux (Android) के लिए optimize किया गया
# ═══════════════════════════════════════════════════════════════════

set -o pipefail   # pipe में कोई भी fail हो तो catch हो
# set -e नहीं लगाते — ताकि individual errors handle कर सकें

# ──── Colors ────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
BLINK='\033[5m'
DIM='\033[2m'
NC='\033[0m'

# ──── Global Config ────
DEFAULT_FOLDER="/storage/emulated/0/apnapdf"
LOG_FILE=""          # setup_folder के बाद set होगा
FIRST_RUN_FLAG="$HOME/.mrdpbhai_firstrun"
TG_CHANNEL="https://t.me/mrdpbhai"
CONVERT_CMD=""       # check_dependencies में set होगा
QUALITY=150          # Default DPI
PAGE_SIZE="A4"       # Default page size
TEMP_DIR=""          # Cleanup के लिए global temp dir

# ──── Cleanup on Exit / Ctrl+C ────
# Ctrl+C या script exit पर temp files clean करो
cleanup_on_exit() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null
    fi
    # किसी अधूरे temp PDF/file को clean करो
    find "$DEFAULT_FOLDER" -maxdepth 1 -name "tmp_*_$$.pdf" -delete 2>/dev/null
    find "$DEFAULT_FOLDER" -maxdepth 1 -name "tmp_dec_*_$$" -delete 2>/dev/null
}
trap cleanup_on_exit EXIT
trap 'echo -e "\n${YELLOW}⚠️  Ctrl+C — Cleanup कर रहा हूँ...${NC}"; cleanup_on_exit; exit 130' INT TERM

# ──── Utility Functions ────
success() { echo -e "${GREEN}✅ $1${NC}"; }
error()   { echo -e "${RED}❌ ERROR: $1${NC}" >&2; }
info()    { echo -e "${CYAN}ℹ️  $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }
step()    { echo -e "${MAGENTA}▶  $1${NC}"; }
header()  { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}\n"; }

# Log function — LOG_FILE set होने के बाद काम करता है
log() {
    if [ -n "$LOG_FILE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
    fi
}

pause() {
    echo ""
    read -r -p "  ↵ Enter दबाओ जारी रखने के लिए..." _
}

# ──── Secure temp dir बनाओ ────
make_temp_dir() {
    TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t mrdpbhai 2>/dev/null)
    if [ ! -d "$TEMP_DIR" ]; then
        TEMP_DIR="$DEFAULT_FOLDER/.tmp_$$"
        mkdir -p "$TEMP_DIR"
    fi
    echo "$TEMP_DIR"
}

# ──── FIRST RUN → Telegram Redirect ────
first_run_check() {
    if [ ! -f "$FIRST_RUN_FLAG" ]; then
        clear
        echo -e "${YELLOW}"
        echo "  ╔══════════════════════════════════════════════════════╗"
        echo "  ║                                                      ║"
        echo "  ║   🔥  MR DP BHAI TOOL में आपका स्वागत है!  🔥      ║"
        echo "  ║                                                      ║"
        echo "  ║   इस Tool को USE करने से पहले हमारा                 ║"
        echo "  ║   Telegram Channel JOIN करना जरूरी है!              ║"
        echo "  ║                                                      ║"
        echo "  ║   📢  t.me/mrdpbhai                                  ║"
        echo "  ║                                                      ║"
        echo "  ║   ✅ Updates   ✅ New Tools   ✅ Support             ║"
        echo "  ╚══════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo ""
        echo -e "  ${BOLD}Channel Join करने के बाद ही Tool चलेगा!${NC}"
        echo ""
        echo -e "  ${GREEN}Link:${NC} ${BOLD}${BLINK}https://t.me/mrdpbhai${NC}"
        echo ""

        # Termux browser open करो
        if command -v termux-open-url &>/dev/null; then
            echo -e "  ${CYAN}Browser में Channel open कर रहा हूँ...${NC}"
            termux-open-url "$TG_CHANNEL" 2>/dev/null &
        elif command -v am &>/dev/null; then
            am start -a android.intent.action.VIEW -d "$TG_CHANNEL" 2>/dev/null &
        else
            echo -e "  ${YELLOW}Browser में manually open करो: $TG_CHANNEL${NC}"
        fi

        echo ""
        echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        local joined=""
        read -r -p "  Channel Join कर लिया? (y=हाँ / n=नहीं): " joined
        echo ""

        if [[ "$joined" =~ ^[Yy]$ ]]; then
            touch "$FIRST_RUN_FLAG" 2>/dev/null
            success "धन्यवाद! अब Tool शुरू होगा 🎉"
            sleep 1
        else
            echo -e "  ${RED}पहले Channel join करो, फिर Tool use करो!${NC}"
            echo -e "  ${CYAN}$TG_CHANNEL${NC}"
            sleep 2
            exit 0
        fi
    fi
}

# ──── MAIN BANNER ────
show_logo() {
    clear
    echo -e "${RED}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║                                                          ║"
    echo "  ║   ███╗   ███╗██████╗      ██████╗ ██████╗               ║"
    echo "  ║   ████╗ ████║██╔══██╗     ██╔══██╗██╔══██╗              ║"
    echo "  ║   ██╔████╔██║██████╔╝     ██║  ██║██████╔╝              ║"
    echo "  ║   ██║╚██╔╝██║██╔══██╗     ██║  ██║██╔═══╝               ║"
    echo "  ║   ██║ ╚═╝ ██║██║  ██║     ██████╔╝██║                   ║"
    echo "  ║   ╚═╝     ╚═╝╚═╝  ╚═╝     ╚═════╝ ╚═╝                   ║"
    echo -e "  ║${NC}${YELLOW}${BOLD}          B H A I  —  E N G I N E E R             ${RED}${BOLD}    ║"
    echo -e "  ║${NC}${CYAN}        📸 Photo & PDF Power Tool v3.0  🔐         ${RED}${BOLD}   ║"
    echo -e "  ║${NC}${GREEN}             🔗 t.me/mrdpbhai                       ${RED}${BOLD}  ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${DIM}📂 Folder: ${DEFAULT_FOLDER}${NC}"
    echo -e "  ${DIM}🕐 $(date '+%d %b %Y | %I:%M %p')${NC}"
    echo ""
}

# ──── Storage Check ────
check_storage() {
    if [ ! -d "/storage/emulated/0" ]; then
        warn "Storage access नहीं है। Permission माँग रहा हूँ..."
        if command -v termux-setup-storage &>/dev/null; then
            termux-setup-storage
            sleep 4
        fi
        # फिर भी नहीं है तो HOME में folder बनाओ
        if [ ! -d "/storage/emulated/0" ]; then
            warn "Internal storage नहीं मिली। HOME folder use होगा।"
            DEFAULT_FOLDER="$HOME/apnapdf"
        fi
    fi
}

# ──── Folder Setup ────
setup_folder() {
    mkdir -p "$DEFAULT_FOLDER" 2>/dev/null || {
        error "Folder नहीं बना: $DEFAULT_FOLDER"
        DEFAULT_FOLDER="$HOME/apnapdf"
        mkdir -p "$DEFAULT_FOLDER"
    }
    LOG_FILE="$DEFAULT_FOLDER/mrdpbhai_log.txt"
    cd "$DEFAULT_FOLDER" || {
        error "Folder नहीं खुला: $DEFAULT_FOLDER"
        exit 1
    }
}

# ──── Dependencies Check & Install ────
check_dependencies() {
    step "Tools चेक कर रहा हूँ..."
    local missing=()

    # ImageMagick — magick (v7) या convert (v6)
    if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
        missing+=("imagemagick")
    fi
    ! command -v openssl &>/dev/null  && missing+=("openssl")
    ! command -v gs &>/dev/null       && missing+=("ghostscript")
    ! command -v zip &>/dev/null      && missing+=("zip")
    ! command -v unzip &>/dev/null    && missing+=("unzip")
    ! command -v qpdf &>/dev/null     && missing+=("qpdf")   # PDF unlock fallback

    if [ ${#missing[@]} -gt 0 ]; then
        warn "कुछ tools नहीं हैं: ${missing[*]}"
        echo ""
        local ans=""
        read -r -p "  सब install करूँ? (y/n): " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            step "Repositories update कर रहा हूँ..."
            pkg update -y 2>/dev/null || apt-get update -y 2>/dev/null
            echo ""
            for p in "${missing[@]}"; do
                step "$p install कर रहा हूँ..."
                if pkg install "$p" -y 2>/dev/null; then
                    success "$p ✓"
                else
                    warn "$p install नहीं हुआ — skip"
                fi
            done
        else
            warn "कुछ features काम नहीं करेंगे।"
        fi
    else
        success "सभी tools ready!"
    fi

    # CONVERT_CMD set करो — magick (v7) prefer करो
    if command -v magick &>/dev/null; then
        CONVERT_CMD="magick"
    elif command -v convert &>/dev/null; then
        CONVERT_CMD="convert"
    else
        error "ImageMagick नहीं मिला!"
        warn "Install करो: pkg install imagemagick"
    fi

    # ImageMagick policy fix करो (startup पर एक बार)
    fix_imagemagick_policy
}

# ──── ImageMagick PDF Policy Fix ────
# Termux में policy.xml PDF को block कर सकती है
fix_imagemagick_policy() {
    [ -z "$CONVERT_CMD" ] && return  # magick नहीं है तो skip

    local policy_file=""
    # सभी possible locations check करो
    local search_paths=(
        "$PREFIX/etc/ImageMagick-7/policy.xml"
        "$PREFIX/etc/ImageMagick-6/policy.xml"
        "/etc/ImageMagick-7/policy.xml"
        "/etc/ImageMagick-6/policy.xml"
        "$HOME/.config/ImageMagick/policy.xml"
    )
    for p in "${search_paths[@]}"; do
        if [ -f "$p" ]; then
            policy_file="$p"
            break
        fi
    done

    if [ -n "$policy_file" ]; then
        # PDF rights को none से read|write में बदलो
        if grep -q 'rights="none".*pattern="PDF"' "$policy_file" 2>/dev/null; then
            sed -i \
                's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/g' \
                "$policy_file" 2>/dev/null
        fi
        # PS, EPS भी fix करो (कभी-कभी block होते हैं)
        if grep -q 'rights="none".*pattern="PS"' "$policy_file" 2>/dev/null; then
            sed -i \
                's/rights="none" pattern="PS"/rights="read|write" pattern="PS"/g' \
                "$policy_file" 2>/dev/null
        fi
        if grep -q 'rights="none".*pattern="EPS"' "$policy_file" 2>/dev/null; then
            sed -i \
                's/rights="none" pattern="EPS"/rights="read|write" pattern="EPS"/g' \
                "$policy_file" 2>/dev/null
        fi
    fi
}

# ──── File List Helpers ────

# फोटो list दिखाओ (safe glob — nullglob जैसा behavior)
show_photos() {
    echo -e "\n${BOLD}${BLUE}📸 फोटो (${DEFAULT_FOLDER}):${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────${NC}"
    local count=0
    local f sz
    # हर extension अलग check करो ताकि glob fail होने पर error न हो
    while IFS= read -r -d '' f; do
        sz=$(du -h "$f" 2>/dev/null | cut -f1)
        echo -e "  ${GREEN}▸${NC} ${BOLD}$(basename "$f")${NC}  ${DIM}[$sz]${NC}"
        ((count++))
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
            -type f -print0 2>/dev/null | sort -z
    )
    [ "$count" -eq 0 ] && warn "कोई फोटो नहीं मिली!"
    echo -e "${YELLOW}──────────────────────────────────────────${NC}"
    echo -e "  कुल: ${BOLD}$count फोटो${NC}\n"
}

# PDF list दिखाओ
show_pdfs() {
    echo -e "\n${BOLD}${BLUE}📄 PDFs (${DEFAULT_FOLDER}):${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────${NC}"
    local count=0
    local f sz lock_icon
    while IFS= read -r -d '' f; do
        sz=$(du -h "$f" 2>/dev/null | cut -f1)
        # Lock status: /Encrypt keyword check करो
        lock_icon=""
        if grep -q "/Encrypt" "$f" 2>/dev/null; then
            lock_icon=" ${RED}🔒${NC}"
        fi
        echo -e "  ${BLUE}▸${NC} ${BOLD}$(basename "$f")${NC}${lock_icon}  ${DIM}[$sz]${NC}"
        ((count++))
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 -iname "*.pdf" -type f -print0 2>/dev/null | sort -z
    )
    [ "$count" -eq 0 ] && warn "कोई PDF नहीं मिली!"
    echo -e "${YELLOW}──────────────────────────────────────────${NC}"
    echo -e "  कुल: ${BOLD}$count PDFs${NC}\n"
}

# ──── File Name Resolver ────
# User का input लो, extension auto-detect करके full path return करो
resolve_photo() {
    local input="$1"
    # Already exists as-is
    [ -f "$input" ] && echo "$input" && return 0
    # Extensions try करो
    local exts=(".jpg" ".JPG" ".jpeg" ".JPEG" ".png" ".PNG" ".webp" ".WEBP")
    for ext in "${exts[@]}"; do
        if [ -f "${input}${ext}" ]; then
            echo "${input}${ext}"
            return 0
        fi
    done
    # Case-insensitive search (find से)
    local found
    found=$(find "$DEFAULT_FOLDER" -maxdepth 1 \
        \( -iname "${input}" -o -iname "${input}.jpg" \
           -o -iname "${input}.jpeg" -o -iname "${input}.png" \
           -o -iname "${input}.webp" \) \
        -type f 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        echo "$found"
        return 0
    fi
    return 1  # नहीं मिला
}

resolve_pdf() {
    local input="$1"
    [ -f "$input" ] && echo "$input" && return 0
    [ -f "${input}.pdf" ] && echo "${input}.pdf" && return 0
    [ -f "${input}.PDF" ] && echo "${input}.PDF" && return 0
    # Case-insensitive search
    local found
    found=$(find "$DEFAULT_FOLDER" -maxdepth 1 \
        \( -iname "${input}" -o -iname "${input}.pdf" \) \
        -type f 2>/dev/null | head -1)
    [ -n "$found" ] && echo "$found" && return 0
    return 1
}

# ──── Progress Bar ────
progress_bar() {
    local cur=$1 total=$2 width=35
    [ "$total" -eq 0 ] && total=1  # Division by zero से बचो
    local filled=$(( cur * width / total ))
    local empty=$(( width - filled ))
    local pct=$(( cur * 100 / total ))
    printf "\r  ["
    printf "${GREEN}"
    printf "%${filled}s" | tr ' ' '█'
    printf "${NC}"
    printf "%${empty}s" | tr ' ' '░'
    printf "]  ${BOLD}%3d%%${NC}  (%d/%d)" "$pct" "$cur" "$total"
}

# ──── Quality & Page Size ────
choose_quality() {
    echo ""
    echo -e "${BOLD}🎨 PDF Resolution (DPI) चुनो:${NC}"
    echo -e "  ${CYAN}1)${NC} 🔵 Low    (72 DPI)  — WhatsApp/Share (छोटी size)"
    echo -e "  ${CYAN}2)${NC} 🟡 Medium (150 DPI) — Normal use ✅"
    echo -e "  ${CYAN}3)${NC} 🔴 High   (300 DPI) — Print quality"
    echo -e "  ${CYAN}4)${NC} ⚙️  Custom — खुद DPI डालो"
    echo ""
    local q=""
    read -r -p "  चुनो (1-4) [Default: 2]: " q
    case "$q" in
        1) QUALITY=72  ;;
        2) QUALITY=150 ;;
        3) QUALITY=300 ;;
        4)
            local custom_dpi=""
            read -r -p "  DPI डालो (जैसे: 200): " custom_dpi
            if [[ "$custom_dpi" =~ ^[0-9]+$ ]] && [ "$custom_dpi" -gt 0 ]; then
                QUALITY="$custom_dpi"
            else
                warn "Invalid DPI — 150 use होगा।"
                QUALITY=150
            fi
            ;;
        *) QUALITY=150 ;;
    esac
    info "DPI: ${BOLD}${QUALITY}${NC}"
}

choose_pagesize() {
    echo ""
    echo -e "${BOLD}📄 Page Size चुनो:${NC}"
    echo -e "  ${CYAN}1)${NC} A4     (210×297mm) ✅ Default"
    echo -e "  ${CYAN}2)${NC} A3     (297×420mm)"
    echo -e "  ${CYAN}3)${NC} Letter (216×279mm)"
    echo -e "  ${CYAN}4)${NC} Auto   (फोटो की original size)"
    echo ""
    local ps=""
    read -r -p "  चुनो (1-4) [Default: 1]: " ps
    case "$ps" in
        1) PAGE_SIZE="A4"     ;;
        2) PAGE_SIZE="A3"     ;;
        3) PAGE_SIZE="Letter" ;;
        4) PAGE_SIZE=""       ;;
        *) PAGE_SIZE="A4"     ;;
    esac
    if [ -n "$PAGE_SIZE" ]; then
        info "Page Size: ${BOLD}${PAGE_SIZE}${NC}"
    else
        info "Page Size: ${BOLD}Auto (Original)${NC}"
    fi
}

# ════════════════════════════════════════════════════
# ───────── CORE CONVERT FUNCTION ───────────────────
# ════════════════════════════════════════════════════

# do_convert: Photo(s) को PDF में convert करो — QUALITY PRESERVE
#
# KEY PRINCIPLES:
#   - -density BEFORE input file (IM को बताता है image कैसे interpret करें)
#   - -quality 95 = JPEG embed quality (100 = lossless JPEG, but huge)
#   - -compress JPEG = PDF के अंदर JPEG compression use करो
#   - कोई -resize/-resample नहीं = original pixels preserved
#   - -colorspace sRGB = color shift prevent करो
#   - हर image के लिए -density अलग से pass करो (multi-image safe)
#
# Usage: do_convert OUTPUT_PDF DPI PAGESIZE "img1" "img2" ...
# Returns: 0 = success, 1 = failure

do_convert() {
    local output="$1"
    local dpi="$2"
    local pgsize="$3"
    shift 3
    local inputs=("$@")

    [ ${#inputs[@]} -eq 0 ] && { error "do_convert: कोई input file नहीं!"; return 1; }
    [ -z "$CONVERT_CMD" ] && { error "ImageMagick नहीं मिला!"; return 1; }

    # Output directory exist करना चाहिए
    local out_dir
    out_dir=$(dirname "$output")
    mkdir -p "$out_dir" 2>/dev/null

    # Args build करो
    local cmd_args=()
    cmd_args+=(-units "PixelsPerInch")
    cmd_args+=(-density "$dpi")
    [ -n "$pgsize" ] && cmd_args+=(-page "$pgsize")
    cmd_args+=(-compress JPEG)
    cmd_args+=(-quality 95)
    cmd_args+=(-colorspace sRGB)
    # Background white रखो (transparent PNG के लिए)
    cmd_args+=(-background white)
    cmd_args+=(-alpha remove)
    cmd_args+=(-alpha off)

    # Main attempt
    local err_msg
    err_msg=$("$CONVERT_CMD" "${cmd_args[@]}" "${inputs[@]}" "$output" 2>&1)
    local rc=$?

    # Policy error check
    if [ $rc -ne 0 ] || [ ! -s "$output" ]; then
        if echo "$err_msg" | grep -qi "policy\|not authorized\|no decode\|security"; then
            warn "Policy issue detected — Fix करके retry..."
            fix_imagemagick_policy
            sleep 1
            rm -f "$output" 2>/dev/null
            err_msg=$("$CONVERT_CMD" "${cmd_args[@]}" "${inputs[@]}" "$output" 2>&1)
            rc=$?
        fi
    fi

    # Fallback: minimal args
    if [ $rc -ne 0 ] || [ ! -s "$output" ]; then
        warn "Standard method failed — Fallback try कर रहा हूँ..."
        rm -f "$output" 2>/dev/null
        local fb_args=(-density "$dpi" -quality 90 -compress JPEG)
        [ -n "$pgsize" ] && fb_args+=(-page "$pgsize")
        err_msg=$("$CONVERT_CMD" "${fb_args[@]}" "${inputs[@]}" "$output" 2>&1)
        rc=$?
    fi

    # Final check
    if [ $rc -ne 0 ] || [ ! -s "$output" ]; then
        error "Convert failed!"
        error "Message: $err_msg"
        error "Tip: 'pkg reinstall imagemagick' try करो"
        rm -f "$output" 2>/dev/null
        return 1
    fi

    return 0
}

# ════════════════════════════════════════════════════
# ───────── PDF CONVERT FUNCTIONS ───────────────────
# ════════════════════════════════════════════════════

convert_two_photos() {
    header "2 फोटो → PDF"
    show_photos

    local p1_input="" p2_input="" p1="" p2=""

    read -r -p "📸 पहली फोटो का नाम (बिना extension भी चलेगा): " p1_input
    read -r -p "📸 दूसरी फोटो का नाम: " p2_input

    # Spaces trim करो
    p1_input="${p1_input// /}"
    p2_input="${p2_input// /}"

    # Resolve करो
    p1=$(resolve_photo "$p1_input") || {
        error "'$p1_input' नहीं मिली! Folder check करो: $DEFAULT_FOLDER"
        return 1
    }
    p2=$(resolve_photo "$p2_input") || {
        error "'$p2_input' नहीं मिली! Folder check करो: $DEFAULT_FOLDER"
        return 1
    }

    info "फोटो 1: $(basename "$p1")"
    info "फोटो 2: $(basename "$p2")"

    choose_quality
    choose_pagesize

    # Default output name
    local default_name="merged_$(date +%Y%m%d_%H%M%S).pdf"
    echo ""
    read -r -p "💾 PDF नाम [$default_name]: " inp
    # Spaces trim
    inp="${inp// /}"
    local name="${inp:-$default_name}"
    # .pdf extension auto-add
    [[ "${name,,}" == *.pdf ]] || name="${name}.pdf"

    echo ""
    step "PDF बना रहा हूँ: $(basename "$p1") + $(basename "$p2") → $name"

    if do_convert "$name" "$QUALITY" "$PAGE_SIZE" "$p1" "$p2"; then
        local sz
        sz=$(du -h "$name" 2>/dev/null | cut -f1)
        success "PDF बन गई! → $name [$sz]"
        log "2-photo: $(basename "$p1") + $(basename "$p2") → $name"
    else
        error "PDF नहीं बनी!"
        return 1
    fi
}

convert_all_photos() {
    header "सभी फोटो → एक PDF"
    show_photos

    # सभी फोटो collect करो (safe, sorted)
    local files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
            -type f -print0 2>/dev/null | sort -z
    )

    if [ ${#files[@]} -eq 0 ]; then
        error "कोई फोटो नहीं मिली! ($DEFAULT_FOLDER में photos रखो)"
        return 1
    fi
    info "${#files[@]} फोटो मिलीं"

    choose_quality
    choose_pagesize

    local default_name="all_photos_$(date +%Y%m%d_%H%M%S).pdf"
    echo ""
    read -r -p "💾 PDF नाम [$default_name]: " inp
    inp="${inp// /}"
    local name="${inp:-$default_name}"
    [[ "${name,,}" == *.pdf ]] || name="${name}.pdf"

    # Temp dir बनाओ — हर photo को अलग page PDF बनाएंगे, फिर merge करेंगे
    # यह method ज्यादा reliable है — हर image independently process होती है
    local tmp_dir
    tmp_dir=$(make_temp_dir)

    local i=0 failed=0 page_files=()
    echo ""
    step "हर फोटो convert कर रहा हूँ..."

    for f in "${files[@]}"; do
        ((i++))
        progress_bar "$i" "${#files[@]}"

        local pg_tmp="${tmp_dir}/page_$(printf '%04d' $i).pdf"
        if do_convert "$pg_tmp" "$QUALITY" "$PAGE_SIZE" "$f" 2>/dev/null; then
            page_files+=("$pg_tmp")
        else
            ((failed++))
            log "WARN: $(basename "$f") convert नहीं हुई"
        fi
    done
    echo ""

    if [ ${#page_files[@]} -eq 0 ]; then
        error "कोई भी photo convert नहीं हुई!"
        rm -rf "$tmp_dir"
        return 1
    fi

    [ "$failed" -gt 0 ] && warn "$failed फोटो convert नहीं हुईं, बाकी से PDF बना रहा हूँ..."

    step "Pages merge कर रहा हूँ..."

    # Merge strategy:
    # 1) Ghostscript (best quality, preserves structure)
    # 2) ImageMagick fallback
    local merge_ok=0

    if command -v gs &>/dev/null; then
        gs -dNOPAUSE -dBATCH -dQUIET \
           -sDEVICE=pdfwrite \
           -dCompatibilityLevel=1.5 \
           -dPDFSETTINGS=/prepress \
           -sOutputFile="$name" \
           "${page_files[@]}" 2>/dev/null
        [ -s "$name" ] && merge_ok=1
    fi

    if [ "$merge_ok" -eq 0 ]; then
        # ImageMagick से merge करो
        "$CONVERT_CMD" -quality 95 -compress JPEG "${page_files[@]}" "$name" 2>/dev/null
        [ -s "$name" ] && merge_ok=1
    fi

    rm -rf "$tmp_dir"

    if [ "$merge_ok" -eq 1 ]; then
        local sz
        sz=$(du -h "$name" 2>/dev/null | cut -f1)
        success "$((i - failed))/${i} फोटो → $name [$sz]"
        log "All Photos→PDF: $name ($i total, $failed failed)"
    else
        error "PDF नहीं बनी! Pages merge failed।"
        return 1
    fi
}

convert_selected_photos() {
    header "मनचाही फोटो → PDF"
    show_photos
    info "फोटो के नाम space से अलग करो (extension optional)"
    echo ""
    read -r -p "📸 फोटो: " -a sel_input

    if [ ${#sel_input[@]} -eq 0 ]; then
        error "कोई नाम नहीं दिया!"
        return 1
    fi

    # Valid files resolve करो
    local valid=()
    for f in "${sel_input[@]}"; do
        [ -z "$f" ] && continue
        local resolved
        if resolved=$(resolve_photo "$f"); then
            valid+=("$resolved")
        else
            warn "'$f' नहीं मिली — skip"
        fi
    done

    if [ ${#valid[@]} -eq 0 ]; then
        error "कोई valid फोटो नहीं मिली!"
        return 1
    fi
    info "${#valid[@]} फोटो select हुईं:"
    for f in "${valid[@]}"; do
        echo -e "  ${GREEN}▸${NC} $(basename "$f")"
    done

    choose_quality
    choose_pagesize

    local default_name="selected_$(date +%Y%m%d_%H%M%S).pdf"
    echo ""
    read -r -p "💾 PDF नाम [$default_name]: " inp
    inp="${inp// /}"
    local name="${inp:-$default_name}"
    [[ "${name,,}" == *.pdf ]] || name="${name}.pdf"

    echo ""
    step "PDF बना रहा हूँ (${#valid[@]} फोटो)..."

    if do_convert "$name" "$QUALITY" "$PAGE_SIZE" "${valid[@]}"; then
        local sz
        sz=$(du -h "$name" 2>/dev/null | cut -f1)
        success "PDF बनी → $name [$sz]"
        log "Selected Photos→PDF: $name (${#valid[@]} files)"
    else
        error "PDF नहीं बनी!"
        return 1
    fi
}

# ════════════════════════════════════════════════════
# ───────── 🔐 PDF LOCK / UNLOCK SYSTEM ─────────────
# ════════════════════════════════════════════════════

pdf_lock_menu() {
    while true; do
        show_logo
        echo -e "  ${RED}${BOLD}╔══════════════════════════════════════════╗${NC}"
        echo -e "  ${RED}${BOLD}║   🔐  PDF LOCK / UNLOCK SYSTEM           ║${NC}"
        echo -e "  ${RED}${BOLD}╚══════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 🔒 PDF में Password लगाओ (Lock)"
        echo -e "  ${GREEN}2)${NC} 🔓 PDF से Password हटाओ (Unlock)"
        echo -e "  ${GREEN}3)${NC} 🔍 PDF Lock है या नहीं? (Check)"
        echo -e "  ${GREEN}4)${NC} 🛡️  PDF को Read-Only बनाओ"
        echo -e "  ${GREEN}5)${NC} 🔑 PDF का Password बदलो"
        echo ""
        echo -e "  ${RED}0)${NC} ← वापस जाओ"
        echo ""
        read -r -p "  👉 चुनो (0-5): " ch
        case "$ch" in
            1) pdf_add_password     ;;
            2) pdf_remove_password  ;;
            3) pdf_check_lock       ;;
            4) pdf_readonly         ;;
            5) pdf_change_password  ;;
            0) break                ;;
            *) warn "गलत input! 0-5 चुनो।" ;;
        esac
        pause
    done
}

# ──── Ghostscript Check Helper ────
require_gs() {
    if ! command -v gs &>/dev/null; then
        error "Ghostscript नहीं मिला!"
        info "Install करो: pkg install ghostscript"
        # qpdf fallback check
        if command -v qpdf &>/dev/null; then
            info "qpdf मिला है — उसे use करेंगे।"
            return 2  # qpdf available
        fi
        return 1  # nothing available
    fi
    return 0  # gs available
}

pdf_add_password() {
    header "🔒 PDF में Password लगाओ"
    show_pdfs

    local input_pdf_raw="" input_pdf=""
    read -r -p "📄 PDF का नाम: " input_pdf_raw
    input_pdf_raw="${input_pdf_raw// /}"
    input_pdf=$(resolve_pdf "$input_pdf_raw") || {
        error "'$input_pdf_raw' नहीं मिली!"
        return 1
    }
    info "File: $(basename "$input_pdf")"

    echo ""
    echo -e "${BOLD}Password Type चुनो:${NC}"
    echo -e "  ${CYAN}1)${NC} User Password    — खोलने के लिए"
    echo -e "  ${CYAN}2)${NC} Owner Password   — Edit/Print रोकने के लिए"
    echo -e "  ${CYAN}3)${NC} दोनों (Full Protection) ✅ Recommended"
    echo ""
    local ptype=""
    read -r -p "  चुनो (1-3) [Default: 3]: " ptype
    [[ "$ptype" =~ ^[123]$ ]] || ptype="3"

    echo ""
    local pass1="" pass2=""
    read -r -s -p "🔐 Password डालो (min 4 chars): " pass1; echo ""
    read -r -s -p "🔐 Confirm करो: " pass2; echo ""

    if [ "$pass1" != "$pass2" ]; then
        error "Password match नहीं हुआ!"
        return 1
    fi
    if [ ${#pass1} -lt 4 ]; then
        error "Password कम से कम 4 characters का होना चाहिए!"
        return 1
    fi

    echo ""
    echo -e "${BOLD}Encryption Strength:${NC}"
    echo -e "  ${CYAN}1)${NC} 128-bit RC4  (Older compatibility)"
    echo -e "  ${CYAN}2)${NC} 256-bit AES  (Strong) ✅"
    echo ""
    local enc_ch=""
    read -r -p "  चुनो (1-2) [Default: 2]: " enc_ch
    local enc_r=6 enc_bits=256
    [ "$enc_ch" = "1" ] && enc_r=3 && enc_bits=128

    local out_name="locked_$(basename "$input_pdf")"

    require_gs
    local gs_status=$?

    if [ "$gs_status" -eq 0 ]; then
        # Ghostscript से lock करो
        local u_pass_arg="" o_pass_arg=""
        case "$ptype" in
            1) u_pass_arg="-sUserPassword=${pass1}" ;;
            2) o_pass_arg="-sOwnerPassword=${pass1}" ;;
            3) u_pass_arg="-sUserPassword=${pass1}"
               o_pass_arg="-sOwnerPassword=${pass1}" ;;
        esac

        step "Password लगा रहा हूँ (${enc_bits}-bit encryption)..."

        gs -sDEVICE=pdfwrite \
           -dNOPAUSE -dQUIET -dBATCH \
           $u_pass_arg $o_pass_arg \
           -dEncryptionR="$enc_r" \
           -dKeyLength="$enc_bits" \
           -dCompatibilityLevel=1.5 \
           -sOutputFile="$out_name" \
           "$input_pdf" 2>/dev/null

        if [ -f "$out_name" ] && [ -s "$out_name" ]; then
            local sz
            sz=$(du -h "$out_name" 2>/dev/null | cut -f1)
            success "Password लग गया! → $out_name [$sz]"
            echo ""
            echo -e "  ${CYAN}Password: ${BOLD}${pass1}${NC}"
            echo -e "  ${RED}${BOLD}⚠️  Password याद रखो — भूल गए तो unlock नहीं होगा!${NC}"
            log "PDF Locked (${enc_bits}-bit): $(basename "$input_pdf") → $out_name"
        else
            error "Lock नहीं लगा! Ghostscript error।"
            error "Try: gs version check करो — 'gs --version'"
            return 1
        fi

    elif [ "$gs_status" -eq 2 ] && command -v qpdf &>/dev/null; then
        # qpdf fallback
        step "qpdf से password लगा रहा हूँ..."
        local qpdf_args=()
        [ "$ptype" = "1" ] || [ "$ptype" = "3" ] && qpdf_args+=(--user-password="$pass1")
        [ "$ptype" = "2" ] || [ "$ptype" = "3" ] && qpdf_args+=(--owner-password="$pass1")

        qpdf --encrypt "${qpdf_args[@]}" "$enc_bits" -- "$input_pdf" "$out_name" 2>/dev/null
        if [ -f "$out_name" ] && [ -s "$out_name" ]; then
            success "Password लगा (qpdf)! → $out_name"
            log "PDF Locked via qpdf: $(basename "$input_pdf") → $out_name"
        else
            error "qpdf से भी lock नहीं हुआ!"
            return 1
        fi
    else
        error "Ghostscript और qpdf — दोनों नहीं हैं!"
        info "Install करो: pkg install ghostscript qpdf"
        return 1
    fi
}

pdf_remove_password() {
    header "🔓 PDF से Password हटाओ"
    show_pdfs

    local input_pdf_raw="" input_pdf=""
    read -r -p "📄 Locked PDF का नाम: " input_pdf_raw
    input_pdf_raw="${input_pdf_raw// /}"
    input_pdf=$(resolve_pdf "$input_pdf_raw") || {
        error "'$input_pdf_raw' नहीं मिली!"
        return 1
    }

    # Check करो कि locked है?
    if ! grep -q "/Encrypt" "$input_pdf" 2>/dev/null; then
        warn "यह PDF already unlocked है!"
        local cont=""
        read -r -p "  फिर भी continue करें? (y/n): " cont
        [[ "$cont" =~ ^[Yy]$ ]] || return 0
    fi

    echo ""
    local pass=""
    read -r -s -p "🔑 Current Password डालो: " pass; echo ""

    local out_name="unlocked_$(basename "$input_pdf")"

    require_gs
    local gs_status=$?

    if [ "$gs_status" -eq 0 ]; then
        step "Ghostscript से unlock कर रहा हूँ..."

        gs -sDEVICE=pdfwrite \
           -dNOPAUSE -dQUIET -dBATCH \
           -sPDFPassword="$pass" \
           -sOutputFile="$out_name" \
           "$input_pdf" 2>/dev/null

        if [ -f "$out_name" ] && [ -s "$out_name" ]; then
            # Verify: unlock हुआ?
            if grep -q "/Encrypt" "$out_name" 2>/dev/null; then
                # अभी भी encrypted है — password wrong था
                rm -f "$out_name"
                error "Password गलत है! PDF decrypt नहीं हुई।"
                return 1
            fi
            local sz
            sz=$(du -h "$out_name" 2>/dev/null | cut -f1)
            success "Password हट गया! → $out_name [$sz]"
            log "PDF Unlocked: $(basename "$input_pdf") → $out_name"
        else
            rm -f "$out_name"
            error "Unlock नहीं हुआ! Password गलत हो सकता है।"
            echo ""
            warn "Retry करना है? फिर से चलाओ।"
            return 1
        fi

    elif command -v qpdf &>/dev/null; then
        step "qpdf से unlock कर रहा हूँ..."
        qpdf --password="$pass" --decrypt "$input_pdf" "$out_name" 2>/dev/null
        if [ -f "$out_name" ] && [ -s "$out_name" ]; then
            success "Unlock हुआ (qpdf)! → $out_name"
            log "PDF Unlocked via qpdf: $(basename "$input_pdf") → $out_name"
        else
            rm -f "$out_name"
            error "qpdf: Wrong password या corrupted file!"
            return 1
        fi
    else
        error "Ghostscript और qpdf — दोनों नहीं हैं!"
        info "Install: pkg install ghostscript qpdf"
        return 1
    fi
}

pdf_check_lock() {
    header "🔍 PDF Lock Status Check"
    show_pdfs

    local input_raw="" input_pdf=""
    read -r -p "📄 PDF का नाम: " input_raw
    input_raw="${input_raw// /}"
    input_pdf=$(resolve_pdf "$input_raw") || {
        error "'$input_raw' नहीं मिली!"
        return 1
    }

    echo ""
    step "Checking: $(basename "$input_pdf")..."
    echo ""

    # Valid PDF check (magic bytes)
    local magic
    magic=$(head -c 4 "$input_pdf" 2>/dev/null)
    if [[ "$magic" != "%PDF" ]]; then
        error "यह valid PDF नहीं है! (Magic bytes: $magic)"
        return 1
    fi

    local sz
    sz=$(du -h "$input_pdf" 2>/dev/null | cut -f1)
    local mod_date
    mod_date=$(date -r "$input_pdf" '+%d %b %Y %I:%M %p' 2>/dev/null || stat -c '%y' "$input_pdf" 2>/dev/null | cut -d'.' -f1)

    echo -e "  📁 File:     ${BOLD}$(basename "$input_pdf")${NC}"
    echo -e "  📏 Size:     ${BOLD}$sz${NC}"
    echo -e "  📅 Modified: ${BOLD}$mod_date${NC}"
    echo ""

    if grep -q "/Encrypt" "$input_pdf" 2>/dev/null; then
        echo -e "  ${RED}${BOLD}🔒 STATUS: LOCKED (Password Protected)${NC}"
        echo ""

        # Encryption level detect करो
        local key_len=""
        key_len=$(grep -o "KeyLength [0-9]*" "$input_pdf" 2>/dev/null | head -1 | awk '{print $2}')

        if [ -n "$key_len" ]; then
            if [ "$key_len" -ge 256 ]; then
                echo -e "  🛡️  Encryption: ${RED}${BOLD}256-bit AES (Strong)${NC}"
            elif [ "$key_len" -ge 128 ]; then
                echo -e "  🛡️  Encryption: ${YELLOW}${BOLD}128-bit (Standard)${NC}"
            else
                echo -e "  🛡️  Encryption: ${CYAN}${key_len}-bit${NC}"
            fi
        else
            # Binary grep
            if strings "$input_pdf" 2>/dev/null | grep -q "AES"; then
                echo -e "  🛡️  Encryption: ${RED}AES (Strong)${NC}"
            else
                echo -e "  🛡️  Encryption: ${YELLOW}Standard RC4${NC}"
            fi
        fi

        # gs से open test करो
        if command -v gs &>/dev/null; then
            gs -dNOPAUSE -dBATCH -dQUIET -sDEVICE=nullpage "$input_pdf" &>/dev/null
            if [ $? -ne 0 ]; then
                echo -e "  🔑 User Password: ${RED}Required to open${NC}"
            else
                echo -e "  🔑 User Password: ${YELLOW}Not required (Owner-only protected)${NC}"
            fi
        fi
    else
        echo -e "  ${GREEN}${BOLD}🔓 STATUS: UNLOCKED (No Password)${NC}"
        echo ""
        info "यह PDF freely readable है।"
    fi
}

pdf_readonly() {
    header "🛡️ PDF को Read-Only बनाओ"
    info "Print और Edit disable होगा — खोलने के लिए password नहीं"
    echo ""
    show_pdfs

    local input_raw="" input_pdf=""
    read -r -p "📄 PDF का नाम: " input_raw
    input_raw="${input_raw// /}"
    input_pdf=$(resolve_pdf "$input_raw") || {
        error "'$input_raw' नहीं मिली!"
        return 1
    }

    # Random owner password (user को जानने की जरूरत नहीं)
    local owner_pass
    owner_pass="MRDP_RO_$(date +%s)_$(head -c 8 /dev/urandom | base64 | tr -d '+/=')"
    local out_name="readonly_$(basename "$input_pdf")"

    require_gs
    local gs_status=$?

    if [ "$gs_status" -eq 0 ]; then
        step "Read-Only PDF बना रहा हूँ..."
        # dPermissions: -3904 = print/copy/edit सब disable
        gs -sDEVICE=pdfwrite \
           -dNOPAUSE -dQUIET -dBATCH \
           -sOwnerPassword="$owner_pass" \
           -dEncryptionR=3 \
           -dKeyLength=128 \
           -dPermissions=-3904 \
           -sOutputFile="$out_name" \
           "$input_pdf" 2>/dev/null

        if [ -f "$out_name" ] && [ -s "$out_name" ]; then
            success "Read-Only PDF → $out_name"
            log "PDF ReadOnly: $(basename "$input_pdf") → $out_name"
        else
            error "Read-Only बनाना failed!"
            return 1
        fi

    elif command -v qpdf &>/dev/null; then
        step "qpdf से Read-Only बना रहा हूँ..."
        qpdf --encrypt "" "$owner_pass" 128 \
             --print=none --modify=none --extract=n \
             -- "$input_pdf" "$out_name" 2>/dev/null
        [ -f "$out_name" ] && [ -s "$out_name" ] \
            && success "Read-Only (qpdf) → $out_name" \
            || { error "Failed!"; return 1; }
    else
        error "Ghostscript या qpdf चाहिए!"
        info "Install: pkg install ghostscript"
        return 1
    fi
}

pdf_change_password() {
    header "🔑 PDF Password बदलो"
    show_pdfs

    local input_raw="" input_pdf=""
    read -r -p "📄 PDF का नाम: " input_raw
    input_raw="${input_raw// /}"
    input_pdf=$(resolve_pdf "$input_raw") || {
        error "File नहीं मिली!"
        return 1
    }

    echo ""
    local old_pass="" new_pass="" new_pass2=""
    read -r -s -p "🔑 पुराना Password: " old_pass; echo ""
    read -r -s -p "🔐 नया Password (min 4 chars): " new_pass; echo ""
    read -r -s -p "🔐 नया Password Confirm: " new_pass2; echo ""

    if [ "$new_pass" != "$new_pass2" ]; then
        error "नया Password match नहीं हुआ!"
        return 1
    fi
    if [ ${#new_pass} -lt 4 ]; then
        error "Password कम से कम 4 characters का होना चाहिए!"
        return 1
    fi

    local tmp_dec="${DEFAULT_FOLDER}/tmp_dec_$$_$(date +%s).pdf"
    local out_name="newpass_$(basename "$input_pdf")"

    require_gs
    local gs_status=$?

    if [ "$gs_status" -eq 0 ]; then
        # Step 1: Old password से decrypt करो
        step "पुराना password verify कर रहा हूँ..."
        gs -sDEVICE=pdfwrite \
           -dNOPAUSE -dQUIET -dBATCH \
           -sPDFPassword="$old_pass" \
           -sOutputFile="$tmp_dec" \
           "$input_pdf" 2>/dev/null

        if [ ! -f "$tmp_dec" ] || [ ! -s "$tmp_dec" ]; then
            rm -f "$tmp_dec"
            error "पुराना Password गलत है!"
            return 1
        fi

        # Step 2: नया password लगाओ
        step "नया password लगा रहा हूँ..."
        gs -sDEVICE=pdfwrite \
           -dNOPAUSE -dQUIET -dBATCH \
           -sUserPassword="$new_pass" \
           -sOwnerPassword="$new_pass" \
           -dEncryptionR=3 \
           -dKeyLength=128 \
           -sOutputFile="$out_name" \
           "$tmp_dec" 2>/dev/null

        rm -f "$tmp_dec"  # Temp file clean करो

        if [ -f "$out_name" ] && [ -s "$out_name" ]; then
            success "Password बदल गया! → $out_name"
            echo -e "  ${CYAN}नया Password: ${BOLD}$new_pass${NC}"
            log "PDF Password Changed: $(basename "$input_pdf") → $out_name"
        else
            error "नया Password लगाना failed!"
            return 1
        fi

    elif command -v qpdf &>/dev/null; then
        step "qpdf से password बदल रहा हूँ..."
        # qpdf: decrypt → re-encrypt
        qpdf --password="$old_pass" --decrypt "$input_pdf" "$tmp_dec" 2>/dev/null && \
        qpdf --encrypt "$new_pass" "$new_pass" 128 -- "$tmp_dec" "$out_name" 2>/dev/null
        rm -f "$tmp_dec"
        [ -f "$out_name" ] && [ -s "$out_name" ] \
            && success "Password बदला (qpdf)! → $out_name" \
            || { error "Failed! पुराना password गलत हो सकता है।"; return 1; }
    else
        error "Ghostscript/qpdf जरूरी है!"
        return 1
    fi
}

# ════════════════════════════════════════════════════
# ───────── 🖼️ PHOTO LOCK / UNLOCK SYSTEM ───────────
# ════════════════════════════════════════════════════

photo_lock_menu() {
    while true; do
        show_logo
        echo -e "  ${MAGENTA}${BOLD}╔══════════════════════════════════════════╗${NC}"
        echo -e "  ${MAGENTA}${BOLD}║   🖼️   PHOTO LOCK / UNLOCK SYSTEM        ║${NC}"
        echo -e "  ${MAGENTA}${BOLD}╚══════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 🔒 फोटो Encrypt करो (Lock)"
        echo -e "  ${GREEN}2)${NC} 🔓 फोटो Decrypt करो (Unlock)"
        echo -e "  ${GREEN}3)${NC} 🗂️  फोटो को ZIP में Lock करो"
        echo -e "  ${GREEN}4)${NC} 📦 ZIP से Unlock करो"
        echo -e "  ${GREEN}5)${NC} 🔍 File Encrypt है या नहीं? (Check)"
        echo -e "  ${GREEN}6)${NC} 🖼️  सभी फोटो Batch Encrypt (Lock)"
        echo -e "  ${GREEN}7)${NC} 🔓 सभी .enc Batch Decrypt (Unlock)"
        echo ""
        echo -e "  ${RED}0)${NC} ← वापस जाओ"
        echo ""
        read -r -p "  👉 चुनो (0-7): " ch
        case "$ch" in
            1) photo_encrypt       ;;
            2) photo_decrypt       ;;
            3) photo_zip_lock      ;;
            4) photo_zip_unlock    ;;
            5) photo_check_encrypt ;;
            6) photo_batch_lock    ;;
            7) photo_batch_unlock  ;;
            0) break               ;;
            *) warn "गलत input! 0-7 चुनो।" ;;
        esac
        pause
    done
}

# OpenSSL check helper
require_openssl() {
    if ! command -v openssl &>/dev/null; then
        error "OpenSSL नहीं है!"
        info "Install करो: pkg install openssl"
        return 1
    fi
    return 0
}

photo_encrypt() {
    header "🔒 फोटो Encrypt करो"
    show_photos

    echo -e "${BOLD}Encryption Method चुनो:${NC}"
    echo -e "  ${CYAN}1)${NC} AES-256-CBC (सबसे Strong) ✅"
    echo -e "  ${CYAN}2)${NC} AES-128-CBC (थोड़ी Fast)"
    echo -e "  ${CYAN}3)${NC} Password ZIP (Simple — zip compatible)"
    echo ""
    local method=""
    read -r -p "  चुनो (1-3) [Default: 1]: " method
    [[ "$method" =~ ^[123]$ ]] || method="1"

    echo ""
    local photo_input="" photo=""
    read -r -p "📸 फोटो का नाम: " photo_input
    photo_input="${photo_input// /}"
    photo=$(resolve_photo "$photo_input") || {
        error "'$photo_input' नहीं मिली!"
        return 1
    }
    info "File: $(basename "$photo") [$(du -h "$photo"|cut -f1)]"

    echo ""
    local pass="" pass2=""
    read -r -s -p "🔐 Password डालो (min 4 chars): " pass; echo ""
    read -r -s -p "🔐 Confirm करो: " pass2; echo ""

    if [ "$pass" != "$pass2" ]; then
        error "Password match नहीं हुआ!"
        return 1
    fi
    if [ ${#pass} -lt 4 ]; then
        error "Password कम से कम 4 characters होने चाहिए!"
        return 1
    fi

    local base_name
    base_name=$(basename "$photo")
    local out_enc=""
    local enc_ok=0

    require_openssl || return 1

    step "Encrypt कर रहा हूँ..."

    case "$method" in
        1)
            out_enc="${base_name}.enc"
            openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
                -in "$photo" -out "$out_enc" \
                -pass "pass:${pass}" 2>/dev/null
            [ -f "$out_enc" ] && [ -s "$out_enc" ] && enc_ok=1
            ;;
        2)
            out_enc="${base_name}.enc"
            openssl enc -aes-128-cbc -salt -pbkdf2 -iter 50000 \
                -in "$photo" -out "$out_enc" \
                -pass "pass:${pass}" 2>/dev/null
            [ -f "$out_enc" ] && [ -s "$out_enc" ] && enc_ok=1
            ;;
        3)
            out_enc="${base_name}.zip"
            # ZIP method — zip command
            if command -v zip &>/dev/null; then
                zip -P "$pass" "$out_enc" "$photo" 2>/dev/null
                [ -f "$out_enc" ] && [ -s "$out_enc" ] && enc_ok=1
            else
                error "zip नहीं है: pkg install zip"
                return 1
            fi
            ;;
    esac

    if [ "$enc_ok" -eq 1 ]; then
        local sz
        sz=$(du -h "$out_enc" 2>/dev/null | cut -f1)
        success "Encrypt हो गई! → $out_enc [$sz]"
        echo ""

        local del=""
        read -r -p "  Original फोटो delete करूँ? (y/n): " del
        if [[ "$del" =~ ^[Yy]$ ]]; then
            rm -f "$photo" && warn "Original delete हुई: $base_name"
        fi
        log "Photo Encrypted (method $method): $base_name → $out_enc"
    else
        rm -f "$out_enc" 2>/dev/null
        error "Encrypt नहीं हुई! OpenSSL error check करो।"
        return 1
    fi
}

photo_decrypt() {
    header "🔓 फोटो Decrypt करो"
    echo ""
    echo -e "${BOLD}Encrypted फाइलें (.enc / .zip):${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────${NC}"
    local found_enc=0
    while IFS= read -r -d '' f; do
        echo -e "  ${MAGENTA}▸${NC} $(basename "$f")  ${DIM}[$(du -h "$f"|cut -f1)]${NC}"
        ((found_enc++))
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 \
            \( -name "*.enc" -o -name "*.zip" \) \
            -type f -print0 2>/dev/null | sort -z
    )
    [ "$found_enc" -eq 0 ] && warn "कोई .enc या .zip file नहीं मिली!"
    echo -e "${YELLOW}──────────────────────────────────────────${NC}"
    echo ""

    local enc_input="" enc_file=""
    read -r -p "🔒 Encrypted File का नाम: " enc_input
    enc_input="${enc_input// /}"
    [ -f "$enc_input" ] && enc_file="$enc_input"
    if [ -z "$enc_file" ]; then
        # Try with full path
        [ -f "$DEFAULT_FOLDER/$enc_input" ] && enc_file="$DEFAULT_FOLDER/$enc_input"
    fi
    if [ -z "$enc_file" ] || [ ! -f "$enc_file" ]; then
        error "'$enc_input' नहीं मिली!"
        return 1
    fi

    local pass=""
    read -r -s -p "🔑 Password डालो: " pass; echo ""

    local ext="${enc_file##*.}"
    local base_name
    base_name=$(basename "$enc_file")

    step "Decrypt कर रहा हूँ..."

    # ZIP case
    if [ "$ext" = "zip" ]; then
        if ! command -v unzip &>/dev/null; then
            error "unzip नहीं है: pkg install unzip"
            return 1
        fi
        local test_out
        test_out=$(unzip -P "$pass" -l "$enc_file" 2>&1)
        if echo "$test_out" | grep -q "incorrect password\|bad password\|wrong password" 2>/dev/null; then
            error "Wrong password!"
            return 1
        fi
        unzip -P "$pass" "$enc_file" 2>/dev/null
        local rc=$?
        if [ $rc -eq 0 ]; then
            success "ZIP Unzipped!"
            log "Photo Decrypted (zip): $base_name"
        else
            error "Wrong password या corrupted ZIP!"
            return 1
        fi
        return 0
    fi

    require_openssl || return 1

    # .enc case — cipher auto-detect करो
    local orig_name="${enc_file%.enc}"
    local out_name="decrypted_$(basename "$orig_name")"

    # Method 1: AES-256 + pbkdf2 + iter 100000
    openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
        -in "$enc_file" -out "$out_name" \
        -pass "pass:${pass}" 2>/dev/null

    if [ -f "$out_name" ] && [ -s "$out_name" ]; then
        success "Decrypt हो गई! → $out_name (AES-256)"
        log "Photo Decrypted (AES-256): $base_name → $out_name"
        return 0
    fi
    rm -f "$out_name" 2>/dev/null

    # Method 2: AES-128 + pbkdf2 + iter 50000
    openssl enc -d -aes-128-cbc -pbkdf2 -iter 50000 \
        -in "$enc_file" -out "$out_name" \
        -pass "pass:${pass}" 2>/dev/null

    if [ -f "$out_name" ] && [ -s "$out_name" ]; then
        success "Decrypt हो गई! → $out_name (AES-128)"
        log "Photo Decrypted (AES-128): $base_name → $out_name"
        return 0
    fi
    rm -f "$out_name" 2>/dev/null

    # Method 3: Legacy (पुराना openssl — without pbkdf2)
    openssl enc -d -aes-256-cbc -salt \
        -in "$enc_file" -out "$out_name" \
        -pass "pass:${pass}" 2>/dev/null

    if [ -f "$out_name" ] && [ -s "$out_name" ]; then
        success "Decrypt हो गई! → $out_name (Legacy AES)"
        log "Photo Decrypted (Legacy): $base_name → $out_name"
        return 0
    fi
    rm -f "$out_name" 2>/dev/null

    error "Decrypt नहीं हुई! Password गलत है या file corrupt है।"
    return 1
}

photo_zip_lock() {
    header "🗂️ फोटो को Password ZIP में Lock करो"
    show_photos

    if ! command -v zip &>/dev/null; then
        error "zip नहीं है: pkg install zip"
        return 1
    fi

    echo -e "${BOLD}क्या lock करना है?${NC}"
    echo -e "  ${CYAN}1)${NC} एक फोटो"
    echo -e "  ${CYAN}2)${NC} मनचाही फोटो (space से अलग)"
    echo -e "  ${CYAN}3)${NC} सभी फोटो"
    echo ""
    local zch=""
    read -r -p "  चुनो (1-3): " zch

    local zpass="" zpass2=""
    read -r -s -p "🔐 ZIP Password (min 4 chars): " zpass; echo ""
    read -r -s -p "🔐 Confirm: " zpass2; echo ""
    if [ "$zpass" != "$zpass2" ]; then
        error "Password match नहीं!"
        return 1
    fi
    if [ ${#zpass} -lt 4 ]; then
        error "Password बहुत छोटा है!"
        return 1
    fi

    local default_zip="photos_locked_$(date +%Y%m%d_%H%M%S).zip"
    echo ""
    read -r -p "💾 ZIP नाम [$default_zip]: " zn
    zn="${zn// /}"
    local zipname="${zn:-$default_zip}"
    [[ "${zipname,,}" == *.zip ]] || zipname="${zipname}.zip"

    local zip_targets=()

    case "$zch" in
        1)
            local zp_input="" zp=""
            read -r -p "फोटो का नाम: " zp_input
            zp_input="${zp_input// /}"
            zp=$(resolve_photo "$zp_input") || {
                error "फोटो नहीं मिली!"
                return 1
            }
            zip_targets+=("$zp")
            ;;
        2)
            local zarr_input=()
            read -r -p "फोटो के नाम (space-separated): " -a zarr_input
            for f in "${zarr_input[@]}"; do
                [ -z "$f" ] && continue
                local zresolved
                if zresolved=$(resolve_photo "$f"); then
                    zip_targets+=("$zresolved")
                else
                    warn "'$f' नहीं मिली — skip"
                fi
            done
            ;;
        3)
            while IFS= read -r -d '' f; do
                zip_targets+=("$f")
            done < <(
                find "$DEFAULT_FOLDER" -maxdepth 1 \
                    \( -iname "*.jpg" -o -iname "*.jpeg" \
                       -o -iname "*.png" -o -iname "*.webp" \) \
                    -type f -print0 2>/dev/null | sort -z
            )
            ;;
        *)
            warn "गलत input!"
            return 1
            ;;
    esac

    if [ ${#zip_targets[@]} -eq 0 ]; then
        error "कोई फोटो नहीं मिली!"
        return 1
    fi

    step "${#zip_targets[@]} फोटो ZIP में डाल रहा हूँ..."
    zip -P "$zpass" -j "$zipname" "${zip_targets[@]}" 2>/dev/null
    local zip_rc=$?

    if [ $zip_rc -eq 0 ] && [ -f "$zipname" ] && [ -s "$zipname" ]; then
        local sz
        sz=$(du -h "$zipname" 2>/dev/null | cut -f1)
        success "Locked ZIP → $zipname [$sz]"
        log "Photo ZIP Lock: $zipname (${#zip_targets[@]} files)"
    else
        rm -f "$zipname" 2>/dev/null
        error "ZIP नहीं बनी! (zip exit code: $zip_rc)"
        return 1
    fi
}

photo_zip_unlock() {
    header "📦 ZIP से फोटो Unlock करो"
    echo ""

    if ! command -v unzip &>/dev/null; then
        error "unzip नहीं है: pkg install unzip"
        return 1
    fi

    echo -e "${BOLD}ZIP फाइलें:${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────${NC}"
    local found_zip=0
    while IFS= read -r -d '' f; do
        echo -e "  ${YELLOW}▸${NC} $(basename "$f")  ${DIM}[$(du -h "$f"|cut -f1)]${NC}"
        ((found_zip++))
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 -name "*.zip" -type f -print0 2>/dev/null | sort -z
    )
    [ "$found_zip" -eq 0 ] && warn "कोई ZIP नहीं मिली!"
    echo -e "${YELLOW}──────────────────────────────────────────${NC}"
    echo ""

    local zf_input=""
    read -r -p "📦 ZIP का नाम: " zf_input
    zf_input="${zf_input// /}"
    local zfile=""
    [ -f "$zf_input" ] && zfile="$zf_input"
    [ -z "$zfile" ] && [ -f "$DEFAULT_FOLDER/$zf_input" ] && zfile="$DEFAULT_FOLDER/$zf_input"
    if [ -z "$zfile" ] || [ ! -f "$zfile" ]; then
        error "'$zf_input' नहीं मिली!"
        return 1
    fi

    local zpass=""
    read -r -s -p "🔑 Password: " zpass; echo ""

    local base_name
    base_name=$(basename "$zfile" .zip)
    local outdir="${DEFAULT_FOLDER}/${base_name}_extracted"
    mkdir -p "$outdir"

    step "Extract कर रहा हूँ → $outdir/"
    unzip -P "$zpass" "$zfile" -d "$outdir" 2>/dev/null
    local unzip_rc=$?

    if [ $unzip_rc -eq 0 ]; then
        local count
        count=$(find "$outdir" -type f | wc -l)
        success "$count फाइलें निकलीं → $(basename "$outdir")/"
        log "ZIP Unlocked: $(basename "$zfile") → $outdir ($count files)"
    else
        rmdir "$outdir" 2>/dev/null
        case $unzip_rc in
            1)  error "Warning हुई लेकिन कुछ files निकली हों।" ;;
            2)  error "ZIP format error — Corrupted file!" ;;
            82) error "Wrong password!" ;;
            *)  error "Unzip failed! (exit code: $unzip_rc) — Wrong password हो सकता है।" ;;
        esac
        return 1
    fi
}

photo_check_encrypt() {
    header "🔍 File Encryption Status Check"
    echo ""
    local chk_input=""
    read -r -p "फाइल का नाम: " chk_input
    chk_input="${chk_input// /}"

    local chk_file=""
    [ -f "$chk_input" ] && chk_file="$chk_input"
    [ -z "$chk_file" ] && [ -f "$DEFAULT_FOLDER/$chk_input" ] && chk_file="$DEFAULT_FOLDER/$chk_input"
    if [ -z "$chk_file" ] || [ ! -f "$chk_file" ]; then
        error "'$chk_input' नहीं मिली!"
        return 1
    fi

    local ext="${chk_file##*.}"
    ext="${ext,,}"  # lowercase
    local sz
    sz=$(du -h "$chk_file" 2>/dev/null | cut -f1)

    echo ""
    echo -e "  📁 File:  ${BOLD}$(basename "$chk_file")${NC}"
    echo -e "  📏 Size:  ${BOLD}$sz${NC}"
    echo -e "  🗂️  Type:  ${BOLD}.${ext}${NC}"
    echo ""

    case "$ext" in
        enc)
            # OpenSSL magic bytes check
            local magic_hex
            magic_hex=$(head -c 8 "$chk_file" 2>/dev/null | xxd -p 2>/dev/null | head -1)
            echo -e "  ${RED}${BOLD}🔒 STATUS: ENCRYPTED (.enc)${NC}"
            if [[ "$magic_hex" == "53616c746564"* ]]; then
                echo -e "  🛡️  Method: ${BOLD}OpenSSL AES (Salted)${NC}"
            else
                echo -e "  🛡️  Method: ${BOLD}OpenSSL Encrypted${NC}"
            fi
            ;;
        zip)
            # ZIP password check
            if ! command -v unzip &>/dev/null; then
                echo -e "  ${YELLOW}STATUS: ZIP (unzip नहीं है — check नहीं हो सकता)${NC}"
            else
                # Encrypted ZIP files में "P" flag होता है
                local zip_info
                zip_info=$(unzip -v "$chk_file" 2>/dev/null | head -20)
                if echo "$zip_info" | grep -q "^  [0-9].*Defl\|^  [0-9].*Stor"; then
                    # Check encryption flag
                    if unzip -l "$chk_file" 2>&1 | grep -q "skipping\|incorrect\|password"; then
                        echo -e "  ${RED}${BOLD}🔒 STATUS: PASSWORD PROTECTED ZIP${NC}"
                    else
                        echo -e "  ${GREEN}${BOLD}🔓 STATUS: Normal ZIP (No password)${NC}"
                    fi
                else
                    echo -e "  ${YELLOW}STATUS: ZIP file (encryption unknown)${NC}"
                fi
            fi
            ;;
        jpg|jpeg|png|webp)
            echo -e "  ${GREEN}${BOLD}🔓 STATUS: Normal Photo (Not Encrypted)${NC}"
            # Image info दिखाओ
            if [ -n "$CONVERT_CMD" ]; then
                local img_info
                img_info=$("$CONVERT_CMD" identify -verbose "$chk_file" 2>/dev/null | grep -E "Geometry|Resolution|Depth|Type")
                [ -n "$img_info" ] && echo "" && echo "$img_info" | while IFS= read -r line; do
                    echo -e "  ${DIM}$line${NC}"
                done
            fi
            ;;
        pdf)
            if grep -q "/Encrypt" "$chk_file" 2>/dev/null; then
                echo -e "  ${RED}${BOLD}🔒 STATUS: PDF LOCKED (Password Protected)${NC}"
            else
                echo -e "  ${GREEN}${BOLD}🔓 STATUS: PDF OPEN (No Password)${NC}"
            fi
            ;;
        *)
            # Unknown — magic bytes से detect करो
            local magic
            magic=$(head -c 4 "$chk_file" 2>/dev/null)
            echo -e "  ${CYAN}STATUS: Unknown file type (.${ext})${NC}"
            echo -e "  ${DIM}Magic: $(echo "$magic" | xxd 2>/dev/null | head -1)${NC}"
            ;;
    esac
}

photo_batch_lock() {
    header "🖼️ सभी फोटो Batch Encrypt करो"
    show_photos

    local all_photos=()
    while IFS= read -r -d '' f; do
        all_photos+=("$f")
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 \
            \( -iname "*.jpg" -o -iname "*.jpeg" \
               -o -iname "*.png" -o -iname "*.webp" \) \
            -type f -print0 2>/dev/null | sort -z
    )

    if [ ${#all_photos[@]} -eq 0 ]; then
        error "कोई फोटो नहीं मिली!"
        return 1
    fi
    info "${#all_photos[@]} फोटो मिलीं"

    require_openssl || return 1

    echo ""
    local bpass="" bpass2=""
    read -r -s -p "🔐 Master Password (min 4 chars): " bpass; echo ""
    read -r -s -p "🔐 Confirm: " bpass2; echo ""
    if [ "$bpass" != "$bpass2" ]; then
        error "Password match नहीं!"
        return 1
    fi
    if [ ${#bpass} -lt 4 ]; then
        error "Password बहुत छोटा!"
        return 1
    fi

    echo ""
    local bdel=""
    read -r -p "  Original फोटो delete करूँ? (y/n): " bdel

    echo ""
    local done_count=0 fail_count=0 total=${#all_photos[@]}

    for f in "${all_photos[@]}"; do
        ((done_count + fail_count + 1 <= total)) && true
        local current=$(( done_count + fail_count + 1 ))
        progress_bar "$current" "$total"

        local out_enc="$(basename "$f").enc"
        openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
            -in "$f" -out "$out_enc" \
            -pass "pass:${bpass}" 2>/dev/null

        if [ -f "$out_enc" ] && [ -s "$out_enc" ]; then
            ((done_count++))
            [[ "$bdel" =~ ^[Yy]$ ]] && rm -f "$f"
        else
            rm -f "$out_enc" 2>/dev/null
            ((fail_count++))
        fi
    done
    echo ""
    echo ""
    success "Batch complete! ✅ $done_count encrypted"
    [ "$fail_count" -gt 0 ] && warn "❌ $fail_count failed"
    log "Batch Lock: $done_count encrypted, $fail_count failed"
}

photo_batch_unlock() {
    header "🔓 सभी .enc फाइलें Batch Decrypt करो"
    echo ""

    local enc_files=()
    while IFS= read -r -d '' f; do
        enc_files+=("$f")
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 -name "*.enc" -type f -print0 2>/dev/null | sort -z
    )

    if [ ${#enc_files[@]} -eq 0 ]; then
        error "कोई .enc file नहीं मिली!"
        return 1
    fi
    info "${#enc_files[@]} .enc फाइलें मिलीं"

    require_openssl || return 1

    echo ""
    local bpass=""
    read -r -s -p "🔑 Master Password: " bpass; echo ""

    echo ""
    step "Decrypt कर रहा हूँ..."
    echo ""

    local done_count=0 fail_count=0 total=${#enc_files[@]}

    for f in "${enc_files[@]}"; do
        local current=$(( done_count + fail_count + 1 ))
        progress_bar "$current" "$total"

        local base="${f%.enc}"
        local out_name="dec_$(basename "$base")"

        # AES-256 try करो
        openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
            -in "$f" -out "$out_name" \
            -pass "pass:${bpass}" 2>/dev/null

        if [ -f "$out_name" ] && [ -s "$out_name" ]; then
            ((done_count++))
        else
            rm -f "$out_name" 2>/dev/null
            # AES-128 fallback
            openssl enc -d -aes-128-cbc -pbkdf2 -iter 50000 \
                -in "$f" -out "$out_name" \
                -pass "pass:${bpass}" 2>/dev/null

            if [ -f "$out_name" ] && [ -s "$out_name" ]; then
                ((done_count++))
            else
                rm -f "$out_name" 2>/dev/null
                ((fail_count++))
            fi
        fi
    done
    echo ""
    echo ""
    success "Batch complete! ✅ $done_count decrypted"
    [ "$fail_count" -gt 0 ] && warn "❌ $fail_count failed (password गलत या different password)"
    log "Batch Unlock: $done_count decrypted, $fail_count failed"
}

# ════════════════════════════════════════════════════
# ───────── OTHER TOOLS ─────────────────────────────
# ════════════════════════════════════════════════════

compress_pdf() {
    header "📦 PDF Compress करो"
    show_pdfs

    local input_raw="" input_pdf=""
    read -r -p "📄 PDF का नाम: " input_raw
    input_raw="${input_raw// /}"
    input_pdf=$(resolve_pdf "$input_raw") || {
        error "File नहीं मिली!"
        return 1
    }

    echo ""
    echo -e "${BOLD}Compression Level चुनो:${NC}"
    echo -e "  ${CYAN}1)${NC} 🟢 Light  (/printer)  — अच्छी quality, बड़ी size"
    echo -e "  ${CYAN}2)${NC} 🟡 Medium (/ebook)    — Balance ✅"
    echo -e "  ${CYAN}3)${NC} 🔴 Heavy  (/screen)   — छोटी size, कम quality"
    echo ""
    local cl=""
    read -r -p "  चुनो (1-3) [Default: 2]: " cl
    local gs_setting="/ebook"
    [ "$cl" = "1" ] && gs_setting="/printer"
    [ "$cl" = "3" ] && gs_setting="/screen"

    local out_name="compressed_$(basename "$input_pdf")"
    local orig_size
    orig_size=$(du -h "$input_pdf" 2>/dev/null | cut -f1)

    if command -v gs &>/dev/null; then
        step "Compress कर रहा हूँ ($gs_setting)..."
        gs -sDEVICE=pdfwrite \
           -dCompatibilityLevel=1.4 \
           -dPDFSETTINGS="$gs_setting" \
           -dNOPAUSE -dQUIET -dBATCH \
           -sOutputFile="$out_name" \
           "$input_pdf" 2>/dev/null

        if [ -f "$out_name" ] && [ -s "$out_name" ]; then
            local new_size
            new_size=$(du -h "$out_name" 2>/dev/null | cut -f1)
            success "Compressed! → $out_name"
            echo -e "  📉 Size: ${BOLD}$orig_size → $new_size${NC}"
            log "PDF Compressed ($gs_setting): $(basename "$input_pdf") → $out_name"
        else
            rm -f "$out_name" 2>/dev/null
            error "Compress failed!"
            return 1
        fi
    else
        error "Ghostscript जरूरी है: pkg install ghostscript"
        return 1
    fi
}

split_pdf() {
    header "✂️ PDF को Pages में Split करो"
    show_pdfs

    local input_raw="" input_pdf=""
    read -r -p "📄 PDF का नाम: " input_raw
    input_raw="${input_raw// /}"
    input_pdf=$(resolve_pdf "$input_raw") || {
        error "File नहीं मिली!"
        return 1
    }

    # Password protected?
    if grep -q "/Encrypt" "$input_pdf" 2>/dev/null; then
        warn "यह PDF locked है। पहले unlock करो।"
        return 1
    fi

    echo ""
    echo -e "${BOLD}Output Format चुनो:${NC}"
    echo -e "  ${CYAN}1)${NC} JPG Images (हर page = एक JPG)"
    echo -e "  ${CYAN}2)${NC} PNG Images (high quality)"
    echo -e "  ${CYAN}3)${NC} Individual PDFs (हर page = एक PDF)"
    echo ""
    local sfmt=""
    read -r -p "  चुनो (1-3) [Default: 1]: " sfmt

    local base_name
    base_name=$(basename "$input_pdf" .pdf)
    base_name=$(basename "$base_name" .PDF)
    local out_dir="${DEFAULT_FOLDER}/${base_name}_pages"
    mkdir -p "$out_dir"

    step "Split कर रहा हूँ..."

    case "$sfmt" in
        2)
            # PNG
            "$CONVERT_CMD" -density 150 -quality 95 \
                "$input_pdf" \
                "${out_dir}/page_%04d.png" 2>/dev/null
            ;;
        3)
            # Individual PDFs — gs से
            if command -v gs &>/dev/null; then
                # Page count detect करो
                local page_count
                page_count=$(gs -dNOPAUSE -dBATCH -dQUIET \
                    -sDEVICE=nullpage "$input_pdf" 2>/dev/null
                    # pages निकालने का दूसरा तरीका:
                    strings "$input_pdf" 2>/dev/null | grep -c "^/Type /Page$" 2>/dev/null || echo "0"
                )
                # Simpler: हर page export करो
                gs -sDEVICE=pdfwrite \
                   -dNOPAUSE -dQUIET -dBATCH \
                   -dPDFSETTINGS=/default \
                   -sOutputFile="${out_dir}/page_%04d.pdf" \
                   "$input_pdf" 2>/dev/null
            else
                warn "Ghostscript नहीं है — JPG format use होगा"
                "$CONVERT_CMD" -density 150 -quality 95 \
                    "$input_pdf" \
                    "${out_dir}/page_%04d.jpg" 2>/dev/null
            fi
            ;;
        *)
            # JPG (default)
            "$CONVERT_CMD" -density 150 -quality 95 \
                "$input_pdf" \
                "${out_dir}/page_%04d.jpg" 2>/dev/null
            ;;
    esac

    local count
    count=$(find "$out_dir" -type f | wc -l)

    if [ "$count" -gt 0 ]; then
        success "$count pages → $(basename "$out_dir")/"
        log "PDF Split: $(basename "$input_pdf") → $count pages in $out_dir"
    else
        rmdir "$out_dir" 2>/dev/null
        error "Split failed! कोई page नहीं बना।"
        return 1
    fi
}

show_info() {
    header "📊 File Information"
    echo ""

    local tp=0 td=0 te=0 tz=0

    echo -e "${BOLD}📸 Photos:${NC}"
    echo -e "${YELLOW}──────────────────────────────${NC}"
    while IFS= read -r -d '' f; do
        local sz; sz=$(du -h "$f" 2>/dev/null | cut -f1)
        echo -e "  ${GREEN}▸${NC} $(basename "$f")  ${DIM}[$sz]${NC}"
        ((tp++))
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 \
            \( -iname "*.jpg" -o -iname "*.jpeg" \
               -o -iname "*.png" -o -iname "*.webp" \) \
            -type f -print0 2>/dev/null | sort -z
    )
    [ "$tp" -eq 0 ] && echo -e "  ${DIM}(कोई फोटो नहीं)${NC}"

    echo ""
    echo -e "${BOLD}📄 PDFs:${NC}"
    echo -e "${YELLOW}──────────────────────────────${NC}"
    while IFS= read -r -d '' f; do
        local sz; sz=$(du -h "$f" 2>/dev/null | cut -f1)
        local lock="🔓"
        grep -q "/Encrypt" "$f" 2>/dev/null && lock="🔒"
        echo -e "  ${BLUE}▸${NC} $lock $(basename "$f")  ${DIM}[$sz]${NC}"
        ((td++))
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 -iname "*.pdf" -type f -print0 2>/dev/null | sort -z
    )
    [ "$td" -eq 0 ] && echo -e "  ${DIM}(कोई PDF नहीं)${NC}"

    echo ""
    echo -e "${BOLD}🔒 Encrypted (.enc):${NC}"
    echo -e "${YELLOW}──────────────────────────────${NC}"
    while IFS= read -r -d '' f; do
        local sz; sz=$(du -h "$f" 2>/dev/null | cut -f1)
        echo -e "  ${RED}▸${NC} 🔐 $(basename "$f")  ${DIM}[$sz]${NC}"
        ((te++))
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 -name "*.enc" -type f -print0 2>/dev/null | sort -z
    )
    [ "$te" -eq 0 ] && echo -e "  ${DIM}(कोई .enc file नहीं)${NC}"

    echo ""
    echo -e "${BOLD}📦 ZIPs:${NC}"
    echo -e "${YELLOW}──────────────────────────────${NC}"
    while IFS= read -r -d '' f; do
        local sz; sz=$(du -h "$f" 2>/dev/null | cut -f1)
        echo -e "  ${YELLOW}▸${NC} 📦 $(basename "$f")  ${DIM}[$sz]${NC}"
        ((tz++))
    done < <(
        find "$DEFAULT_FOLDER" -maxdepth 1 -name "*.zip" -type f -print0 2>/dev/null | sort -z
    )
    [ "$tz" -eq 0 ] && echo -e "  ${DIM}(कोई ZIP नहीं)${NC}"

    echo ""
    echo -e "${YELLOW}══════════════════════════════════════${NC}"
    local free_space
    free_space=$(df -h "$DEFAULT_FOLDER" 2>/dev/null | awk 'NR==2{print $4}')
    echo -e "  💾 Free Space: ${GREEN}${BOLD}$free_space${NC}"
    echo -e "  📊 Photos: ${BOLD}$tp${NC}  |  PDFs: ${BOLD}$td${NC}  |  Encrypted: ${BOLD}$te${NC}  |  ZIPs: ${BOLD}$tz${NC}"
    echo ""
}

show_log() {
    header "📋 Activity Log (Last 30 entries)"
    echo ""
    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        # Last 30 lines दिखाओ, color के साथ
        tail -30 "$LOG_FILE" | while IFS= read -r line; do
            echo -e "  ${DIM}$line${NC}"
        done
        echo ""
        echo -e "  ${DIM}Log file: $LOG_FILE${NC}"
        echo ""
        local del_log=""
        read -r -p "  Log साफ करें? (y/n): " del_log
        [[ "$del_log" =~ ^[Yy]$ ]] && > "$LOG_FILE" && success "Log साफ हो गया!"
    else
        info "कोई activity log नहीं है।"
    fi
}

change_folder() {
    header "📁 Working Folder बदलो"
    echo -e "  Current: ${BOLD}$DEFAULT_FOLDER${NC}"
    echo ""
    read -r -p "  नया folder path: " nf

    if [ -z "$nf" ]; then
        warn "कोई path नहीं दिया।"
        return
    fi

    if [ -d "$nf" ]; then
        DEFAULT_FOLDER="$nf"
        LOG_FILE="$DEFAULT_FOLDER/mrdpbhai_log.txt"
        cd "$DEFAULT_FOLDER" && success "Folder बदला → $DEFAULT_FOLDER"
    else
        local mk=""
        read -r -p "  '$nf' exist नहीं करता — बनाऊँ? (y/n): " mk
        if [[ "$mk" =~ ^[Yy]$ ]]; then
            mkdir -p "$nf" 2>/dev/null && {
                DEFAULT_FOLDER="$nf"
                LOG_FILE="$DEFAULT_FOLDER/mrdpbhai_log.txt"
                cd "$DEFAULT_FOLDER" && success "Folder बना और set हुआ → $DEFAULT_FOLDER"
            } || error "Folder नहीं बना! Permission check करो।"
        fi
    fi
}

# ════════════════════════════════════════════════════
# ───────── MAIN MENU ───────────────────────────────
# ════════════════════════════════════════════════════

main_menu() {
    # Startup sequence
    check_storage
    setup_folder
    first_run_check
    check_dependencies

    while true; do
        show_logo
        echo -e "  ${BOLD}${GREEN}── 📸 PDF बनाओ ──────────────────────────────${NC}"
        echo -e "  ${GREEN}  1)${NC} 2 फोटो से PDF बनाओ"
        echo -e "  ${GREEN}  2)${NC} सभी फोटो → एक PDF"
        echo -e "  ${GREEN}  3)${NC} मनचाही फोटो → PDF"
        echo ""
        echo -e "  ${BOLD}${RED}── 🔐 PDF LOCK SYSTEM ───────────────────────${NC}"
        echo -e "  ${RED}  4)${NC} 🔒 PDF Lock / 🔓 Unlock Menu"
        echo ""
        echo -e "  ${BOLD}${MAGENTA}── 🖼️  PHOTO LOCK SYSTEM ──────────────────────${NC}"
        echo -e "  ${MAGENTA}  5)${NC} 🔒 Photo Lock / 🔓 Unlock Menu"
        echo ""
        echo -e "  ${BOLD}${YELLOW}── 🛠️  PDF TOOLS ──────────────────────────────${NC}"
        echo -e "  ${YELLOW}  6)${NC} 📦 PDF Compress करो"
        echo -e "  ${YELLOW}  7)${NC} ✂️  PDF Split करो"
        echo ""
        echo -e "  ${BOLD}${CYAN}── ⚙️  EXTRA ────────────────────────────────────${NC}"
        echo -e "  ${CYAN}  8)${NC} 📊 Files की Info"
        echo -e "  ${CYAN}  9)${NC} 📋 Activity Log"
        echo -e "  ${CYAN} 10)${NC} 📁 Folder बदलो"
        echo -e "  ${CYAN} 11)${NC} 🔗 Telegram Channel"
        echo ""
        echo -e "  ${RED}  0)${NC} ❌ Exit"
        echo ""
        echo -e "${YELLOW}  ════════════════════════════════════════════${NC}"
        local choice=""
        read -r -p "  👉 Choice (0-11): " choice
        echo ""

        case "$choice" in
            1)  convert_two_photos;       pause ;;
            2)  convert_all_photos;       pause ;;
            3)  convert_selected_photos;  pause ;;
            4)  pdf_lock_menu ;;
            5)  photo_lock_menu ;;
            6)  compress_pdf;             pause ;;
            7)  split_pdf;                pause ;;
            8)  show_info;                pause ;;
            9)  show_log;                 pause ;;
            10) change_folder;            pause ;;
            11)
                echo ""
                info "Telegram Channel: $TG_CHANNEL"
                if command -v termux-open-url &>/dev/null; then
                    termux-open-url "$TG_CHANNEL" 2>/dev/null &
                elif command -v am &>/dev/null; then
                    am start -a android.intent.action.VIEW -d "$TG_CHANNEL" 2>/dev/null &
                else
                    echo -e "  ${YELLOW}Browser में खोलो: $TG_CHANNEL${NC}"
                fi
                pause
                ;;
            0)
                echo ""
                echo -e "${CYAN}${BOLD}"
                echo "  ╔══════════════════════════════════════════════╗"
                echo "  ║   🙏 धन्यवाद! MR DP BHAI Tool use करने के  ║"
                echo "  ║   लिए — t.me/mrdpbhai  ❤️                  ║"
                echo "  ╚══════════════════════════════════════════════╝"
                echo -e "${NC}"
                exit 0
                ;;
            *)
                warn "गलत choice! 0-11 के बीच चुनो।"
                sleep 1
                ;;
        esac
    done
}

# ──── Entry Point ────
main_menu