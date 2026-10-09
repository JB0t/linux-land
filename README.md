# linux-land

## What's in this repo

Whatever I want to be able to pop-up somewhere else.

## Setting up a machine

Tested on Ubuntu 24.04 (bare metal, WSL2, and a clean container in CI).
Needs only `git`, `curl` and a user with `sudo`:

```bash
git clone https://github.com/JB0t/linux-land.git ~/git/JB0t/linux-land
cd ~/git/JB0t/linux-land
./setup.sh
```

`setup.sh` fetches [uv](https://docs.astral.sh/uv/) into `~/.cache/linux-land`
and uses it to run `ansible/site.yml` with a throwaway `ansible-core`, so
Ansible is never installed on the machine. It asks for your sudo password
once, if sudo needs one, and only uses it for apt and for installing into
`/opt` and `/usr/local`; everything else runs as you.

Re-run it any time: it only changes what differs, so it is also how you pick
up new config or tool versions on a machine that is already set up.

```bash
./setup.sh --check --diff     # show what would change, change nothing
./setup.sh --tags dotfiles    # one part: packages, tools, dotfiles, tmux, nvim, verify
./setup.sh -e notes_dir=~/work/notes   # override a value in ansible/group_vars/all.yml
```

### What it does

| Role | What |
| --- | --- |
| `packages` | apt packages (`git`, `tmux`, `ripgrep`, `fd-find`, `jq`, `xclip`, ...) |
| `tools` | Neovim into `/opt`, Go into `/usr/local/go`, yq, fzf (`~/.fzf`), nvm + Node LTS, tree-sitter-cli, `~/.git-prompt.sh` |
| `dotfiles` | symlinks `.bashrc`, `.bash_additions`, `bash_additions`, `.tmux.conf`, tx's opts and `nvim` into `$HOME`; seeds per-machine files |
| `tmux` | tpm and the plugins listed in `.tmux.conf` |
| `nvim` | plugins at the commits in `nvim/lazy-lock.json`, Mason LSP servers and delve, treesitter parsers |
| `verify` | checks every tool runs, links point here, a new shell loads, and nvim starts with treesitter active |

Versions live in `ansible/group_vars/all.yml`. They default to `latest`; pin
one (e.g. `nvim_version: v0.12.5`) to make a machine reproducible. CPU
architecture (x86_64 or aarch64) and WSL are detected from the host.

Anything already at a path setup wants to link is moved aside to
`<path>.bak.<timestamp>` first, never overwritten.

### Per-machine files

These are seeded once if missing and never overwritten, so edit them freely:

- `~/.bash_extras`: anything specific to this machine (paths, env vars,
  ssh-agent, extra PATH entries). `~/.bashrc` sources it before
  `~/.bash_additions`. Sets `GIT_ROOT_DIR` and `NOTES_DIR`.
- `~/.bash_search_dirs`: parent dirs whose subdirs `cdto`, `nvto` and tx's
  finder offer (space-separated).
- `~/.tmux/tx/sessions/`: tx session definitions. `~/.tmux` is a real
  directory on each machine (plugins and sessions); only tx's opts are linked
  from this repo.
- `~/.bash_aliases`: optional, sourced if present.

Don't install `luarocks` system-wide; nothing here uses rocks.

## Put thing in here

```bash
# From the repo root
this_dir=$(pwd)
bak_path="/path/to/backup/object"
mv $bak_path $this_dir/$( basename $bak_path) && ln -s $this_dir/$( basename $bak_path) $bak_path
```

## Save and restore tmux work

Install tmux-resurrect once by reloading tmux and pressing the tmux prefix followed by `I`. Start Neovim inside tmux at least once and let Lazy install `vim-obsession`; it keeps a `Session.vim` in each Neovim working directory for tmux-resurrect to reopen.

Before restarting WSL, run `tx save`. After WSL starts and tmux is running again, run `tx restore`. One run is enough even from a brand-new tmux server: the restore runs from the tmux server, so it survives tmux-resurrect closing the session you ran it in. Its output is also kept in `~/.tmux/tx/snapshot/restore.log`. Each save replaces the prior snapshot. The snapshot preserves tmux sessions, windows, panes, layouts, working directories, and Neovim sessions/open files. Neovim and k9s are restarted automatically; Claude runs `claude --continue` in each saved working directory, which resumes the latest conversation there rather than a captured session ID. Unsaved buffer edits are not a disk backup; write important changes before restarting.

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
