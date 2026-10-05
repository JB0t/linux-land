# Automating linux-land setup

> **Status (2026-10-04):** stage 3 is built: `setup.sh` runs `ansible/site.yml`
> with a throwaway ansible-core via uv (instead of pipx). Stage 1 was skipped
> and stage 2's version pins live in `ansible/group_vars/all.yml` rather than
> `versions.env`. The verification list is the `verify` role, and the CI job
> is `.github/workflows/setup.yml`. All four config fixes at the end are done.
> Kept below for the reasoning.

Today a new machine is set up by following the README by hand. This plan
moves that to one idempotent command, in stages, so each stage is useful on
its own and the end state is a self-contained Ansible playbook.

## Goals

- **One command** on a fresh Ubuntu machine (bare metal, VM or WSL2), with
  nothing to install first except `git` and `curl`.
- **Machine-agnostic.** Nothing hardcodes a hostname, a username, `/home/jstevens`
  or a CPU architecture. Per-machine values (notes dir, search dirs) come from
  one small, untracked file with sensible defaults.
- **Idempotent.** Re-running changes nothing on a set-up machine, and is the
  way to pick up new config or upgrade tools.
- **Reproducible editor state.** Plugins come from `nvim/lazy-lock.json`, not
  whatever is latest on the day.
- **No sudo surprises.** Everything that needs root is grouped and stated up
  front; the rest runs as the user.

## Non-goals

- Supporting non-apt distros or macOS in the first pass. The layout keeps
  that possible later (see stage 3), but it isn't built until needed.
- Managing secrets or credentials (AWS, Copilot login, git identity). Setup
  prints a checklist of these at the end instead.

## Stage 1: `setup.sh`, the README as a script

A single `setup.sh` at the repo root that does exactly what the README's
"Setting up a new machine" section does, in the same order, so the README
and the script can be checked against each other line by line.

- Split into functions that match the README steps: `install_packages`,
  `install_tools` (nvim, Go, nvm/Node, fzf, yq, tree-sitter-cli,
  git-prompt), `link_dotfiles`, `wire_shell`, `install_tmux_plugins`,
  `install_nvim_plugins`.
- `./setup.sh` runs all of them; `./setup.sh link_dotfiles` runs one, for
  re-linking after pulling changes.
- Detect architecture with `uname -m` and map it to each project's
  naming (`x86_64`/`amd64`, `aarch64`/`arm64`) in one place.
- Before symlinking, move any existing real file or directory to
  `<path>.bak.<timestamp>` rather than failing or overwriting it.
- Write the `~/.bashrc` additions as a single marked block
  (`# >>> linux-land >>>` ... `# <<< linux-land <<<`) and replace that block
  on re-run, so it never gets appended twice.
- Seed `~/.bash_extras` and `~/.bash_search_dirs` only if they don't exist,
  since they are per-machine.
- `set -euo pipefail`, and a final verification pass (see "Verification").

Reuse `_ensure_packages` from `bash_additions/bash_cmd_extd.sh` for the apt
step, after fixing its `eval $(sudo apt-get update)` line, which evaluates
apt's output as a command, and its `exit 1`, which would close an
interactive shell that sourced it.

## Stage 2: pin versions in one file

Add `versions.env`, sourced by `setup.sh`:

```bash
NVIM_VERSION=latest      # or e.g. v0.12.5
GO_VERSION=latest        # or e.g. go1.27.1
NODE_VERSION=lts         # nvm alias or exact version
NVM_VERSION=v0.40.3
YQ_VERSION=latest
FZF_VERSION=latest
```

`latest` keeps today's behavior. Pinning a value makes a machine
reproducible; the installer skips the download when the installed version
already matches. This is also the input the Ansible version will reuse.

## Stage 3: Ansible playbook

Convert the stage-1 functions to roles in a playbook kept in this repo, so it
stays self-contained:

```
ansible/
  site.yml               # hosts: all, runs the roles below in order
  inventory.example.ini  # localhost ansible_connection=local
  group_vars/all.yml     # versions (from versions.env), notes_dir, search_dirs
  roles/
    packages/            # apt list; one place to add a dnf/brew variant later
    tools/               # nvim, go, nvm/node, fzf, yq, tree-sitter-cli, git-prompt
    dotfiles/            # symlinks with backup, .bashrc blockinfile, extras files
    tmux/                # placeholder cleanup, tpm, install_plugins
    nvim/                # Lazy restore, MasonInstall, treesitter install
```

- Default target is the local machine: `ansible-playbook -i ansible/inventory.example.ini ansible/site.yml -K`.
  The same playbook can then set up a remote machine by adding it to an
  inventory.
- `ansible.builtin.blockinfile` for `.bashrc`, `ansible.builtin.file
  state=link` for symlinks, `unarchive` with `creates:` for the tarballs.
- The nvim role's headless commands use `changed_when` from the lockfile
  and the Mason and parser directories, so a re-run reports "ok", not "changed".
- `setup.sh` becomes a thin bootstrap: install `ansible-core` with pipx if
  missing, then run the playbook. Stage 1's functions are kept until the
  playbook has been proven on a fresh machine, then deleted, so there is one
  source of truth.

## Verification

Run at the end of every setup, and in CI later:

- every tool resolves and reports a version (`nvim`, `go`, `node`, `fzf`,
  `yq`, `tree-sitter`, `tmux`);
- every symlink points into this repo;
- a new interactive shell sources `.bash_additions` with no errors and
  defines `tx`, `cdto`, `nvim`;
- `tmux -f ~/.tmux.conf` starts and every plugin dir is non-empty;
- `nvim --headless` on a sample `.go` file starts with no errors, an LSP
  client attaches, and a treesitter highlighter is active;
- `git status` in this repo is clean (catches a dirty lockfile).

A GitHub Actions job running the playbook in an `ubuntu:24.04` container,
plus a second run to assert nothing changes, keeps it from rotting.

## Config fixes found during the 2026-10 setup on sammy

These aren't setup gaps, but the verification step will fail until they are
fixed:

1. **Treesitter highlighting never starts.** `nvim/lua/theprimeagen/lazy/treesitter.lua`
   pins nvim-treesitter's `main` branch but passes the old `master` options
   (`ensure_installed`, `highlight.enable`, `parser_install_dir`) through
   `nvim-treesitter.config`. `main` ignores them. It needs
   `require("nvim-treesitter").install({...})` and a `FileType` autocmd
   calling `vim.treesitter.start()`. The README's step 5 installs the parsers
   as a stopgap.
2. **`.tmux/plugins/*` are tracked as empty gitlinks** without
   `.gitmodules` entries, apart from catppuccin's. Either remove them from git
   and `.gitignore` the plugins dir (tpm owns it), or make them all proper
   submodules and drop tpm's install step. The first is simpler.
3. **`@tpm_plugins` ends with a stray `\`**, which makes tpm try to install a
   plugin named `\`. It's harmless but noisy.
4. **`luarocks.nvim` is loaded but unused** (`rocks.enabled = false`). It
   breaks nvim startup whenever luarocks 3.12+ is installed on the machine.
   Removing `lazy/luarocks.lua` removes the hazard.
