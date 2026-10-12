# tasks

<!-- docgen:begin id=ansible/roles/dotfiles/tasks:overview scope=ansible/roles/dotfiles/tasks hash=e2694e2059ea -->
This module manages user dotfiles and configuration directories. It links files from a repository to home directory locations. It handles existing files by backing them up before creating links. The module preserves permissions on existing directories. It seeds per-machine files that should not be overwritten.

The module has two main tasks files. The `link.yml` file handles individual link operations. It inspects target paths, backs up existing items, and creates symbolic links. The `main.yml` file orchestrates the overall setup. It migrates old ~/.tmux symlinks to real directories. It creates necessary directories with appropriate permissions. It links all dotfiles from the repository. It seeds machine-specific files like `.bash_extras` and `.bash_search_dirs`.

The tasks work together to set up a user's environment. The main task includes the link task for each dotfile. It handles special cases like ~/.tmux migration. It ensures directories exist before linking. It seeds files that should only be created once. The backup suffix is added to moved files. The module does not overwrite existing files unless they are backups.
<!-- docgen:end id=ansible/roles/dotfiles/tasks:overview -->

<!-- docgen:begin id=ansible/roles/dotfiles/tasks:reference scope=ansible/roles/dotfiles/tasks hash=e2694e2059ea -->
## Reference

### `link.yml`

- **`Inspect ~/{{ link.dest }}`** (task): Link ~/&lt;link.dest> to &lt;repo>/&lt;link.src>. Whatever is there already (a file, a dir, or a link pointing elsewhere) is moved to &lt;dest>.bak.&lt;time>.
- **`Back up ~/{{ link.dest }}`** (task)
- **`Link ~/{{ link.dest }}`** (task)

### `main.yml`

- **`Inspect ~/.tmux`** (task): ~/.tmux stays a real, per-machine dir (tpm plugins, tx sessions); only tx's opts are linked from the repo. Older setups symlinked ~/.tmux to the repo: move that link aside and carry its tx sessions over.
- **`Migrate a symlinked ~/.tmux to a real dir`** (task)
- **`Create directories`** (task): No mode: existing dirs keep their permissions (~/.config is often 0700), new ones follow the umask.
- **`Link dotfiles into $HOME`** (task)
- **`Seed ~/.bash_extras`** (task): Per-machine files: seeded once, never overwritten
- **`Seed ~/.bash_search_dirs`** (task)
- **`Seed tx init sessions`** (task)
<!-- docgen:end id=ansible/roles/dotfiles/tasks:reference -->
