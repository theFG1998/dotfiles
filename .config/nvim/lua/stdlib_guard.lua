local M = {}

local roots = {}
local group_name = "StdlibGuard"
local probe_state = {}

local probes = {
	go = {
		label = "Go standard library",
		argv = { "go", "env", "GOROOT" },
	},
	python = {
		label = "Python standard library",
		argv = {
			"python3",
			"-c",
			"import sysconfig; print(sysconfig.get_paths().get('stdlib', '')); print(sysconfig.get_paths().get('platstdlib', ''))",
		},
	},
	rust = {
		label = "Rust toolchain and standard library",
		argv = { "rustc", "--print", "sysroot" },
	},
	ruby = {
		label = "Ruby standard library",
		argv = { "ruby", "-rrbconfig", "-e", "puts RbConfig::CONFIG['rubylibdir']" },
	},
	java = {
		label = "Java standard library",
		argv = { "/usr/libexec/java_home" },
	},
	clang = {
		label = "Clang standard headers",
		argv = { "clang", "-print-resource-dir" },
	},
	perl = {
		label = "Perl standard library",
		argv = { "perl", "-MConfig", "-e", "print $Config{privlib}" },
	},
	r_language = {
		label = "R runtime and standard library",
		argv = { "R", "RHOME" },
	},
}

local probes_by_filetype = {
	c = { "clang" },
	cpp = { "clang" },
	cuda = { "clang" },
	go = { "go" },
	gomod = { "go" },
	gotmpl = { "go" },
	gowork = { "go" },
	java = { "java" },
	objc = { "clang" },
	objcpp = { "clang" },
	opencl = { "clang" },
	perl = { "perl" },
	python = { "python" },
	r = { "r_language" },
	rmd = { "r_language" },
	rnoweb = { "r_language" },
	ruby = { "ruby" },
	rust = { "rust" },
}

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalized(path)
	if not path or path == "" then
		return nil
	end

	path = vim.fs.normalize(path)
	local resolved = vim.uv.fs_realpath(path)
	if resolved then
		return vim.fs.normalize(resolved)
	end

	-- BufNewFile paths do not exist yet. Resolve their parent so paths reached
	-- through Homebrew's `opt` symlinks are still covered.
	local parent = vim.fs.dirname(path)
	local resolved_parent = parent and vim.uv.fs_realpath(parent)
	if resolved_parent then
		return vim.fs.joinpath(vim.fs.normalize(resolved_parent), vim.fs.basename(path))
	end

	return path
end

local function is_within(path, root)
	return path == root or vim.startswith(path, root .. "/")
end

local function add_root(label, path)
	path = normalized(path)
	if not path or not vim.uv.fs_stat(path) then
		return
	end

	for _, item in ipairs(roots) do
		if item.path == path then
			return
		end
	end
	table.insert(roots, { label = label, path = path })
end

local function output_lines(stdout)
	local lines = {}
	for line in (stdout or ""):gmatch("[^\r\n]+") do
		line = trim(line)
		if line ~= "" then
			table.insert(lines, line)
		end
	end
	return lines
end

local function discover_static_roots()
	roots = {}

	-- Package-manager and operating-system trees are intentionally protected as
	-- a whole. This makes the policy language-agnostic and covers future runtimes.
	add_root("Homebrew installation", "/opt/homebrew/Cellar")
	add_root("Homebrew installation", "/usr/local/Cellar")
	add_root("macOS system library", "/System/Library")
	add_root("Apple developer toolchain", "/Library/Developer/CommandLineTools")
	add_root("Xcode toolchain", "/Applications/Xcode.app/Contents/Developer")
	add_root("system headers", "/usr/include")

	add_root("Neovim runtime", vim.env.VIMRUNTIME)
	add_root("Go standard library", vim.env.GOROOT)
	add_root("Go module cache", vim.fs.joinpath(vim.env.HOME, "go", "pkg", "mod"))
	add_root("Java standard library", vim.env.JAVA_HOME)
end

local function special_path_reason(path)
	-- JavaScript's standard library is represented by TypeScript declaration
	-- files and can live inside a project rather than a global runtime tree.
	if path:match("/node_modules/typescript/lib/lib[^/]*%.d%.ts$") then
		return "TypeScript/JavaScript standard library declarations"
	end

	-- Cover common user-space runtime managers, including inactive runtimes that
	-- cannot be found by querying the currently selected executable.
	if path:match("/%.rustup/toolchains/") then
		return "rustup toolchain and standard library"
	end
	if path:match("/%.pyenv/versions/[^/]+/lib/python[^/]+/") then
		return "pyenv Python standard library"
	end
	if path:match("/%.rbenv/versions/[^/]+/lib/ruby/") then
		return "rbenv Ruby standard library"
	end
	if path:match("/%.asdf/installs/") or path:match("/%.local/share/mise/installs/") then
		return "version-manager runtime installation"
	end

	return nil
end

local function reason_for_path(path)
	path = normalized(path)
	if not path then
		return nil
	end

	local special_reason = special_path_reason(path)
	if special_reason then
		return special_reason
	end

	for _, item in ipairs(roots) do
		if is_within(path, item.path) then
			return item.label
		end
	end

	return nil
end

local function reason_for_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
		return nil
	end
	return reason_for_path(vim.api.nvim_buf_get_name(bufnr))
end

local function protect(bufnr, notify)
	local reason = reason_for_buffer(bufnr)
	if not reason then
		return false
	end

	vim.b[bufnr].stdlib_guard_reason = reason
	vim.bo[bufnr].readonly = true
	vim.bo[bufnr].modifiable = false

	if notify and not vim.b[bufnr].stdlib_guard_notified then
		vim.b[bufnr].stdlib_guard_notified = true
		vim.notify("Protected by stdlib guard: " .. reason, vim.log.levels.INFO)
	end
	return true
end

-- Probes run synchronously and lazily: the first time a buffer of a given
-- filetype appears, the matching runtime is queried once and the discovered
-- paths take effect immediately. Synchronous by design so there is no window
-- where a standard-library file is writable while detection is still pending.
local function start_probe(name)
	if probe_state[name] then
		return
	end
	probe_state[name] = "done"

	local probe = probes[name]
	if not probe or vim.fn.executable(probe.argv[1]) ~= 1 then
		return
	end

	local ok, result = pcall(function()
		return vim.system(probe.argv, { text = true, timeout = 2000 }):wait()
	end)
	if not ok or result.code ~= 0 or result.signal ~= 0 then
		vim.notify(("Stdlib guard: failed to detect %s"):format(probe.label), vim.log.levels.WARN)
		return
	end

	for _, path in ipairs(output_lines(result.stdout)) do
		add_root(probe.label, path)
	end
end

local function probe_for_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	for _, name in ipairs(probes_by_filetype[vim.bo[bufnr].filetype] or {}) do
		start_probe(name)
	end
end

local function reset_discovery()
	probe_state = {}
	discover_static_roots()
end

function M.is_protected(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local reason = reason_for_buffer(bufnr)
	return reason ~= nil, reason
end

function M.setup()
	reset_discovery()

	local group = vim.api.nvim_create_augroup(group_name, { clear = true })
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter", "FileType" }, {
		group = group,
		desc = "Make language standard libraries immutable",
		callback = function(args)
			probe_for_buffer(args.buf)
			protect(args.buf, args.event ~= "BufEnter")
		end,
	})
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group,
		desc = "Block writes to language standard libraries",
		callback = function(args)
			probe_for_buffer(args.buf)
			-- args.file is the actual write target; `:write {file}` can point
			-- at a protected path from an unprotected buffer.
			local reason = reason_for_path(args.file) or reason_for_buffer(args.buf)
			if reason then
				protect(args.buf, false)
				error("Stdlib guard blocked this write: " .. reason)
			end
		end,
	})
	vim.api.nvim_create_autocmd("OptionSet", {
		group = group,
		pattern = { "modifiable", "readonly" },
		desc = "Keep language standard libraries immutable",
		callback = function(args)
			protect(args.buf, false)
		end,
	})

	vim.api.nvim_create_user_command("StdlibGuardInfo", function()
		local protected, reason = M.is_protected()
		if protected then
			vim.notify("Protected by stdlib guard: " .. reason, vim.log.levels.INFO)
		else
			vim.notify("Current buffer is not a detected standard-library file", vim.log.levels.INFO)
		end
	end, { desc = "Show standard-library protection status", force = true })

	vim.api.nvim_create_user_command("StdlibGuardRefresh", function()
		reset_discovery()
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			probe_for_buffer(bufnr)
			protect(bufnr, false)
		end
		vim.notify("Standard-library paths refreshed for active filetypes", vim.log.levels.INFO)
	end, { desc = "Refresh detected standard-library paths", force = true })

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		probe_for_buffer(bufnr)
		protect(bufnr, false)
	end
end

return M
