#!/bin/bash
SOURCE_DIR="/Users/sgkrishna/Downloads/SOURCE"
ENGINE_DIR="$SOURCE_DIR/ENGINE FILES"
DATE_STR=$(date +%b-%d)

# 1. Run the Extraction Engine first
if [ -f "$ENGINE_DIR/crystal_extract.sh" ]; then
    "$ENGINE_DIR/crystal_extract.sh"
fi

# 2. Re-Organization Fix: Move any stray "Deleted" folders into the Date parent
if [ -d "$SOURCE_DIR/Deleted" ]; then
    mkdir -p "$SOURCE_DIR/$DATE_STR"
    mv "$SOURCE_DIR/Deleted"/* "$SOURCE_DIR/$DATE_STR/" 2>/dev/null
    rmdir "$SOURCE_DIR/Deleted"
fi

# 3. Clean empty parent folders
find "$SOURCE_DIR" -maxdepth 1 -type d -empty -not -path "$SOURCE_DIR" -delete
