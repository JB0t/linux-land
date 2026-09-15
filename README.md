# linux-land

## What's in this repo

Whatever I want to be able to pop-up somewhere else.

## things

```bash
# From this repo root
this_dir=$(pwd)

# Custom Bash functions
ln -s $this_dir/bash_additions ~/bash_additions
ln -s $this_dir/.bash_additions ~/.bash_additions

# Custom tmux config
ln -s $this_dir/.tmux ~/.tmux
ln -s $this_dir/.tmux.conf ~/.tmux.conf

# Custom nvim config
mkdir -p ~/.config
ln -s $this_dir/nvim ~/.config/nvim
```

## Put thing in here

```bash
# From the repo root
this_dir=$(pwd)
bak_path="/path/to/backup/object"
mv $bak_path $this_dir/$( basename $bak_path) && ln -s $this_dir/$( basename $bak_path) $bak_path
```