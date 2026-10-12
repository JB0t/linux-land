# tasks

<!-- docgen:begin id=ansible/roles/nvim/tasks:overview scope=ansible/roles/nvim/tasks hash=c961fae276ed -->
This module manages Neovim configuration and dependencies using Ansible. It handles plugin restoration from a lockfile, Mason package installation, and Treesitter parser setup. The module ensures Neovim is configured with correct environment variables and plugin states.

The module uses Git to manage plugin versions and lockfile integrity. It reads the `nvim/lazy-lock.json` file to determine plugin commits. If the lockfile becomes dirty during restore, it resets and retries the restore process. This maintains consistent plugin states across environments.

The module sets up the Neovim environment PATH to include Node.js binaries and Go tools. It installs Mason packages and Treesitter parsers using Neovim's built-in commands. Each task handles a specific aspect of Neovim setup, from environment preparation to final dependency installation. The module uses `nvim --headless` mode for plugin and parser operations without user interaction.
<!-- docgen:end id=ansible/roles/nvim/tasks:overview -->

<!-- docgen:begin id=ansible/roles/nvim/tasks:reference scope=ansible/roles/nvim/tasks hash=c961fae276ed -->
## Reference

### `main.yml`

- **`Read the default Node bin dir`** (task)
- **`Set the PATH nvim's plugins build and run with`** (task)
- **`Check whether nvim/lazy-lock.json has local changes`** (task): Plugins at the commits pinned in nvim/lazy-lock.json. Lazy rewrites the lockfile from whatever is checked out, so a plugin that couldn't switch (e.g. a branch change) leaves it dirty; if it was clean beforehand, put it back and restore once more.
- **`Read nvim/lazy-lock.json`** (task): lazy_init.lua bootstraps lazy.nvim from its stable branch, and restore doesn't move lazy.nvim itself, so put it at the pinned commit first.
- **`Check out lazy.nvim at the pinned commit`** (task)
- **`Record plugin commits before restoring`** (task)
- **`Restore nvim plugins from the lockfile`** (task)
- **`Check whether the restore left the lockfile dirty`** (task)
- **`Put the lockfile back and restore again`** (task)
- **`Record plugin commits after restoring`** (task)
- **`Check for Mason packages`** (task): LSP servers and debugger
- **`Install missing Mason packages`** (task)
- **`Check for treesitter parsers`** (task): Treesitter parsers (the config also installs these, but asynchronously)
- **`Install missing treesitter parsers`** (task)
<!-- docgen:end id=ansible/roles/nvim/tasks:reference -->
