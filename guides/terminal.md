# Terminal

- kitty + zsh + tmux + starship
- Short & concise

## Colors

matugen (`matugen/config.toml`) renders the wallpaper colors into kitty, tmux and
more, then reloads them live. kitty talks over a socket per instance
(`$XDG_RUNTIME_DIR/kitty-<pid>`), so every open kitty gets recolored.

starship uses terminal color names, so the prompt follows kitty's colors:

```
blue    primary        (directory, >)
purple  tertiary       (git branch)   starship says purple, not magenta
cyan    secondary      (git changes)
red     error          (> after a failed command)
dimmed  faded text     (command duration)
```

## Prompt

```
dotfiles on main [1 changed] [took 3s]
>
```
