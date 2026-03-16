#!/usr/bin/env bash
SOURCE_DIR="/Users/sgkrishna/Downloads/SOURCE"
EXEC_DIR="$SOURCE_DIR/executed"

if [ -d "$EXEC_DIR" ]; then
    # Scan every file/folder inside 'executed'
    find "$EXEC_DIR" -maxdepth 1 -not -path "$EXEC_DIR" | while read -r item; do
        # Determine the date of the item
        DATE_PART=$(stat -f "%Sm" -t "%b-%d" "$item")
        PARENT_DIR="$SOURCE_DIR/$DATE_PART"
        mkdir -p "$PARENT_DIR"
        
        # Move the item into the Parent Date folder
        mv "$item" "$PARENT_DIR/"
    done
    # Remove the now-empty executed folder
    rmdir "$EXEC_DIR"
fi
