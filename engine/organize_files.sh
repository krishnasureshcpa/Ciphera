#!/bin/bash
FILE_PATH=$1
[[ ! -f "$FILE_PATH" ]] && exit 0
EXT="${FILE_PATH##*.}"

case $EXT in
  js|ts|py|go|cpp) DEST="src/" ;;
  md|txt|pdf)      DEST="docs/" ;;
  json|yaml|yml)   DEST="config/" ;;
  *)               DEST="assets/" ;;
esac

mkdir -p "$DEST"
mv "$FILE_PATH" "$DEST"
echo -e "\033[1;34m📦 Organized:\033[0m $FILE_PATH -> $DEST"
