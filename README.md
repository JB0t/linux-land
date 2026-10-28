# linux-land

## What's in this repo

Whatever I want to be able to pop-up somewhere else.

## Setting up a machine

### WSL

* Install [winget-cli](https://github.com/microsoft/winget-cli/releases)
* Install windows terminal

```bash
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.WindowsTerminal_8wekyb3d8bbwe
```

* Then WSL

```bash
wsl --install -d Ubuntu-26.04
```

### Post WSL

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
| `verify` | checks every tool runs, links point here (or into the copy), a new shell loads, and nvim starts with treesitter active |

Versions live in `ansible/group_vars/all.yml`. They default to `latest`; pin
one (e.g. `nvim_version: v0.12.5`) to make a machine reproducible. CPU
architecture (x86_64 or aarch64) and WSL are detected from the host.

Anything already at a path setup wants to link is moved aside to
`<path>.bak.<timestamp>` first, never overwritten.

### Another machine, from here

The target needs no checkout and no GitHub access, only SSH from here (as a
user with sudo), `python3` with `python3-apt`, and `git` for a `--check` run:

```bash
./setup.sh -i 10.5.0.15, -u jb0t          # trailing comma: a host, not an inventory file
./setup.sh -i host, -u me --ask-become-pass   # if sudo there needs a password
```

For any connection that isn't local, setup copies this checkout's tracked
files (uncommitted edits included) to `~/.local/share/linux-land` on the
target and links `$HOME` into that copy. To update the machine, re-run
setup here; a copy that's already current is left alone. If anything in the
copy was edited on the target, the whole copy is moved to
`~/.local/share/linux-land.bak.<timestamp>` before the new one goes in.
Set `-e linux_land_mode=link` or `copy` to override the choice.

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

## Moving to another machine

Two ways, depending on how much should come along.

### A new Windows machine: prepare WSL

From PowerShell on the new machine (download `windows/prepare-wsl.ps1` from this repo,
or clone it on the Windows side):

```powershell
powershell -ExecutionPolicy Bypass -File .\prepare-wsl.ps1 -NerdFont JetBrainsMono
```

It installs WSL if missing (the first time it needs "Run as administrator" and a
restart, then run it again), installs Ubuntu-24.04 (or the release in
`-Snapshot machines\NAME\manifest.json`) and lets you create your user, writes
`.wslconfig` if there is none (memory = RAM minus 8 GB, `autoMemoryReclaim=gradual`,
`sparseVhd=true`), turns on systemd in `/etc/wsl.conf` (snap, cron and user services
need it), then clones this repo and runs `./setup.sh`. Re-running it only does what
is missing. `-SkipSetup` stops before the clone; `-ReplaceWslConfig` replaces an
existing `.wslconfig` (after backing it up).

### Copy the packages and tools another machine has

`machine` (linked into `~/.local/bin` by setup) records what a machine has installed
and installs what another one is missing. Both machines must run the same Ubuntu
release on the same CPU architecture.

On the machine that has everything:

```bash
machine snapshot --bundle        # writes machines/<hostname>/
git -C ~/git/JB0t/linux-land add machines && git commit -m "snapshot"  && git push
```

It records:

| What | How it comes back |
| --- | --- |
| apt packages you installed (not the OS's own), plus third-party apt sources and their keys | sources and keys added, packages installed |
| `.deb` files installed by hand | from the bundle, if apt still had the file cached; otherwise listed |
| snaps, flatpaks | installed with the same channel / remote |
| pipx and uv tools, global npm packages, `cargo install` crates, `~/go/bin` | installed at the recorded versions (`--latest` for newest) |
| files no package owns in `/opt`, `/usr/local/bin`, `~/.local/bin`; `~/.local/share/fonts` | copied from the bundle |
| crontab, systemd user units | installed if this machine has none / lacks them |

`machines/NAME/manifest.json` and the apt keys are for git. `--bundle` also archives
the loose files and cached `.deb`s into `machines/NAME/bundle/`, which is gitignored
(it can be gigabytes): copy that folder to the same place on the other machine
yourself. The archive is written and read at most 50 MB/s (`MACHINE_RATE=20` for
less) and kept out of the page cache, so big copies don't balloon WSL's memory.

Before committing a snapshot of a work machine, check the diff: it lists third-party
apt sources (which can name internal repositories) and includes your crontab.

On the new machine, after `./setup.sh` (which installs Go, Node and the rest that the
language tools need):

```bash
git pull                          # brings machines/NAME/; copy bundle/ in as well
machine diff NAME                 # what this machine lacks; changes nothing
machine restore NAME              # install it; asks for sudo once
machine restore NAME --only apt,snap   # or one part at a time
```

`restore` only adds what is missing: it never removes anything or overwrites a file
that exists, and leaves an apt source alone if this machine has a different one by
the same name. It ends with what it added and what needs doing by hand (a `.deb` that
wasn't bundled, a `go` binary built from local source, a crontab that differs).
Symlinks that pointed into the old home folder are pointed at the new one, so the user
names can differ. Run `machine diff` again at any time to check the two still match.

### Move the whole distro instead

Copies everything: files, packages, credentials. `windows/wsl-migrate.ps1` wraps
`wsl --export` / `wsl --import`:

```powershell
# On the old machine
.\wsl-migrate.ps1 -Export D:\backups\ubuntu-24.04.tar -Distro Ubuntu-24.04
# On the new machine
.\wsl-migrate.ps1 -Import D:\backups\ubuntu-24.04.tar -Distro Ubuntu-24.04 -User jstevens
```

Export stops the distro first and copies `.wslconfig` next to the archive; import
registers it as WSL 2, makes `-User` the default login (an imported distro otherwise
logs in as root) and installs the `.wslconfig` if the new machine has none.
