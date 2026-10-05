return {
    'tpope/vim-obsession',
    lazy = false,
    config = function()
        vim.api.nvim_create_autocmd('VimEnter', {
            callback = function()
                if vim.env.TMUX then
                    vim.cmd('Obsess')
                end
            end,
        })
    end,
}