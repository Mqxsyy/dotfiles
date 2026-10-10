#!/bin/zsh

SESSION_NAME="VoidScape"

if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "Session already exists!"
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

echo "Creating session..."

tmux new-session -d -s "$SESSION_NAME" -n "nvim"
tmux send-keys -t "$SESSION_NAME:1" "cd ~/Projects/VoidScape && clear && nvim" C-m

tmux new-window -t "$SESSION_NAME:2" -n "git" 
tmux send-keys -t "$SESSION_NAME:2" "cd ~/Projects/VoidScape && clear" C-m

tmux new-window -t "$SESSION_NAME:3" -n "claude" 
tmux send-keys -t "$SESSION_NAME:3" "cd ~/Projects/VoidScape && clear && claude" C-m

tmux select-window -t "$SESSION_NAME:1"
tmux attach-session -t "$SESSION_NAME"

