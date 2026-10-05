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

## Save and restore tmux work

Install tmux-resurrect once by reloading tmux and pressing the tmux prefix followed by `I`. Start Neovim inside tmux at least once and let Lazy install `vim-obsession`; it keeps a `Session.vim` in each Neovim working directory for tmux-resurrect to reopen.

Before restarting WSL, run `tx save`. After WSL starts and tmux is running again, run `tx restore`. Each save replaces the prior snapshot. The snapshot preserves tmux sessions, windows, panes, layouts, working directories, and Neovim sessions/open files. Neovim and k9s are restarted automatically; Claude runs `claude --continue` in each saved working directory, which resumes the latest conversation there rather than a captured session ID. Unsaved buffer edits are not a disk backup; write important changes before restarting.

## If you need to lift-and-shift your WSL

### Import/Export

On the current machine:

```powershell
# Probably Ubuntu-26.04
wsl --list --verbose
wsl --export Ubuntu-26.04 D:\backups\ubuntu-26.04.tar
```

On the new machine:

```powershell
wsl --import Ubuntu-26.04 C:\WSL\Ubuntu-26.04 D:\path\to\ubuntu-26.04.tar --version 2
```

Re-establish default login user:

```powershell
wsl -d Ubuntu-26.04 -u root
```

Add this to `/etc/wsl.conf`:

```conf
[user]
default=jstevens
```

### Other

* Copy `.wslconfig`
