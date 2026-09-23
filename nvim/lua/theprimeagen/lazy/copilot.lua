return {
  "github/copilot.vim",
  lazy = false, -- Force it to load instantly on startup instead of waiting for insert mode
  config = function()
    -- Map Tab to accept suggestions seamlessly
    vim.keymap.set('i', '<Tab>', function()
      if vim.fn['copilot#Accept']() ~= '' then
        return vim.fn['copilot#Accept']()
      else
        return '<Tab>'
      end
    end, { expr = true, silent = true })
  end
}
