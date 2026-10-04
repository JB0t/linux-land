return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false, -- main branch does not support lazy-loading
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			-- Default install_dir is stdpath("data")/site, already on runtimepath
			ts.setup({})

			-- No-op for parsers already installed; builds missing ones in the background
			ts.install({
				"vimdoc", "lua", "bash", "go", "python", "javascript", "typescript",
				"json", "yaml", "c", "markdown", "markdown_inline",
			})

			vim.treesitter.language.register("templ", "templ")

			local skip_highlight = { html = true, help = true, vimdoc = true }
			local max_filesize = 100 * 1024 -- 100 KB

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("ThePrimeagenTreesitter", { clear = true }),
				callback = function(args)
					local buf = args.buf
					local lang = vim.treesitter.language.get_lang(args.match) or args.match
					if skip_highlight[lang] then
						return
					end

					local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						vim.notify(
							"File larger than 100KB treesitter disabled for performance",
							vim.log.levels.WARN,
							{ title = "Treesitter" }
						)
						return
					end

					-- Fails quietly when no parser is installed for this filetype
					if not pcall(vim.treesitter.start, buf, lang) then
						return
					end

					vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

					-- Keep regex syntax alongside treesitter where we rely on it
					if lang == "markdown" then
						vim.bo[buf].syntax = "ON"
					end
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-context",
		after = "nvim-treesitter",
		config = function()
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				multiwindow = false, -- Enable multiwindow support.
				max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 20, -- Maximum number of lines to show for a single context
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- Separator between context and content. Should be a single character string, like '-'.
				-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
				separator = nil,
				zindex = 20, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
}
