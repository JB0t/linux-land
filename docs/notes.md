# Notes

Plain Markdown files in dated folders, in a git repo of their own. The shell
finds them (fzf, ripgrep), Neovim edits them, tmux keeps a session open on
them. Nothing here needs a task tracker: notes are the personal layer, and
[clctl](#tasks-clctl) is an optional, deliberate step that turns parts of a
note into comments on a task.

## How it works

### Layout

One folder per day, `YYYY/MM/DD/`, under the notes folder. Each day has a
daily note named after the date; anything else for that day sits next to it.

```
~/notes/
├── TODO.md                          # openmisc; clctl tasks push-todo reads it
├── 2026/
│   └── 11/
│       └── 10/
│           ├── 2026-11-10.md        # daily note: nvnotes
│           ├── standup-prep.md      # nvnotes "standup prep"
│           ├── digest.md            # clctl digest
│           ├── <project path>/
│           │   ├── TASK-12.md       # task note: clctl notes open
│           │   └── TASK-12/         # files that go with it
│           └── workspaces/
│               └── TASK-12/         # clctl notes workspace: symlinks only
└── <anything else>/                 # undated folders and files are fine too
```

Because the date is in the path, you never have to remember when something
happened: search by content (`searchnotes`) or by name (Ctrl+T), and the
path tells you the day.

A new note starts with its name as a heading (`standup-prep.md` gets
`# standup prep`). An existing note is opened as it is.

### Where things live

| What | Where |
| --- | --- |
| Notes folder | `$NOTES_DIR`, set in `~/.bash_extras` |
| Default on a new machine | `notes_dir` in `ansible/group_vars/all.yml` (`~/notes`); `./setup.sh -e notes_dir=~/work/notes` to change it |
| Shell functions | `bash_additions/md_notes.sh` (`cdnotes`, `nvnotes`, `searchnotes`, ...), `bash_additions/bash_fs_extd.sh` (`yesterday`, `searchdir`), `bash_additions/gitctl.sh` (`updatenotes`) |
| tmux session | `~/.tmux/tx/sessions/init/notes.yaml` (`dir:` the notes folder) |
| clctl's notes folder | `notes_dir` in `$XDG_CONFIG_HOME/clctl`, or `$NOTES_DIR` |

`setup.sh` creates the notes folder, seeds `~/.bash_extras` with
`NOTES_DIR` and the tx `notes` session from `notes_dir`, installs ripgrep and
fzf (with its key bindings, which `.bashrc` loads from `~/.fzf.bash`) and sets
up Neovim. The seeded files are never overwritten, so to move the notes on a
machine that is already set up, edit `~/.bash_extras` and `notes.yaml`.

Clone the notes repo to that folder yourself; setup only creates it.

## Daily flows

### Start the day

```bash
tx init      # creates the init sessions; the notes session opens today's note
```

In tmux, Alt+1 switches to the `notes` session from anywhere. Its `main`
window runs `nvnotes` (today's daily note, created if needed) and its `term`
window is a shell in the notes folder.

Outside the session:

```bash
nvnotes                    # today's YYYY-MM-DD.md
nvnotes "standup prep"     # today's standup-prep.md
nvnotes infra/cert-plan    # today's infra/cert-plan.md (folders created)
yesterday                  # the last day before today that has a folder
openmisc                   # the undated TODO.md at the top of the notes folder
cdnotestoday               # cd into today's folder (created if needed)
```

`yesterday` skips days with no folder, so on a Monday it opens Friday. It
opens that day's daily note, or the folder when there is none. `openmisc`
and `yesterday` open in a new tmux window when run inside tmux. `codenotes`
works like `nvnotes` with VS Code.

### Jump to any folder: `cdnotes` + Ctrl+T

```bash
cdnotes
cd <Ctrl+T>     # fuzzy-pick any file or folder under the notes, path pasted after cd
<Alt+C>         # fuzzy-pick a folder and cd straight into it
```

Ctrl+T lists every file and folder below the current directory, so typing a
fragment of a file name (`task-12`, `11/10`, `cert`) narrows it to the
matching notes. Pick a folder: `cd` on a file fails with `Not a directory`.
A task note has a folder of the same name next to it, so typing the task ID
offers both `TASK-12.md` and `TASK-12/`.

Ctrl+T works with any command, not just `cd`:

```bash
nvim <Ctrl+T>   # open a note by name
cp <Ctrl+T> .   # copy a file out of the notes
```

Results under `workspaces/` are symlinks to the same notes elsewhere.

### Find anything by content: `searchnotes`

```bash
searchnotes                 # from any directory
searchnotes cert rotation   # start with a query
```

This is for "I remember part of what I wrote, not where or when". Type any
fragment you remember; ripgrep searches every note as you type and fzf shows
the matching lines, with the 20 lines around the selected one in a preview.
Enter opens the file in Neovim at that line. Esc gives up.

- Matches are per line, and the query is a ripgrep regex.
- Smart case: lowercase ignores case, any capital makes it exact.
- Skips `.git`, `venv` and `workspaces/`, so a linked note appears once.
- The path in each result is the day you wrote it.

`searchdir` does the same over the current directory instead of the notes.
`notegrep PATTERN` is the plain version: `grep -r` over the notes, `-l` for
file names only.

For a search by meaning rather than by words, see `clctl search` below.

### In Neovim

Open Neovim from the notes folder (the tmux session does) and Telescope
searches all of them:

| Key | Does |
| --- | --- |
| `<Space>pf` | find a note by file name |
| `<Space>pG` | live grep over the notes |
| `<Space>ps` | grep for a string you type |
| `<Space>pws` | grep for the word under the cursor |
| `gf` | open the file under the cursor; images open in the system viewer |

Pickers follow symlinks. render-markdown draws headings, lists and tables
in normal mode; insert mode shows the raw Markdown.

### Save and sync

The notes folder is a git repo; linux-land doesn't sync it any other way.

```bash
updatenotes     # git add ., commit "Update Notes", push
```

`bash_additions/updatenotes.sh` runs the same thing, for cron. Cron has no
`~/.bash_extras`, so pass the folder:

```cron
0 18 * * 1-5 NOTES_DIR=$HOME/notes $HOME/bash_additions/updatenotes.sh
```

`updatenotes` commits everything in the folder. Keep anything that shouldn't
reach the remote in the notes repo's `.gitignore`.

When `tx load notes` creates the session, it pulls first; `tx init` opens
today's note instead, so pull there yourself (`git -C "$NOTES_DIR" pull`).

## Tasks: clctl

[clctl](https://github.com/JB0t/scripts/tree/main/clis/clctl) works with
tasks in a task backend (local, ClickUp or Jira) and reads and writes the
same notes folder. The notes stay yours: clctl only posts to a task when you
run `clctl notes push`. Everything else above works without it.

Keep clctl's `notes_dir` (set by `clctl init`) the same as `NOTES_DIR`.
`NOTES_DIR` overrides it in a shell, but cron needs it in the config.

```bash
clctl notes open                       # today's task note, in a tmux window named after the task
clctl notes workspace TASK-12          # today's workspaces/TASK-12/: every day's note for the task, linked
clctl notes unpushed --since 7d        # task notes with ## sections not pushed yet, or edited since
clctl notes push                       # pick task, day and ## sections; post them as comments
clctl notes push --task-id TASK-12 --select 1,3-4 --dry-run
clctl notes tldr                       # a daily tl;dr on each task, from what was pushed
clctl digest                           # recent task activity into today's digest.md
clctl tasks push-todo                  # 'new: ' lines in TODO.md become tasks
clctl index && clctl search --notes "how did I rotate the certs"
```

- **Task notes.** `notes open` creates `TASK-12.md` and `TASK-12/` in
  today's folder and offers to start the task's timer. Write as you go, in
  `##` sections.
- **Pushing.** `notes push` posts one comment per `##` section. Sections
  already posted are skipped and edited ones update their comment, so write,
  push, keep writing, push again. Local images are uploaded with the comment.
  `notes unpushed` lists what is still only in your notes.
- **Workspaces.** `notes workspace` gathers every day you have written about
  a task into one folder of symlinks, and in tmux opens a window
  (`TASK-12-ws`) with today's note and the workspace. Run it again the next
  day to move that window to the new day.
- **tl;drs and digests.** `notes tldr` summarises only sections already
  pushed, so nothing reaches the task that you haven't pushed yourself.
  `digest` writes `digest.md` in today's folder; `digest --meeting` writes it
  next to the day's meeting note and links it from there.
- **Search by meaning.** `clctl index` embeds the notes, split by heading,
  with a local model; run it again to add new and changed notes. `clctl
  search` prints the best matches with day, file, heading and a snippet.
  Use it when you remember what it was about but none of the words.

See clctl's README for set-up and every flag.

## Reference

| Command / key | Does |
| --- | --- |
| `cdnotes` | cd to the notes folder |
| `cdnotestoday` | cd to today's folder, creating it |
| `nvnotes [NAME]` | open today's daily note, or today's `NAME.md` |
| `codenotes [NAME]` | the same in VS Code |
| `yesterday` | open the last earlier day's note |
| `openmisc` | open the top-level `TODO.md` |
| `searchnotes [QUERY]` | live content search over the notes, open at the line |
| `searchdir [QUERY]` | the same over the current directory |
| `notegrep [-l] PATTERN` | `grep -r` over the notes |
| `updatenotes` | commit and push the notes repo |
| Ctrl+T | fuzzy-pick a file or folder, paste its path |
| Alt+C | fuzzy-pick a folder, cd into it |
| Ctrl+R | fuzzy-search shell history |
| Alt+1 | tmux: switch to the `notes` session |
| `tx init` / `tx load notes` | start the notes session |
| `<Space>pf` / `<Space>pG` | Neovim: find a note by name / by content |
| `clctl notes open \| workspace \| unpushed \| push \| tldr` | task notes, see above |
| `clctl index` / `clctl search` | search the notes by meaning |
