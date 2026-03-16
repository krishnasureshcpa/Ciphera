#!/bin/bash
COMMAND=$1
if [[ $COMMAND == *"rm "* ]] || [[ $COMMAND == *"truncate"* ]]; then
  echo -e "\033[1;31m⚠️  CRITICAL ACTION DETECTED: $COMMAND\033[0m"
  read -p "CONFIRMATION 1/2: Are you sure? (y/N) " res1
  [[ "$res1" != "y" ]] && exit 1
  
  read -p "CONFIRMATION 2/2: TYPE 'DELETE' TO PROCEED: " res2
  [[ "$res2" != "DELETE" ]] && exit 1
fi
