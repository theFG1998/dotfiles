local prettier = { "prettierd", "prettier", stop_after_first = true }

local function update_format_status(bufnr)
	return function(err)
		vim.b[bufnr].conform_failed = err ~= nil
	end
end

return {
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>,",
				function()
					local bufnr = vim.api.nvim_get_current_buf()
					require("conform").format({ async = true }, update_format_status(bufnr))
				end,
				mode = { "n", "v" },
				desc = "Format buffer or selection",
			},
		},
		opts = {
			formatters_by_ft = {
				go = { "gofumpt", "goimports" },

				javascript = prettier,
				javascriptreact = prettier,
				typescript = prettier,
				typescriptreact = prettier,
				vue = prettier,

				c = { "clang-format" },
				cpp = { "clang-format" },
				python = { "ruff_format" },
				lua = { "stylua" },

				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },

				json = prettier,
				jsonc = prettier,
				yaml = prettier,
				toml = { "taplo" },
				sql = { "sql_formatter" },

				markdown = prettier,
				html = prettier,
				css = prettier,
				scss = prettier,
			},
			default_format_opts = {
				lsp_format = "fallback",
			},
			notify_on_error = true,
			-- format_after_save = function(bufnr)
			-- 	return {}, update_format_status(bufnr)
			-- end,
		},
	},
}
