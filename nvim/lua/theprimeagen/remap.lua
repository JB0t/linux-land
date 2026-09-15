
-- Set space as leader key
vim.g.mapleader = " "

-- Open netrw file explorer
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move selected lines down/up in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Run PlenaryTestFile in normal mode
vim.api.nvim_set_keymap("n", "<leader>tf", "<Plug>PlenaryTestFile", { noremap = false, silent = false })

-- Join lines and keep cursor position
vim.keymap.set("n", "J", "mzJ`z")

-- Center cursor after half-page jump
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Center cursor after search next/prev
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Re-indent around 'ap' text object
vim.keymap.set("n", "=ap", "ma=ap'a")

-- Restart LSP
vim.keymap.set("n", "<leader>zig", "<cmd>LspRestart<cr>")

-- Start/Stop Vim With Me plugin
vim.keymap.set("n", "<leader>vwm", function()
    require("vim-with-me").StartVimWithMe()
end)
vim.keymap.set("n", "<leader>svwm", function()
    require("vim-with-me").StopVimWithMe()
end)

-- Run PlenaryBustedFile on current file
vim.keymap.set("n", "<leader>lt", function()
    vim.cmd [[ PlenaryBustedFile % ]]
end)

-- Paste over selection without yanking
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Delete to black hole register
vim.keymap.set({ "n", "v" }, "<leader>d", "\"_d")

-- Map Ctrl-c to Esc in insert mode
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Disable Q (Ex mode)
vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<M-h>", "<cmd>silent !tmux-sessionizer -s 0 --vsplit<CR>")
vim.keymap.set("n", "<M-H>", "<cmd>silent !tmux neww tmux-sessionizer -s 0<CR>")

-- Quickfix and location list navigation
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Search and replace word under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Make current file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Go error handling snippets
vim.keymap.set(
    "n",
    "<leader>ee",
    function()
        vim.cmd("normal! oif err != nil {")
        vim.cmd("normal! o}")
        vim.cmd("normal! kOreturn err")
    end
)
vim.keymap.set(
    "n",
    "<leader>ea",
    function()
        vim.cmd("normal! oassert.NoError(err, \"\")")
        vim.cmd("normal! F\"")
        vim.cmd("normal! a")
    end
)
vim.keymap.set(
    "n",
    "<leader>ef",
    function()
        vim.cmd("normal! oif err != nil {")
        vim.cmd("normal! o}")
        vim.cmd("normal! kOlog.Fatalf(\"error: %s\\n\", err.Error())")
    end
)
vim.keymap.set(
    "n",
    "<leader>el",
    function()
        vim.cmd("normal! oif err != nil {")
        vim.cmd("normal! o}")
        vim.cmd("normal! kO.logger.Error(\"error\", \"error\", err)")
        vim.cmd("normal! F.")
        vim.cmd("normal! i")
    end
)

-- Cellular automaton animation
vim.keymap.set("n", "<leader>ca", function()
    require("cellular-automaton").start_animation("make_it_rain")
end)

-- Source current file
vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)

