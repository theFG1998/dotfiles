local opt = vim.opt
local keyset = vim.keymap.set

local function set_global_var()
	vim.g.mapleader = " "
	vim.g.loaded_perl_provider = 0
	vim.g.vimsyn_embed = "l"
end

local function set_option()
	opt.termguicolors = true
	opt.shiftwidth = 2
	opt.softtabstop = -1
	opt.tabstop = 2
	opt.expandtab = true
	opt.number = true
	opt.relativenumber = true
	opt.scrolloff = 5
	opt.clipboard:append("unnamedplus")
	opt.ignorecase = true
	opt.smartcase = true
	opt.hlsearch = true
	opt.incsearch = true
end

function Cmt(opts)
	local str = "-- ================  " .. opts.fargs[1] .. "  ================ --"
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line_count = vim.api.nvim_buf_line_count(0)
	local insert_pos = math.min(row, line_count)

	vim.api.nvim_buf_set_lines(0, insert_pos, insert_pos, false, { str, "" })
	vim.api.nvim_win_set_cursor(0, { insert_pos + 2, 0 })
	vim.cmd.startinsert()
end

function CompileAndRun()
	local ft = vim.bo.filetype
	local cmd
	local file = vim.fn.expand("%:p")
	local file_no_ext = vim.fn.expand("%:p:r")

	if ft == "javascript" then
		cmd = { "node", file }
	elseif ft == "typescript" then
		cmd = { "ts-node", file }
	elseif ft == "lua" then
		cmd = { "lua", file }
	elseif ft == "cpp" then
		cmd = string.format('clang++ -std=c++20 "%s" -o "%s" && "%s"', file, file_no_ext, file_no_ext)
	elseif ft == "python" then
		cmd = { "python3", file }
	elseif ft == "go" then
		cmd = string.format('go build -o "%s" && "%s"', file_no_ext, file_no_ext)
	else
		vim.notify("No run command for filetype: " .. ft, vim.log.levels.WARN)
		return
	end

	vim.cmd("w")
	local buf = vim.api.nvim_create_buf(false, true)
	vim.cmd("botright split")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_buf_call(buf, function()
		vim.fn.jobstart(cmd, { term = true })
	end)
end

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

local function sync_alac_bg()
	local function set_alacritty_bg()
		if vim.env.TERM_PROGRAM ~= "alacritty" and not vim.env.ALACRITTY_LOG then
			return
		end
		local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = true })
		if normal.bg then
			io.stdout:write(("\027]11;#%06x\027\\"):format(normal.bg))
			io.stdout:flush()
		end
	end
	local function reset_terminal_bg()
		if vim.env.TERM_PROGRAM ~= "alacritty" and not vim.env.ALACRITTY_LOG then
			return
		end
		io.stdout:write("\027]111\027\\")
		io.stdout:flush()
	end
	vim.api.nvim_create_autocmd({ "VimEnter", "VimResume", "ColorScheme" }, {
		group = augroup,
		callback = set_alacritty_bg,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = augroup,
		callback = reset_terminal_bg,
	})
end

local function back_last_cursor_position()
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		desc = "Restore last cursor position",
		callback = function()
			if vim.o.diff then -- except in diff mode
				return
			end

			local last_pos = vim.api.nvim_buf_get_mark(0, '"') -- {line, col}
			local last_line = vim.api.nvim_buf_line_count(0)

			local row = last_pos[1]
			if row < 1 or row > last_line then
				return
			end

			pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
		end,
	})
end

local function set_keymap()
	-- Terminals encode Esc and Ctrl-[ identically; let terminal UIs receive Esc.
	pcall(vim.keymap.del, "t", "<C-[>")
	keyset("n", "<leader><cr>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlights" })
	keyset("n", "S", "<cmd>w<CR>", { desc = "Save file" })
	keyset("n", "Q", "<cmd>q<CR>", { desc = "Quit" })
	keyset({ "n", "x" }, "K", "7k", { desc = "Move up 7 lines" })
	keyset({ "n", "x" }, "H", "8h", { desc = "Move left 8 chars" })
	keyset({ "n", "x" }, "J", "7j", { desc = "Move down 7 lines" })
	keyset({ "n", "x" }, "L", "8l", { desc = "Move right 8 chars" })
	keyset("n", "bn", "<cmd>bn<cr>", { desc = "Next buffer" })
	keyset("n", "bp", "<cmd>bp<cr>", { desc = "Previous buffer" })
	keyset("n", "r", CompileAndRun, { desc = "Compile and run current file" })
	vim.api.nvim_create_user_command("Cmt", Cmt, { nargs = 1 })
end

set_global_var()
set_option()
sync_alac_bg()
set_keymap()
back_last_cursor_position()
