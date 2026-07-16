return {
	{
		"mfussenegger/nvim-lint",
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				-- Go
				go = { "golangcilint" },

				-- TypeScript / JavaScript / React / Vue
				javascript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescript = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				vue = { "eslint_d" },

				-- Python
				python = { "ruff" },

				-- Lua
				lua = { "selene" },

				-- Shell
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				zsh = { "zsh" },

				-- YAML
				yaml = { "yamllint" },

				-- Markdown
				markdown = { "markdownlint" },

				-- Dockerfile
				dockerfile = { "hadolint" },

				-- SQL
				sql = { "sqlfluff" },
			}

			-- Selene must use this config even when Neovim was launched outside this directory.
			lint.linters.selene.args = {
				"--config",
				vim.fn.stdpath("config") .. "/selene.toml",
				"--display-style",
				"json",
				"-",
			}

			-- SQLFluff requires a dialect. ANSI provides a safe baseline for generic SQL.
			lint.linters.sqlfluff.args = {
				"lint",
				"--format=json",
				"--dialect=ansi",
				"-",
			}

			local insert_leave_linters = {
				javascript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescript = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				vue = { "eslint_d" },
				python = { "ruff" },
				lua = { "selene" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				zsh = { "zsh" },
			}

			local function try_lint(bufnr, linters)
				if vim.bo[bufnr].buftype ~= "" or not linters then
					return
				end

				vim.api.nvim_buf_call(bufnr, function()
					lint.try_lint(linters)
				end)
			end

			local group = vim.api.nvim_create_augroup("NvimLint", { clear = true })

			vim.api.nvim_create_autocmd("BufWritePost", {
				group = group,
				callback = function(args)
					try_lint(args.buf, lint.linters_by_ft[vim.bo[args.buf].filetype])
				end,
			})

			vim.api.nvim_create_autocmd("InsertLeave", {
				group = group,
				callback = function(args)
					try_lint(args.buf, insert_leave_linters[vim.bo[args.buf].filetype])
				end,
			})
		end,
	},
}
