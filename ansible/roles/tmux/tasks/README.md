# tasks

<!-- docgen:begin id=ansible/roles/tmux/tasks:overview scope=ansible/roles/tmux/tasks hash=7ffbcab5cf46 -->
This module manages tmux plugin installation using the tpm (Tmux Plugin Manager) system. It handles setup and maintenance of tmux plugins in the user's home directory. The module ensures plugin directories are clean before installation.

The module runs three main tasks in sequence. First, it removes any empty plugin directories that might exist from previous installations. Second, it checks out the tpm repository into the standard location. Third, it runs tpm's install script to install all configured plugins.

The tasks work together to provide a clean installation environment. Empty directories are cleared to prevent tpm from thinking plugins are already installed. The tpm repository is fetched and then its install script is executed to download and setup all plugins. The module tracks changes by monitoring output from the install command.
<!-- docgen:end id=ansible/roles/tmux/tasks:overview -->

<!-- docgen:begin id=ansible/roles/tmux/tasks:reference scope=ansible/roles/tmux/tasks hash=7ffbcab5cf46 -->
## Reference

### `main.yml`

- **`Remove empty tmux plugin dirs`** (task): tpm treats an existing empty plugin dir as installed, so clear any out (left by older checkouts that tracked plugins as empty gitlinks).
- **`Check out tpm`** (task)
- **`Install tmux plugins`** (task)
<!-- docgen:end id=ansible/roles/tmux/tasks:reference -->
