return {
	{
		"mason-org/mason.nvim",
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = {
			"mason-org/mason.nvim",
		},
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					-- ========== LSP ==========
					"gopls",
					"vtsls",
					"vue-language-server",
					"clangd",
					"pyright",
					"lua-language-server",
					"vim-language-server",
					"bash-language-server",
					"taplo",
					"yaml-language-server",
					"json-lsp",
					"rust-analyzer",
					"marksman",
					"html-lsp",
					"css-lsp",
					"tailwindcss-language-server",
					"dockerfile-language-server",

					-- ========== Formatter ==========
					"gofumpt",
					"goimports",
					"prettierd",
					"prettier",
					"clang-format",
					"ruff",
					"stylua",
					"shfmt",
					"taplo",
					"sql-formatter",

					-- ========== Linter ==========
					"golangci-lint",
					"eslint_d",
					"selene",
					"shellcheck",
					"yamllint",
					"markdownlint",
					"hadolint",
					"sqlfluff",
				},
				auto_update = true,
				run_on_start = true,
				start_delay = 1500,
			})
		end,
	},
}
