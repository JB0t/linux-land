# workflows

<!-- docgen:begin id=.github/workflows:overview scope=.github/workflows hash=782506ac7ae2 -->
This workflow sets up a clean Ubuntu 24.04 environment for testing Linux setup scripts. It runs on push to main, pull request, and manual dispatch. The job uses a fresh container without preinstalled tools.

The workflow installs basic dependencies like git and curl before checking out the repository. It creates a normal user account with passwordless sudo access. The setup script runs twice to verify idempotency.

The first run executes the setup script as the test user. The second run checks that no changes occur, confirming the script is idempotent. Logs from the second run show expected counts of changed, unreachable, and failed tasks.
<!-- docgen:end id=.github/workflows:overview -->

<!-- docgen:begin id=.github/workflows:reference scope=.github/workflows hash=782506ac7ae2 -->
## Reference

### `setup.yml`

- **`setup`** (workflow)
- **`fresh-ubuntu`** (job)
<!-- docgen:end id=.github/workflows:reference -->
