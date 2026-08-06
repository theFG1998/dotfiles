-- 只传补全能力，其他全用默认配置
local capabilities = require("blink.cmp").get_lsp_capabilities()
vim.lsp.config("*", { capabilities = capabilities })

vim.lsp.config("lua_ls", {
	root_markers = {
		".luarc.json",
		".luarc.jsonc",
		".git",
		"init.lua",
	},
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
})

-- uv 默认把项目依赖安装到根目录下的 .venv。显式告诉 Pyright 使用该
-- 解释器，避免 Neovim 从未激活虚拟环境的 shell 启动时误报 import。
vim.lsp.config("pyright", {
	before_init = function(_, config)
		if not config.root_dir then
			return
		end

		local python = vim.fs.joinpath(config.root_dir, ".venv", "bin", "python")
		if vim.fn.executable(python) == 1 then
			config.settings = config.settings or {}
			config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, {
				pythonPath = python,
			})
		end
	end,
})

local vue_language_server_path = vim.fn.stdpath("data")
	.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

vim.lsp.config("vtsls", {
	settings = {
		vtsls = {
			tsserver = {
				globalPlugins = {
					{
						name = "@vue/typescript-plugin",
						location = vue_language_server_path,
						languages = { "vue" },
						configNamespace = "typescript",
					},
				},
			},
		},
	},
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
	},
})

vim.lsp.enable({
	"gopls",
	"vtsls",
	"vue_ls",
	"clangd",
	"pyright",
	"lua_ls",
	"vimls",
	"bashls",
	"taplo",
	"yamlls",
	"jsonls",
	"rust_analyzer",
	"marksman",
	"html",
	"cssls",
	"tailwindcss",
	"dockerls",
})

-- 诊断显示
vim.diagnostic.config({
	virtual_text = { current_line = true },
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = true },
})

-- LSP 快捷键
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local opts = { buffer = args.buf }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "[d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, opts)
		vim.keymap.set("n", "]d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, opts)
		vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
	end,
})

-- 简化的 LSP 状态命令
vim.api.nvim_create_user_command("LspStatus", function()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		print("No LSP attached to current buffer")
		return
	end

	print("Attached LSP clients:")
	print("─────────────────────")
	for _, client in ipairs(clients) do
		local root = client.config.root_dir or client.root_dir or "N/A"
		local filetypes = rawget(client.config, "filetypes")
		local fts = type(filetypes) == "table" and table.concat(filetypes, ", ") or "N/A"
		print(string.format("  • %s", client.name))
		print(string.format("    id:     %d", client.id))
		print(string.format("    root:   %s", root))
		print(string.format("    files:  %s", fts))
	end
end, { desc = "Show attached LSP clients" })
