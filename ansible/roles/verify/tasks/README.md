# tasks


<!-- docgen:begin id=ansible/roles/verify/tasks:reference scope=ansible/roles/verify/tasks hash=7ce818e2646a -->
## Reference

### `main.yml`

- **`Check every tool runs`** (task): Read-only checks that the machine ended up working. Nothing here changes anything; a failure means setup did not do its job.
- **`Show tool versions`** (task)
- **`Check every link points into this repo`** (task)
- **`Check a new interactive shell loads cleanly`** (task)
- **`Check nvim starts cleanly and highlights Go with treesitter`** (task)
- **`Read nvim/lazy-lock.json after setup`** (task)
- **`Show what setup changed in nvim/lazy-lock.json`** (task)
- **`Check setup left nvim/lazy-lock.json as it found it`** (task): Lazy rewrites the lockfile to match the plugin specs, so a plugin added to or removed from nvim/lua without committing the lockfile it produced fails here.
<!-- docgen:end id=ansible/roles/verify/tasks:reference -->
