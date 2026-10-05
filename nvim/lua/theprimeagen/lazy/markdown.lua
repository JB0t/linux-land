return {
    'MeanderingProgrammer/render-markdown.nvim',
    lazy = false,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
        render_modes = { 'n', 'c' }, -- Keeps layouts cleanly formatted in normal mode
        table = {
            enabled = true,
            style = 'full',          -- Draws clear box borders around columns
        },
    },
    config = function(_, opts)
        require('render-markdown').setup(opts)

        -- Required to let the plugin calculate correct column padding
        vim.opt.conceallevel = 2
        vim.opt.concealcursor = 'nc'
    end
}
