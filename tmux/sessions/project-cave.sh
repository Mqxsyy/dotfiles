#!/bin/zsh

SESSION_NAME="project-cave"

if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "Session already exists!"
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

echo "Creating session..."

tmux new-session -d -s "$SESSION_NAME" -n "nvim"
tmux send-keys -t "$SESSION_NAME:1" "cd ~/Projects/project-cave && clear && nvim" C-m

tmux new-window -t "$SESSION_NAME:2" -n "rojo" 
tmux send-keys -t "$SESSION_NAME:2" "cd ~/Projects/project-cave && clear && rojo serve" C-m

tmux new-window -t "$SESSION_NAME:3" -n "commands" 
tmux send-keys -t "$SESSION_NAME:3" "cd ~/Projects/project-cave && ./bin/build.sh && clear" C-m

tmux select-window -t "$SESSION_NAME:1"
tmux attach-session -t "$SESSION_NAME"

