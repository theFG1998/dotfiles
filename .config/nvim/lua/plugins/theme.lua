local transparent = true

return {
	{
		"EdenEast/nightfox.nvim",
		config = function()
			require("nightfox").setup({
				options = {
					transparent = transparent,
				},
				groups = {
					all = {
						NormalFloat = { fg = "fg1", bg = transparent and "NONE" or "bg0" },
					},
				},
			})
			vim.cmd([[colorscheme terafox]])
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				sections = {
					lualine_c = {
						{
							function()
								return vim.b.conform_failed and "FMT!" or ""
							end,
							color = {
								fg = "#e5c07b",
							},
						},
						"filename",
					},
				},
			})
		end,
	},
}
