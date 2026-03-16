#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:-/Users/sgkrishna/Downloads/SOURCE}"
PASSWORD_FILE="${2:-}"
ENGINE_DIR="$SOURCE_DIR/ENGINE FILES"
LOG_FILE="$ENGINE_DIR/extraction_status.log"
if ! command -v 7z >/dev/null 2>&1; then
  echo "7z command not found; install p7zip or 7z" >&2
  exit 1
fi

timestamp() { date +"%H:%M:%S"; }
log() {
  local message="» [$(timestamp)] $1"
  printf '%s\n' "$message"
  printf '%s\n' "$message" >>"$LOG_FILE"
}
abort() {
  log "${1:-aborting}"
  exit 1
}

sanitize_password() {
  local password="$1"
  password="${password//$'\r'/}"
  password="${password//$'\n'/}"
  password="${password//$'\t'/}"
  password="${password//\"/}"
  password="${password#${password%%[![:space:]]*}}"
  password="${password%${password##*[![:space:]]}}"
  printf '%s' "$password"
}

extract_archive() {
  local archive="$1"
  local output_dir="$2"
  local base="$(basename "$archive")"
  log "starting password attempts for '$base'"
  local extracted=false
  local attempt=0
  while IFS= read -r password || [[ -n "$password" ]]; do
    local sanitized
    sanitized="$(sanitize_password "$password")"
    [[ -z "$sanitized" ]] && continue
    [[ "${sanitized:0:1}" == "#" ]] && continue
    ((attempt++))
    log "trying password #$attempt for '$base'"
    if 7z t "$archive" -p"$sanitized" >/dev/null 2>&1; then
      log "password #$attempt validated header for '$base'"
      if 7z x "$archive" -o"$output_dir" -y -p"$sanitized" >/dev/null 2>&1; then
        log "extraction complete for '$base' with password #$attempt"
        extracted=true
        break
      else
        log "extraction failed for '$base' despite valid header"
      fi
    else
      log "password #$attempt rejected for '$base'"
    fi
  done < "$PASSWORD_FILE"
  if ! $extracted; then
    log "unable to extract '$base'; check password list or archive integrity"
  fi
}

mkdir -p "$ENGINE_DIR"
touch "$LOG_FILE"

DATE_DIR="$SOURCE_DIR/$(date +%b-%d)"
mkdir -p "$DATE_DIR"
for entry in "$SOURCE_DIR"/*; do
  [[ -d "$entry" ]] || continue
  name="$(basename "$entry")"
  case "$name" in
    "ENGINE FILES"|"$(basename "$DATE_DIR")")
      continue
      ;;
    Extract*|extract*|Delete*|delete*|Fail*|fail*)
      continue
      ;;
  esac
  [[ "$entry" == "$DATE_DIR"* ]] && continue
  mv "$entry" "$DATE_DIR/"
  log "relocated $name into $DATE_DIR"
done

compressed_files=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  compressed_files+=("$line")
done < <(
  SOURCE_DIR="$SOURCE_DIR" ENGINE_DIR="$ENGINE_DIR" python3 <<'PY'
import os
import re
import sys

SOURCE = os.environ.get('SOURCE_DIR')
ENGINE = os.environ.get('ENGINE_DIR')
if SOURCE is None or ENGINE is None:
    raise SystemExit('SOURCE_DIR and ENGINE_DIR must be provided via env')

KEYWORDS = ('extract', 'delete', 'fail')
EXTENSIONS = ('.7z', '.zip', '.rar', '.tar', '.tgz', '.tar.gz', '.tar.bz2', '.tar.xz', '.gz', '.bz2', '.xz')

def skip(name):
    lower = name.lower()
    return any(keyword in lower for keyword in KEYWORDS)

def is_valid_archive(name):
    lower = name.lower()
    if re.search(r'\.[0-9]{3}$', lower):
        return False
    return any(lower.endswith(ext) for ext in EXTENSIONS)

for root, dirs, files in os.walk(SOURCE):
    if os.path.exists(ENGINE) and os.path.samefile(root, ENGINE):
        dirs[:] = []
        continue
    dirs[:] = [d for d in dirs if not skip(d)]
    base_root = os.path.basename(root)
    if skip(base_root) and root != SOURCE:
        dirs[:] = []
        continue
    for name in files:
        if skip(name) or not is_valid_archive(name):
            continue
        print(os.path.join(root, name))
PY
)

if (( ${#compressed_files[@]} == 0 )); then
  log "no standalone compressed archives found"
else
  log "processing ${#compressed_files[@]} standalone compressed archive(s)"
  for archive in "${compressed_files[@]}"; do
    if [[ -f "$archive" ]]; then
      extract_archive "$archive" "$(dirname "$archive")"
    else
      log "missing archive $(basename "$archive") – skipping"
    fi
  done
fi

if [[ -z "$PASSWORD_FILE" ]]; then
  log "no password file supplied; extraction skipped"
  exit 0
fi

if [[ ! -f "$PASSWORD_FILE" ]]; then
  abort "password list missing at $PASSWORD_FILE"
fi

log "scanning $SOURCE_DIR for split archives"

group_lines=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  group_lines+=("$line")
done < <(
  SOURCE_DIR="$SOURCE_DIR" ENGINE_DIR="$ENGINE_DIR" python3 <<'PY'
import os
import re
import sys

SOURCE = os.environ.get('SOURCE_DIR')
ENGINE = os.environ.get('ENGINE_DIR')
if SOURCE is None or ENGINE is None:
    raise SystemExit('SOURCE_DIR and ENGINE_DIR must be provided via env')

KEYWORDS = ('extract', 'delete', 'fail')
pattern = re.compile(r'^(.+?)(?:\.7z)?\.([0-9]{3})$')
groups = {}

def skip_dir(name):
    lower = name.lower()
    return any(keyword in lower for keyword in KEYWORDS)

for root, dirs, files in os.walk(SOURCE):
    if os.path.exists(ENGINE) and os.path.samefile(root, ENGINE):
        dirs[:] = []
        continue
    dirs[:] = [d for d in dirs if not skip_dir(d)]
    base_root = os.path.basename(root)
    if skip_dir(base_root) and root != SOURCE:
        dirs[:] = []
        continue
    for name in files:
        if skip_dir(name):
            continue
        match = pattern.match(name)
        if not match:
            continue
        parent = root
        base_name = match.group(1)
        key = (parent, base_name)
        groups.setdefault(key, []).append(os.path.join(root, name))

for (parent, base_name) in sorted(groups.keys()):
    chunks = groups[(parent, base_name)]
    chunks.sort(key=lambda chunk: int(os.path.basename(chunk).rsplit('.', 1)[-1]) if os.path.basename(chunk).rsplit('.', 1)[-1].isdigit() else 0)
    packed = '\x1f'.join(chunks)
    print(f"{parent}\t{base_name}\t{packed}")
PY
)

if (( ${#group_lines[@]} == 0 )); then
  log "no split archive sets detected - nothing to extract"
  exit 0
fi

log "found ${#group_lines[@]} split archive group(s)"

group_index=0
for group_line in "${group_lines[@]}"; do
  ((group_index++))
  IFS=$'\t' read -r parent_dir base_name packed <<< "$group_line"
  IFS=$'\x1f' read -r -a chunk_paths <<< "$packed"
  if [[ ${#chunk_paths[@]} -eq 1 && -z "${chunk_paths[0]}" ]]; then
    chunk_paths=()
  fi
  split_dir="$parent_dir/(split) $base_name"
  mkdir -p "$split_dir"
  log "preparing workspace for '$base_name' ($group_index/${#group_lines[@]})"

  chunk_paths_after=()
  for chunk in "${chunk_paths[@]}"; do
    if [[ -f "$chunk" ]]; then
      mv "$chunk" "$split_dir/"
      log "moved $(basename "$chunk") → $split_dir"
      chunk_paths_after+=("$split_dir/$(basename "$chunk")")
    else
      log "missing chunk $(basename "$chunk") for '$base_name'"
    fi
  done

  chunk_paths=("${chunk_paths_after[@]}")
  if (( ${#chunk_paths[@]} == 0 )); then
    log "no chunk files found for '$base_name'; skipping"
    continue
  fi

  first_chunk="${chunk_paths[0]}"
  log "found ${#chunk_paths[@]} chunk(s) for '$base_name' (header: $(basename "$first_chunk"))"

  expected_max=0
  for path in "${chunk_paths[@]}"; do
    fname="$(basename "$path")"
    num="${fname##*.}"
    if [[ "$num" =~ ^[0-9]{3}$ ]]; then
      value=$((10#$num))
      (( value > expected_max )) && expected_max=$value
    fi
  done
  missing=$(( expected_max - ${#chunk_paths[@]} ))
  if (( missing > 0 )); then
    log "chunk set for '$base_name' is missing $missing file(s) (expected $expected_max)"
  fi

  log "starting password attempts for '$base_name'"
  extracted=false
  attempt=0
  while IFS= read -r password || [[ -n "$password" ]]; do
    sanitized="$(sanitize_password "$password")"
    [[ -z "$sanitized" ]] && continue
    [[ "${sanitized:0:1}" == "#" ]] && continue
    ((attempt++))
    log "trying password #$attempt"
    if 7z t "$first_chunk" -p"$sanitized" >/dev/null 2>&1; then
      log "password #$attempt validated header"
      if 7z x "$first_chunk" -o"$split_dir" -y -p"$sanitized" >/dev/null 2>&1; then
        log "extraction complete for '$base_name' with password #$attempt"
        extracted=true
        break
      else
        log "extraction failed for '$base_name' despite valid header"
      fi
    else
      log "password #$attempt rejected"
    fi
  done < "$PASSWORD_FILE"

  if ! $extracted; then
    log "unable to extract '$base_name'; check password list or chunk integrity"
  fi
done
