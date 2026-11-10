vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

-- Over SSH there is no X display, so xclip cannot reach a clipboard. Send "+y and
-- "*y out as OSC 52 instead: tmux passes it to the terminal you are typing on.
-- Few terminals answer OSC 52 reads (Windows Terminal does not), so "+p pastes
-- nvim's last yank; paste from the outer machine with the terminal's paste key.
if not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY and vim.fn.has("mac") == 0 then
    local osc52 = require("vim.ui.clipboard.osc52")
    local function paste()
        return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
    end
    vim.g.clipboard = {
        name = "OSC 52",
        copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
        paste = { ["+"] = paste, ["*"] = paste },
    }
end
