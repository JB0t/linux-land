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
