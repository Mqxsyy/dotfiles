#!/bin/zsh

SESSION_NAME="TableEditor"

if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "Session already exists!"
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

echo "Creating session..."

tmux new-session -d -s "$SESSION_NAME" -n "nvim"
tmux send-keys -t "$SESSION_NAME:1" "cd ~/Projects/TableEditor && clear && nvim" C-m

tmux new-window -t "$SESSION_NAME:2" -n "rojo" 
tmux send-keys -t "$SESSION_NAME:2" "cd ~/Projects/TableEditor && clear && ./bin/watch.sh" C-m

tmux new-window -t "$SESSION_NAME:3" -n "commands" 
tmux send-keys -t "$SESSION_NAME:3" "cd ~/Projects/TableEditor && clear" C-m

tmux select-window -t "$SESSION_NAME:1"
tmux attach-session -t "$SESSION_NAME"

