return {
    "nvim-telescope/telescope.nvim",

    tag = "v0.1.9",

    dependencies = {
        "nvim-lua/plenary.nvim"
    },

    config = function()
        -- rg skips symlinked files/dirs unless told to follow them
        local follow_args = function() return { "--follow" } end
        require('telescope').setup({
            pickers = {
                find_files = { follow = true },
                live_grep = { additional_args = follow_args },
                grep_string = { additional_args = follow_args },
            },
        })

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end)
        vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
        vim.keymap.set('n', '<leader>pG', builtin.live_grep, {})

        -- Global content search including untracked/ignored files, skipping noisy dirs
        vim.keymap.set('n', '<leader>pg', function()
            builtin.live_grep({
                additional_args = function()
                    return {
                        "--hidden",
                        "--no-ignore",
                        "--follow",
                        "--glob=!.git/*",
                        "--glob=!.venv/*",
                        "--glob=!venv/*",
                        "--glob=!node_modules/*",
                        "--glob=!.agents/*",
                        "--glob=!*.key",
                        "--glob=!.bash_history",
                        "--glob=!.ssh/",
                        "--glob=!.profile",
                    }
                end,
            })
        end)
    end
}

