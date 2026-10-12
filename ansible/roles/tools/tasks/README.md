# tasks

<!-- docgen:begin id=ansible/roles/tools/tasks:overview scope=ansible/roles/tools/tasks hash=dcf5aae96464 -->
This module installs and manages development tools on target systems. It handles Neovim, Go, yq, fzf, Node via nvm, tree-sitter-cli, and git-prompt.sh. Each tool follows the same pattern: resolve the desired version, check what is installed, and only download or install when needed.

The module uses Ansible tasks to fetch latest release information from GitHub or Go.dev APIs. It compares installed versions with wanted versions using command outputs and file stats. Only when versions differ does it perform downloads, unpacks, or installations. This avoids unnecessary work and ensures tools stay up to date.

Tasks are organized by tool. Each tool has a version resolution step, an installed version check, and an install step that runs only when needed. The module uses `unarchive`, `git`, and `command` modules. It manages files in `/opt`, `/usr/local`, and user home directories. The module supports `latest`, `lts`, or specific version strings for each tool.
<!-- docgen:end id=ansible/roles/tools/tasks:overview -->

<!-- docgen:begin id=ansible/roles/tools/tasks:reference scope=ansible/roles/tools/tasks hash=dcf5aae96464 -->
## Reference

### `main.yml`

- **`Resolve latest Neovim release`** (task): Each tool: work out the wanted version, read the installed one, and only download when they differ.
- **`Read installed Neovim version`** (task)
- **`Install Neovim`** (task)
- **`Resolve latest Go release`** (task): Go, into /usr/local/go
- **`Read installed Go version`** (task)
- **`Install Go`** (task)
- **`Resolve latest yq release`** (task): yq (mikefarah's Go yq, used by tx; not the apt "yq" package)
- **`Read installed yq version`** (task)
- **`Install yq`** (task)
- **`Resolve latest fzf release`** (task): fzf (the apt one is too old for tx's --tmux popups)
- **`Check out fzf`** (task)
- **`Check for the fzf binary`** (task)
- **`Install fzf binary and shell integration`** (task)
- **`Read installed nvm version`** (task): Node via nvm (copilot, pyright, bashls and tree-sitter-cli need it)
- **`Create the nvm dir`** (task)
- **`Install nvm {{ nvm_version }}`** (task)
- **`Install Node {{ node_version }}`** (task): A new Node version starts with no global npm packages; carry them over from the current default so CLIs installed with npm -g don't vanish.
- **`Read the default Node bin dir`** (task)
- **`Check for tree-sitter-cli`** (task): tree-sitter CLI: nvim-treesitter's main branch builds parsers with it
- **`Install tree-sitter-cli`** (task)
- **`Download git-prompt.sh`** (task): git prompt helper, sourced by bash_additions/git_ps1.sh
<!-- docgen:end id=ansible/roles/tools/tasks:reference -->
