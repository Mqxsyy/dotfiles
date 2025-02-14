#!/bin/zsh
if [ $# -lt 1 ]; then
    echo "Missing file path"
    exit 1
fi

file_path="$1"

clear
wallust run $file_path

kill -SIGUSR1 $KITTY_PID

clear
neofetch
