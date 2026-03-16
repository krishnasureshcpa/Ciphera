#!/usr/bin/env bash
SOURCE_DIR="/Users/sgkrishna/Downloads/SOURCE"

# Function to apply tags (2: Green, 4: Blue, 6: Red)
apply_tag() {
    xattr -wx com.apple.FinderInfo "0000000000000000000$2 00000000000000000000000000000000" "$1" 2>/dev/null
}

find "$SOURCE_DIR" -maxdepth 1 -type d | while read -r dir; do
    folder_name=$(basename "$dir")
    
    # Skip the SOURCE folder and the Toggle script
    [[ "$folder_name" == "SOURCE" ]] || [[ "$folder_name" == .* ]] && continue
    
    # Identify the Date from the name (e.g., Feb-04)
    DATE_PART=$(echo "$folder_name" | grep -oE '[A-Z][a-z]{2}-[0-9]{2}')
    
    # If no date in name, use the folder's creation date
    if [ -z "$DATE_PART" ]; then
        DATE_PART=$(stat -f "%Sm" -t "%b-%d" "$dir")
    fi

    # Create the Parent Date Folder
    PARENT_DIR="$SOURCE_DIR/$DATE_PART"
    mkdir -p "$PARENT_DIR"

    # Determine Type and Color Tag
    if [[ "$folder_name" == Extracted* ]]; then tag=2; fi
    if [[ "$folder_name" == Deleted* ]]; then tag=4; fi
    if [[ "$folder_name" == Failed* ]]; then tag=6; fi

    # Move the folder into the Parent Date Folder
    if [ ! -z "$tag" ]; then
        mv "$dir" "$PARENT_DIR/" 2>/dev/null
        apply_tag "$PARENT_DIR/$folder_name" "$tag"
    fi
done

# Final Cleanup: Remove non-conforming empty folders
rmdir "$SOURCE_DIR/Deleted" "$SOURCE_DIR/executed" 2>/dev/null
