#!/usr/bin/env bash
set -euo pipefail

VERSION="5.0"
HISTORY_FILE="$HOME/.ciphera.history"

ESC=$'\e'
RED="${ESC}[0;31m"
GREEN="${ESC}[0;32m"
BLUE="${ESC}[0;34m"
YELLOW="${ESC}[1;33m"
CYAN="${ESC}[0;36m"
MAGENTA="${ESC}[0;35m"
BOLD="${ESC}[1m"
DIM="${ESC}[2m"
NC="${ESC}[0m"
BG_RED="${ESC}[41m"
BG_GREEN="${ESC}[42m"
BG_BLUE="${ESC}[44m"
WHITE="${ESC}[37m"
BG_YELLOW="${ESC}[43m"

SOURCE_DIR=""
PASSWORD_FILE=""
TARGET_DIR=""
LOG_FILE=""
PAUSE_MODE=false
SKIP_CURRENT=false
FORCE_EXTRACT=false
AUTO_MODE=false

show_banner() {
    clear
    printf "${BG_RED}${WHITE}"
    printf "\n"
    printf "  ╔═══════════════════════════════════════════════════════════════╗\n"
    printf "  ║           🔓  CIPHERA EXTRACTION ENGINE v$VERSION  🔓            ║\n"
    printf "  ║                 EXTRACTION IN PROGRESS                    ║\n"
    printf "  ╚═══════════════════════════════════════════════════════════════╝\n"
    printf "${NC}\n"
}

show_aborted() {
    clear
    printf "${BG_RED}${WHITE}"
    printf "\n"
    printf "  ╔═══════════════════════════════════════════════════════════════╗\n"
    printf "  ║                    ⚠️  ABORTED  ⚠️                          ║\n"
    printf "  ║            Extraction process terminated                    ║\n"
    printf "  ╚═══════════════════════════════════════════════════════════════╝\n"
    printf "${NC}\n"
}

show_welcome() {
    clear
    printf "${BG_BLUE}${WHITE}"
    printf "\n"
    printf "  ╔═══════════════════════════════════════════════════════════════╗\n"
    printf "  ║           🔓  CIPHERA EXTRACTION ENGINE v$VERSION  🔓            ║\n"
    printf "  ║                                                                  ║\n"
    printf "  ║            Premium Archive Password Recovery                   ║\n"
    printf "  ╚═══════════════════════════════════════════════════════════════╝\n"
    printf "${NC}\n"
    
    printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${BOLD}  Welcome to CIPHERA${NC}\n"
    printf "${DIM}  Premium Archive Extraction Utility${NC}\n"
    printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
}

show_notification() {
    local msg="$1"
    osascript -e "display notification \"$msg\" with title \"CIPHERA EXTRACTION\"" 2>/dev/null || true
}

prompt_source_folder() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  STEP 1: SELECT SOURCE FOLDER                                  ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                                                                   ║"
    echo "║   A Finder window will open to select the folder              ║"
    echo "║   containing your archive files (.zip, .7z, .rar)            ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    printf "Press [Enter] to open Finder... "
    read -r
    
    local selected
    selected=$(osascript -e "tell app \"Finder\" to activate" \
        -e "tell app \"System Events\" to tell process \"Finder\" \
            set dialogText to \"Select SOURCE folder containing archives\" \
            POSIX path of (choose folder with prompt dialogText)" 2>/dev/null)
    
    if [ -n "$selected" ] && [ -d "$selected" ]; then
        echo "$selected"
    else
        printf "No folder selected. Enter path manually: "
        read -r input
        echo "$input"
    fi
}

prompt_password_file() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  STEP 2: SELECT PASSWORD FILE                               ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                                                                   ║"
    echo "║   A Finder window will open to select your password file        ║"
    echo "║   (should be a .txt file with one password per line)            ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    printf "Press [Enter] to open Finder... "
    read -r
    
    local selected
    selected=$(osascript -e "tell app \"Finder\" to activate" \
        -e "tell app \"System Events\" to tell process \"Finder\" \
            set dialogText to \"Select PASSWORD file (txt)\" \
            POSIX path of (choose file with prompt dialogText)" 2>/dev/null)
    
    if [ -n "$selected" ] && [ -f "$selected" ]; then
        echo "$selected"
    else
        printf "No file selected. Enter path manually: "
        read -r input
        echo "$input"
    fi
}

prompt_target_folder() {
    local source="$1"
    echo ""
    echo "  Target Folder:"
    echo "    Default: Same as SOURCE ($source)"
    echo "    [1] Use SOURCE as TARGET (default)"
    echo "    [2] Select different folder"
    printf "    Enter choice [1/2]: "
    read -r choice
    
    if [[ "$choice" == "2" ]]; then
        printf "    Press [Enter] to open Finder... "
        read -r
        local selected
        selected=$(osascript -e "tell app \"Finder\" to activate" \
            -e "tell app \"System Events\" to tell process \"Finder\" \
                set dialogText to \"Select TARGET folder\" \
                POSIX path of (choose folder with prompt dialogText)" 2>/dev/null)
        if [ -n "$selected" ] && [ -d "$selected" ]; then
            echo "$selected"
        else
            echo "$source"
        fi
    else
        echo "$source"
    fi
}

show_controls() {
    printf "\n${DIM}Quick Controls: [P]ause [S]kip [V]ariations [Shift+S]Source [Q]uit${NC}\n"
}

show_help() {
    echo ""
    echo "CIPHERA v$VERSION - Archive Extraction Utility"
    echo ""
    echo "Usage: Ciphera.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --source PATH    Source folder containing archives"
    echo "  -p, --password FILE  Password file (.txt)"
    echo "  -t, --target PATH    Target folder for extraction"
    echo "  -f, --force          Force re-extraction (skip already extracted check)"
    echo "  -a, --auto           Auto-start extraction (no prompts)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  Ciphera.sh                              # Interactive mode"
    echo "  Ciphera.sh -s ~/Downloads/archives     # Specify source"
    echo "  Ciphera.sh -s ~/Xpose -p ~/pw.txt -t ~/Output -f -a"
    echo ""
}

check_deps() {
    # 7z is the only tool needed - handles ALL archive formats
    if ! command -v 7z &>/dev/null; then
        printf "${YELLOW}Installing: 7z (p7zip)...${NC}\n"
        if command -v brew &>/dev/null; then
            brew install p7zip
        else
            printf "${RED}Error: Homebrew not found. Please install p7zip manually.${NC}\n"
            exit 1
        fi
    fi
    
    # Verify 7z works
    if ! 7z &>/dev/null; then
        printf "${RED}Error: 7z is installed but not working properly${NC}\n"
        exit 1
    fi
    
    printf "${GREEN}✓ 7z ready (handles zip, 7z, rar, tar, gz, bz2, xz, etc.)${NC}\n"
}

save_history() {
    local now
    now=$(date)
    cat > "$HISTORY_FILE" <<EOF
SOURCE_DIR="$SOURCE_DIR"
PASSWORD_FILE="$PASSWORD_FILE"
TARGET_DIR="$TARGET_DIR"
LAST_RUN="$now"
EOF
}

load_history() {
    [ -f "$HISTORY_FILE" ] && source "$HISTORY_FILE" 2>/dev/null || true
    SOURCE_DIR=${SOURCE_DIR:-}
    PASSWORD_FILE=${PASSWORD_FILE:-}
    TARGET_DIR=${TARGET_DIR:-}
}

guard_rails() {
    local dir="$1"
    local name=$(basename "$dir")
    if [[ "$name" == Tr* ]] || [[ "$name" == tr* ]] || [[ "$name" == Del* ]] || [[ "$name" == del* ]]; then
        printf "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
        printf "${RED}║  ERROR: Cannot run in folder starting with Trash/Deleted     ║${NC}\n"
        printf "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
        return 1
    fi
    return 0
}

apply_tag() {
    local folder="$1"
    local color="$2"
    command -v xattr &>/dev/null || return 0
    case "$color" in
        green) xattr -wx com.apple.FinderInfo "00000000000000000004000000000000000000000000000000" "$folder" 2>/dev/null || true ;;
        blue)  xattr -wx com.apple.FinderInfo "00000000000000000002000000000000000000000000000000" "$folder" 2>/dev/null || true ;;
        red)   xattr -wx com.apple.FinderInfo "0000000000000000000C000000000000000000000000000000" "$folder" 2>/dev/null || true ;;
    esac
}

get_archives() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f \( -name "*.zip" -o -name "*.7z" -o -name "*.rar" \) 2>/dev/null | wc -l | tr -d ' '
}

get_archive_list() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f \( \
        -name "*.zip" -o -name "*.7z" -o -name "*.rar" -o \
        -name "*.tar" -o -name "*.tar.gz" -o -name "*.tgz" -o \
        -name "*.tar.bz2" -o -name "*.tbz2" -o -name "*.tar.xz" -o \
        -name "*.gz" -o -name "*.bz2" -o -name "*.xz" -o \
        -name "*.iso" -o -name "*.dmg" \
    \) 2>/dev/null | while read -r f; do
        local name
        name=$(basename "$f")
        local lower
        lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
        # Skip partial/incomplete downloads
        if [[ "$lower" == *.part ]] || [[ "$lower" == *.crdownload ]] || \
           [[ "$lower" == *.download ]] || [[ "$lower" == *.tmp ]] || \
           [[ "$lower" == *.partial ]] || [[ "$lower" == *".download" ]] || \
           [[ "$lower" == *.downloading ]] || [[ "$lower" == *.temp ]]; then
            continue
        fi
        echo "$f"
    done
}

get_split_archives() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f \( -name "*.7z.001" -o -name "*.zip.001" -o -name "*.rar.001" \) 2>/dev/null | sed 's/\.001$//' | sort -u
}

gen_variations() {
    local pw="$1"
    echo "$pw"
    local trim=$(echo "$pw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$trim" ] && return
    echo "$trim" | tr '[:lower:]' '[:upper:]'
    echo "$trim"
    echo "${trim^}"
    for i in 1 2 3 5 10 13; do printf "%${i}s%s\n" "" "$trim"; done
    for i in 1 2 3 5 10 13; do printf "%s%${i}s\n" "$trim" ""; done
    for i in 1 2 3; do printf "%${i}s%s%${i}s\n" "" "$trim" ""; done
    echo "$trim" | sed 's/a/@/g;s/A/@/g'
    echo "$trim" | sed 's/e/3/g;s/E/3/g'
    echo "$trim" | sed 's/i/1/g;s/I/1/g'
    echo "$trim" | sed 's/o/0/g;s/O/0/g'
    echo "$trim" | sed 's/s/\$/g;s/S/\$/g'
    echo "${trim}1"
    echo "1${trim}"
    echo "${trim}123"
}

test_password() {
    local arc="$1"
    local pw="$2"
    
    # Use 7z for ALL formats - it's more reliable and handles rar natively
    # 7z can test: zip, 7z, rar, tar, gz, bz2, xz, etc.
    7z t "$arc" -p"$pw" -y &>/dev/null 2>&1
    return $?
}

extract_archive() {
    local arc="$1"
    local out="$2"
    local pw="$3"
    
    mkdir -p "$out"
    # Use 7z for ALL formats - handles zip, 7z, rar, tar, gz, etc.
    7z x "$arc" -o"$out" -y -p"$pw" &>/dev/null 2>&1
}

draw_header() {
    local current=$1
    local total=$2
    local archive=$3
    local pw_count=$4
    local mode=$5
    
    printf "\n"
    printf "${CYAN}┌─────────────────────────────────────────────────────────────────────┐${NC}\n"
    printf "${CYAN}│${NC}  ${BOLD}CIPHERA EXTRACTION${NC}                                         ${CYAN}│${NC}\n"
    printf "${CYAN}├─────────────────────────────────────────────────────────────────────┤${NC}\n"
    printf "${CYAN}│${NC}  Archive: ${YELLOW}%-52s${NC}${CYAN} │${NC}\n" "$archive"
    printf "${CYAN}│${NC}  Progress: ${BOLD}$current/${total}${NC} archives                               ${CYAN}│${NC}\n"
    printf "${CYAN}│${NC}  Mode: ${MAGENTA}%-58s${NC}${CYAN} │${NC}\n" "$mode"
    printf "${CYAN}│${NC}  Passwords tried: ${BOLD}$pw_count${NC}                                       ${CYAN} │${NC}\n"
    
    if [ "$PAUSE_MODE" = true ]; then
        printf "${CYAN}│${NC}  ${BG_YELLOW}${BLACK}  ⏸ PAUSED  ${NC}                                                   ${CYAN} │${NC}\n"
    fi
    
    printf "${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}\n"
    show_controls
}

draw_status() {
    local status="$1"
    local message="$2"
    local pw="$3"
    
    local status_color="${YELLOW}"
    local status_icon="⏳"
    
    case "$status" in
        success)
            status_color="${GREEN}"
            status_icon="✓"
            ;;
        failed)
            status_color="${RED}"
            status_icon="✗"
            ;;
        trying)
            status_color="${CYAN}"
            status_icon="⟳"
            ;;
    esac
    
    printf "\n"
    printf "${CYAN}┌─────────────────────────────────────────────────────────────────────┐${NC}\n"
    printf "${CYAN}│${NC}  ${status_color}${status_icon} ${BOLD}${status}${NC}                                                     ${CYAN}│${NC}\n"
    
    if [ -n "$pw" ]; then
        printf "${CYAN}│${NC}  Password: ${GREEN}$pw${NC}                                         ${CYAN}│${NC}\n"
    else
        printf "${CYAN}│${NC}  ${message}${NC}                                          ${CYAN}│${NC}\n"
    fi
    
    printf "${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}\n"
}

draw_log_preview() {
    local log_file="$1"
    local lines=${2:-5}
    
    if [ ! -f "$log_file" ]; then
        return
    fi
    
    printf "\n"
    printf "${YELLOW}┌───────────────────────────┬───────────────────────────────────┐${NC}\n"
    printf "${YELLOW}│${NC}  ${BOLD}RECENT EXTRACTIONS${NC}                                              ${YELLOW}│${NC}\n"
    printf "${YELLOW}├───────────────────────────┼───────────────────────────────────┤${NC}\n"
    
    tail -n +15 "$log_file" 2>/dev/null | head -n "$lines" | while IFS= read -r line; do
        if echo "$line" | grep -q "│"; then
            printf "${YELLOW}│${NC} %-24s ${YELLOW}│${NC}\n" "$(echo "$line" | sed 's/│/ /g' | tr -s ' ' | cut -c1-24)"
        fi
    done
    
    printf "${YELLOW}└───────────────────────────┴───────────────────────────────────┘${NC}\n"
}

count_remaining() {
    local src="$1"
    local count=$(get_archives "$src")
    echo "$count"
}

run_extraction() {
    local src="$1"
    local pw_file="$2"
    local tgt="$3"
    local variation="$4"
    
    # Find the OLDEST creation date among archives in source folder
    # This will be used for the date folder name
    local oldest_date=""
    local oldest_ts=99999999999
    
    # Get all archives and find oldest creation date
    while IFS= read -r arc; do
        [ -z "$arc" ] && continue
        if [ -f "$arc" ]; then
            # Get file creation date (macOS)
            local created=$(mdls -name kMDItemFSCreationDate "$arc" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
            if [ -n "$created" ]; then
                local ts=$(date -j -f "%Y-%m-%d" "$created" +%s 2>/dev/null)
                if [ -n "$ts" ] && [ "$ts" -lt "$oldest_ts" ]; then
                    oldest_ts=$ts
                    oldest_date=$created
                fi
            fi
        fi
    done < <(get_archive_list "$src")
    
    # If no date found, use current date
    if [ -z "$oldest_date" ]; then
        oldest_date=$(date +"%Y-%m-%d")
    fi
    
    # Convert to Mmm-dd format (e.g., Feb-18)
    local date_str=$(date -j -f "%Y-%m-%d" "$oldest_date" +"%b-%d" 2>/dev/null)
    if [ -z "$date_str" ]; then
        date_str=$(date +"%b-%d")
    fi
    
    # Create parent folder Mmm-dd with Watch/Trash/Failed inside
    # This creates: TARGET/Feb-18/Watch, TARGET/Feb-18/Trash, TARGET/Feb-18/Failed
    local parent_folder="$tgt/$date_str"
    local watch="$parent_folder/Watch"
    local trash="$parent_folder/Trash"
    local failed="$parent_folder/Failed"
    
    # If target equals source, create inside source
    if [ "$tgt" = "$src" ]; then
        parent_folder="$src/$date_str"
        watch="$parent_folder/Watch"
        trash="$parent_folder/Trash"
        failed="$parent_folder/Failed"
    fi
    
    mkdir -p "$watch" "$trash" "$failed"
    
    LOG_FILE="$watch/extraction_log.txt"
    
    if [ "$variation" = "false" ]; then
        cat > "$LOG_FILE" <<EOF
╔══════════════════════════════════════════════════════════════════════════╗
║                    CIPHERA EXTRACTION LOG                               ║
╠════════════════════════════════════════════════════════════════════════╣
║ Source:      $src
║ Passwords:   $pw_file
║ Target:      $tgt
║ Date:        $(date +"%Y-%m-%d %H:%M:%S")
║ Mode:        STANDARD (no variations)
╚══════════════════════════════════════════════════════════════════════════╝

┌────────────────────────────────┬─────────────────────────────────────────┐
│ ARCHIVE FILE                  │ PASSWORD USED                          │
├────────────────────────────────┼─────────────────────────────────────────┤
EOF
    else
        cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════════════════
                        VARIATION MODE - PHASE 2
═══════════════════════════════════════════════════════════════════════════

EOF
    fi
    
    local archives=()
    while IFS= read -r arc; do
        [ -n "$arc" ] && archives+=("$arc")
    done < <(get_archive_list "$src")
    
    local total=${#archives[@]}
    
    if [ $total -eq 0 ]; then
        draw_status "DONE" "No archives found" ""
        return 0
    fi
    
    local extracted=0
    local failed_count=0
    local idx=0
    local pw_attempts=0
    
    for arc in "${archives[@]}"; do
        [ -e "$arc" ] || continue
        
        # Check if already extracted (skip if not force mode)
        if [ "$FORCE_EXTRACT" = false ]; then
            local check_name=$(basename "$arc")
            # Check if archive exists in ANY Trash folder (already extracted)
            local already_extracted=false
            for trash_dir in "$tgt"/*/Trash; do
                if [ -f "$trash_dir/$check_name" ]; then
                    already_extracted=true
                    break
                fi
            done
            if [ "$already_extracted" = true ]; then
                echo "  [SKIP] Already extracted: $check_name"
                continue
            fi
        fi
        
        ((idx++))
        
        [ "$SKIP_CURRENT" = true ] && SKIP_CURRENT=false && continue
        
        while [ "$PAUSE_MODE" = true ]; do
            sleep 0.5
        done
        
        local name=$(basename "$arc")
        pw_attempts=0
        
        draw_header "$idx" "$total" "$name" "$pw_attempts" "Standard Mode"
        
        local matched=false
        local used_pw=""
        
        while IFS= read -r pw || [ -n "$pw" ]; do
            [[ "$pw" =~ ^[[:space:]]*# ]] && continue
            
            while [ "$PAUSE_MODE" = true ]; do
                sleep 0.5
            done
            
            if [ "$SKIP_CURRENT" = true ]; then
                SKIP_CURRENT=false
                break
            fi
            
            ((pw_attempts++))
            
            if [ "$variation" = "false" ]; then
                if test_password "$arc" "$pw"; then
                    matched=true
                    used_pw="$pw"
                    break
                fi
            else
                while IFS= read -r var; do
                    [ -z "$var" ] && continue
                    ((pw_attempts++))
                    if test_password "$arc" "$var"; then
                        matched=true
                        used_pw="$var"
                        break 2
                    fi
                done < <(gen_variations "$pw")
            fi
            
            draw_header "$idx" "$total" "$name" "$pw_attempts" "Standard Mode"
        done < "$pw_file"
        
        if [ "$matched" = true ]; then
            extract_archive "$arc" "$watch" "$used_pw"
            mv "$arc" "$trash/"
            printf "│ %-30s │ %-40s │\n" "$name" "$used_pw" >> "$LOG_FILE"
            draw_status "SUCCESS" "Archive extracted" "$used_pw"
            ((extracted++))
        else
            mv "$arc" "$failed/"
            printf "│ %-30s │ %-40s │\n" "$name" "(none matched)" >> "$LOG_FILE"
            draw_status "FAILED" "No password matched" ""
            ((failed_count++))
        fi
        
        draw_log_preview "$LOG_FILE" 5
    done
    
    printf "└────────────────────────────────┴─────────────────────────────────────────┘\n" >> "$LOG_FILE"
    
    apply_tag "$watch" "green"
    apply_tag "$trash" "blue"
    apply_tag "$failed" "red"
    
    printf "\n"
    printf "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${GREEN}║                   EXTRACTION COMPLETE                         ║${NC}\n"
    printf "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${GREEN}║ Total Archives:     %-39s ║${NC}\n" "$total"
    printf "${GREEN}║ Successfully Opened: %-38s ║${NC}\n" "$extracted"
    printf "${GREEN}║ Failed:            %-39s ║${NC}\n" "$failed_count"
    printf "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${GREEN}║ Log: %-56s ║${NC}\n" "$LOG_FILE"
    printf "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    
    show_notification "Ciphera: $extracted extracted, $failed_count failed"
}

show_remaining_prompt() {
    local src="$1"
    local remaining=$(count_remaining "$src")
    
    printf "\n"
    printf "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${YELLOW}║              ARCHIVES REMAINING ANALYSIS                      ║${NC}\n"
    printf "${YELLOW}╠═══════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${YELLOW}║ Source Folder: %-48s ║${NC}\n" "$src"
    printf "${YELLOW}║ Remaining Archives: ${BOLD}%-38s${NC}${YELLOW} ║${NC}\n" "$remaining"
    printf "${YELLOW}╠═══════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${YELLOW}║                                                                   ║${NC}\n"
    printf "${YELLOW}║   These archives could not be opened with standard passwords   ║${NC}\n"
    printf "${YELLOW}║   Would you like to try PASSWORD VARIATIONS?                  ║${NC}\n"
    printf "${YELLOW}║                                                                   ║${NC}\n"
    printf "${YELLOW}║   ${GREEN}[V]${NC} Run with Variations (20+ password variations)         ║${NC}\n"
    printf "${YELLOW}║   ${GREEN}[S]${NC} Change Source Folder                                    ║${NC}\n"
    printf "${YELLOW}║   ${GREEN}[E]${NC} Exit                                                   ║${NC}\n"
    printf "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}\n\n"
    
    printf "${CYAN}Enter choice [V/S/E]: ${NC}"
}

main() {
    show_welcome
    check_deps
    
    # Check for command line / environment arguments
    local arg_source=""
    local arg_password=""
    local arg_target=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--source)
                arg_source="$2"
                shift 2
                ;;
            -p|--password)
                arg_password="$2"
                shift 2
                ;;
            -t|--target)
                arg_target="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_EXTRACT=true
                shift
                ;;
            -a|--auto)
                AUTO_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
    
    echo ""
    echo "Configuration:"
    echo ""
    
    # STEP 1: Source Folder
    if [ -n "$arg_source" ] && [ -d "$arg_source" ]; then
        SOURCE_DIR="$arg_source"
        echo "  Source: $SOURCE_DIR (from command line)"
    else
        SOURCE_DIR=$(prompt_source_folder)
    fi
    guard_rails "$SOURCE_DIR" || exit 1
    
    # STEP 2: Password File
    if [ -n "$arg_password" ] && [ -f "$arg_password" ]; then
        PASSWORD_FILE="$arg_password"
        echo "  Password: $PASSWORD_FILE (from command line)"
    else
        PASSWORD_FILE=$(prompt_password_file)
    fi
    
    # STEP 3: Target Folder
    if [ -n "$arg_target" ]; then
        # Create target directory if it doesn't exist
        mkdir -p "$arg_target"
        TARGET_DIR="$arg_target"
    else
        TARGET_DIR=$(prompt_target_folder "$SOURCE_DIR")
        mkdir -p "$TARGET_DIR"
    fi
    
    # STEP 4: Auto Mode (only if not already set via command line)
    if [ "$AUTO_MODE" = false ]; then
        echo ""
        echo "Auto Mode:"
        echo "  [1] Manual (press Enter to start) - DEFAULT"
        echo "  [2] Auto (start extraction immediately)"
        printf "  Enter choice [1/2]: "
        read -r auto_choice
        if [[ "$auto_choice" == "2" ]]; then
            AUTO_MODE=true
        fi
    fi
    
    # STEP 5: Force Extraction (only if not already set via command line)
    if [ "$FORCE_EXTRACT" = false ]; then
        echo ""
        echo "Force Extraction:"
        echo "  [1] Normal (skip already extracted) - DEFAULT"
        echo "  [2] Force (re-extract all archives)"
        printf "  Enter choice [1/2]: "
        read -r force_choice
        if [[ "$force_choice" == "2" ]]; then
            FORCE_EXTRACT=true
        fi
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    show_notification "Ciphera Extraction Started"
    
    show_banner
    
    run_extraction "$SOURCE_DIR" "$PASSWORD_FILE" "$TARGET_DIR" "false"
    
    # Post-extraction loop
    while true; do
        local remaining=$(count_remaining "$SOURCE_DIR")
        
        if [ "$remaining" -eq 0 ]; then
            echo ""
            echo "[✓] All archives processed successfully!"
            break
        fi
        
        show_remaining_prompt "$SOURCE_DIR"
        
        local choice
        read -r choice
        
        case "$choice" in
            v|V)
                echo ""
                echo "[*] Running VARIATION MODE..."
                run_extraction "$SOURCE_DIR" "$PASSWORD_FILE" "$TARGET_DIR" "true"
                ;;
            s|S)
                echo ""
                echo "[*] Changing SOURCE folder..."
                SOURCE_DIR=$(prompt_source_folder)
                guard_rails "$SOURCE_DIR" || continue
                save_history
                show_banner
                run_extraction "$SOURCE_DIR" "$PASSWORD_FILE" "$TARGET_DIR" "false"
                ;;
            e|E)
                break
                ;;
            *)
                echo ""
                echo "[!] Invalid option"
                ;;
        esac
    done
    
    echo ""
    echo "Press [Enter] to exit..."
    read -r input
    
    show_aborted
    show_notification "Ciphera Extraction Complete"
}

trap 'PAUSE_MODE=true' INT

main "$@"
