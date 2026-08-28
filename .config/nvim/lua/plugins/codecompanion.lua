return {
	{
		"olimorris/codecompanion.nvim",
		version = "^19.0.0",
		cmd = {
			"CodeCompanionChat",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			adapters = {
				acp = {
					-- Grok Build CLI via ACP (OAuth from `grok login` / ~/.grok/auth.json)
					grok = function()
						local helpers = require("codecompanion.adapters.acp.helpers")
						local version = require("codecompanion").version() or "unknown"
						return {
							name = "grok",
							formatted_name = "Grok",
							type = "acp",
							roles = {
								llm = "assistant",
								user = "user",
							},
							opts = {
								vision = true,
							},
							commands = {
								default = {
									"grok",
									"agent",
									"-m",
									"grok-4.6",
									"stdio",
								},
							},
							defaults = {
								mcpServers = {},
								timeout = 20000,
								model = "grok-4.6",
							},
							parameters = {
								protocolVersion = 1,
								clientCapabilities = {
									fs = { readTextFile = true, writeTextFile = true },
								},
								clientInfo = {
									name = "CodeCompanion.nvim",
									version = version,
								},
							},
							handlers = {
								setup = function(self)
									return true
								end,
								-- Grok CLI owns OAuth (subscription). Pre-auth with `grok login`.
								auth = function(self)
									return true
								end,
								form_messages = function(self, messages, capabilities)
									return helpers.form_messages(self, messages, capabilities)
								end,
								on_exit = function(self, code) end,
							},
						}
					end,
				},
			},
			interactions = {
				chat = {
					adapter = {
						name = "grok",
						model = "grok-4.6",
					},
				},
			},
			opts = {
				log_level = "INFO",
			},
		},
		keys = {
			{
				"<leader>aa",
				"<cmd>CodeCompanionChat<cr>",
				mode = { "n", "v" },
				desc = "AI new chat",
			},
			{
				"<leader>at",
				"<cmd>CodeCompanionChat Toggle<cr>",
				mode = { "n", "v" },
				desc = "AI toggle chat",
			},
			{
				"<leader>ad",
				"<cmd>CodeCompanionChat Add<cr>",
				mode = "v",
				desc = "AI add selection to chat",
			},
		},
	},
}
