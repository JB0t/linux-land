# bash_additions

<!-- docgen:begin id=bash_additions:overview scope=bash_additions hash=77cd32b48792 -->
Bash additions module extends shell environment with custom commands and functions for common tasks. It provides specialized scripts for AWS, Azure, Git, Terraform, and note-taking workflows. Each script exports functions that integrate with system tools and user preferences.

Main components include AWS CLI extensions for profile management and login, Azure CLI helper for portal navigation, Git utilities for branch and repository operations, and Terraform control functions. File system navigation helpers offer quick directory switching and note creation. Markdown note-taking tools provide search and editing capabilities.

Functions connect through shared dependencies like `fzf`, `tmux`, and `nvim`. Scripts source each other to build upon existing functionality. Environment variables like `NOTES_DIR` and `NVIM_BIN` configure behavior. The module uses `bash_cmd_extd.sh` for clipboard and editor integration, `fs_nav_extd.sh` for directory navigation, and `md_notes.sh` for structured note management.
<!-- docgen:end id=bash_additions:overview -->

<!-- docgen:begin id=bash_additions:reference scope=bash_additions hash=77cd32b48792 -->
## Reference

### `aws_cli_extd.sh`

- **`aws_cli_extd.sh`** (script): Requires: aws cli, fzf, aws-sso-util
- **`alogin`** (function)
- **`aprofile`** (function)
- **`ainfo`** (function)
- **`alookup`** (function)

### `az_cli_extd.sh`

- **`az_cli_extd.sh`** (script): Requires: az cli, fzf, chrome
- **`azchromeopen`** (function): Open the Azure portal on a resource group or resource in the current subscription. No args: fzf over everything. With an arg: open the single match, or fzf over the matches. 'home' opens the portal landing page.

### `bash_cmd_extd.sh`

- **`bash_cmd_extd.sh`** (script): Requires: nvim, $NVIM_BIN, xclip
- **`clip_text`** (function): clip_text: the clipboard as text. xclip reads X's clipboard (on WSL, WSLg keeps it in step with Windows'); when that is empty or there is no X display, Windows' own clipboard is read through powershell.exe.
- **`paste2`** (function): paste2: paste without the terminal's paste key (which TeamViewer can swallow). paste2 the clipboard on an editable command line: Enter runs it, Ctrl+C drops it paste2 -p print the clipboard, e.g. paste2 -p > notes.md, paste2 -p | jq . Alt+V inserts the clipboard at the cursor while typing any command.
- **`lastcmd`** (function)
- **`nvim`** (function)
- **`ptouch`** (function)

### `bash_fs_extd.sh`

- **`bash_fs_extd.sh`** (script): Requires: tmux, nvim, code.
- **`nvfsextd`** (function)
- **`ghto`** (function)
- **`yesterday`** (function)
- **`freplace`** (function)

### `clctl.sh`

- **`clctl.sh`** (script): clctl is the Go binary in ~/.local/bin, built from $JB0T_SCRIPTS_DIR/clis/clctl: go build -o ~/.local/bin/clctl "$JB0T_SCRIPTS_DIR/clis/clctl"
- **`cldocs`** (function): cldocs (ClickUp Docs export) is still Python and shares clctl's config.

### `fs_nav_extd.sh`

- **`fs_nav_extd.sh`** (script): Requires: fzf, tmux, _verifyShortcut, nvim, vscode, ~/.bash_search_dirs
- **`cdto`** (function)
- **`nvto`** (function)
- **`codeto`** (function)
- **`catdir`** (function)
- **`savedir`** (function)
- **`loaddir`** (function)

### `gitctl.sh`

- **`gitctl.sh`** (script): TODO: turn this into gitctl lmao
- **`gitallbranches`** (function)
- **`gitupdate`** (function)
- **`gitm`** (function)
- **`gita`** (function)
- **`gitcurrentbranch`** (function)
- **`gito`** (function)
- **`gitchromeopen`** (function)
- **`gitcreatepr`** (function)
- **`gitpullall`** (function)
- **`clonerepos`** (function)
- **`updatenotes`** (function)

### `md_notes.sh`

- **`md_notes.sh`** (script): Requires: fs_nav_extd, tmux, nvim, fzf, rg, $NOTES_DIR, $NVIM_BIN
- **`cdnotes`** (function)
- **`cdnotestoday`** (function)
- **`openmisc`** (function)
- **`opennotes`** (function)
- **`nvnotes`** (function)
- **`codenotes`** (function)
- **`notegrep`** (function)
- **`search_notes`** (function): Live content search over $NOTES_DIR (like telescope live_grep), opens the match in $NVIM_BIN. clctl's task workspaces (YYYY/MM/DD/workspaces/) only hold symlinks to notes found elsewhere, so they are skipped: with --follow every linked note would match twice.

### `tfctl.sh`

- **`tfctl`** (function)
- **`tfvars`** (function)
- **`tfwks`** (function)
- **`tfbatch`** (function)
- **`tfruns`** (function)
- **`tfvsets`** (function)

### `tx.sh`

- **`tx.sh`** (script): Requires: bash_cmd_extd, tmux, fzf, fs_nav_extd, yq
- **`tx`** (function)
- **`tx_add`** (function)
- **`tx_create`** (function)
- **`tx_bind`** (function)
- **`txconf`** (function)
- **`tx_delete`** (function)
- **`tx_help`** (function)
- **`tx_init`** (function)
- **`tx_load`** (function)
- **`tx_print`** (function)
- **`tx_save`** (function)
- **`tx_restore`** (function)
- **`tx_session`** (function)
- **`tx_unbind`** (function)
<!-- docgen:end id=bash_additions:reference -->
