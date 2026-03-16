#!/usr/bin/env bash
SOURCE_DIR="/Users/sgkrishna/Downloads/Downloads_Current"
PASSWORD_FILE="/Users/sgkrishna/Desktop/1 passkey/passwords.txt"

# Helper to merge items and update the (#Count)
merge_into_daily() {
    local parent="$1"
    local base_name="$2"  # e.g., Extracted_Feb-04
    local source_items="$3"
    
    # 1. Find the existing folder for today
    local existing=$(find "$parent" -maxdepth 1 -type d -name "${base_name} (#*)" | head -n 1)
    
    if [ -z "$existing" ]; then
        # Create new if it doesn't exist
        local new_folder="$parent/${base_name} (#0)"
        mkdir -p "$new_folder"
        existing="$new_folder"
    fi

    # 2. Move items into the consolidated folder
    if [ -d "$source_items" ]; then
        mv "$source_items"/* "$existing/" 2>/dev/null
    else
        mv "$source_items" "$existing/" 2>/dev/null
    fi

    # 3. Recalculate total items inside and rename folder
    local total_items=$(find "$existing" -maxdepth 1 -not -path "$existing" | wc -l | tr -d ' ')
    local updated_name="$parent/${base_name} (#${total_items})"
    
    if [ "$existing" != "$updated_name" ]; then
        mv "$existing" "$updated_name"
    fi
}

# Main process
find "$SOURCE_DIR" -maxdepth 1 -type f \( -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) | while read -r file; do
    [ -e "$file" ] || continue
    [[ "$(basename "$file")" == *.command ]] && continue

    FILE_DATE=$(stat -f "%Sm" -t "%b-%d" "$file")
    PARENT_DIR="$SOURCE_DIR/$FILE_DATE"
    mkdir -p "$PARENT_DIR"

    extracted=false
    TEMP_OUT="$SOURCE_DIR/tmp_ext"
    mkdir -p "$TEMP_OUT"

    while IFS= read -r pass || [ -n "$pass" ]; do
        clean_pass=$(echo "$pass" | tr -d '\r' | xargs)
        [ -z "$clean_pass" ] && continue
        if [[ "$file" == *.zip ]]; then unzip -P "$clean_pass" -o "$file" -d "$TEMP_OUT" >/dev/null 2>&1 && extracted=true
        elif [[ "$file" == *.rar ]]; then unrar x -p"$clean_pass" -y "$file" "$TEMP_OUT" >/dev/null 2>&1 && extracted=true
        elif [[ "$file" == *.7z ]]; then 7z x -p"$clean_pass" -y "$file" -o"$TEMP_OUT" >/dev/null 2>&1 && extracted=true
        fi
        [[ $extracted == true ]] && break
    done < "$PASSWORD_FILE"

    if [ "$extracted" = true ]; then
        # Consolidated Extraction
        merge_into_daily "$PARENT_DIR" "Extracted_${FILE_DATE}" "$TEMP_OUT"
        # Consolidated Deleted (Archives)
        merge_into_daily "$PARENT_DIR" "Deleted_${FILE_DATE}" "$file"
    else
        # Consolidated Failed (Archives)
        merge_into_daily "$PARENT_DIR" "Failed_${FILE_DATE}" "$file"
    fi
    rm -rf "$TEMP_OUT"
done
