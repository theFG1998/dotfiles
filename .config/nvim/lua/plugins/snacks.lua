local diagnostic_picker = {
  actions = {
    yank_diagnostic = {
      action = "yank",
      field = "text",
      reg = "+",
      desc = "Copy diagnostic",
    },
  },
  win = {
    input = {
      keys = {
        ["<C-y>"] = { "yank_diagnostic", mode = { "n", "i" } },
      },
    },
    list = {
      keys = {
        ["y"] = "yank_diagnostic",
      },
    },
  },
}

local project_markers = {
  ".git",
  "package.json",
  "pyproject.toml",
  "uv.lock",
  "go.mod",
  "Cargo.toml",
  "Makefile",
}

local function project_root()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)

  if path ~= "" and vim.bo[buf].buftype == "" then
    local root = vim.fs.root(path, project_markers)
    if root then
      return root
    end

    local lsp_root
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      local client_root = client.config.root_dir
      if client_root and (not lsp_root or #client_root > #lsp_root) then
        lsp_root = client_root
      end
    end
    if lsp_root then
      return lsp_root
    end
  end

  return vim.fn.getcwd(0)
end

local function toggle_project_terminal()
  Snacks.terminal(nil, { cwd = project_root() })
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = false },
      input = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      picker = {
        enabled = true,
        sources = {
          diagnostics = diagnostic_picker,
          diagnostics_buffer = diagnostic_picker,
        },
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      styles = {
        notification = {
          -- wo = { wrap = true } -- Wrap notifications
        }
      }
    },
    keys = {
      { "<leader><space>", function() Snacks.picker.smart() end,            desc = "Smart Find Files" },
      { "<leader>/",       function() Snacks.picker.grep() end,             desc = "Grep" },
      { "<leader>ff",      function() Snacks.picker.files() end,            desc = "Find Files" },
      { "<leader>fg",      function() Snacks.picker.git_files() end,        desc = "Find Git Files" },
      { "<leader>fp",      function() Snacks.picker.projects() end,         desc = "Projects" },
      { "<leader>sr",      function() Snacks.picker.recent() end,           desc = "Recent" },
      { "<leader>su",      function() Snacks.picker.undo() end,             desc = "Undo History" },
      { "<leader>sm",      function() Snacks.picker.marks() end,            desc = "Marks" },
      { "<leader>si",      function() Snacks.picker.icons() end,            desc = "Icons" },
      { "<leader>sb",      function() Snacks.picker.buffers() end,          desc = "Buffers" },
      { "<leader>sd",      function() Snacks.picker.diagnostics() end,      desc = "Diagnostics" },
      { "<leader>sD",      function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      { "<leader>cR",      function() Snacks.rename.rename_file() end,      desc = "Rename File" },
      {
        "<c-/>",
        toggle_project_terminal,
        desc = "Toggle Project Terminal",
      },
      {
        -- tmux may encode Ctrl-/ as the legacy Ctrl-_ control character.
        "<c-_>",
        toggle_project_terminal,
        desc = "which_key_ignore",
      },
      { "]]",              function() Snacks.words.jump(vim.v.count1) end,  desc = "Next Reference",       mode = { "n", "t" } },
      { "[[",              function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference",       mode = { "n", "t" } },
      { "<leader>.",       function() Snacks.scratch() end,                 desc = "Toggle Scratch Buffer" },
      { "<leader>S",       function() Snacks.scratch.select() end,          desc = "Select Scratch Buffer" },
      { "<leader>n",       function() Snacks.notifier.show_history() end,   desc = "Notification History" },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          -- selene: allow(global_usage)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          -- selene: allow(global_usage)
          _G.bt = function()
            Snacks.debug.backtrace()
          end

          -- Override print to use snacks for `:=` command (blue info style)
          local function notify_info(...)
            local len = select("#", ...)
            local obj = { ... }
            local lines = vim.split(vim.inspect(len == 1 and obj[1] or len > 0 and obj or nil), "\n")
            Snacks.notify.info(lines, { title = "Eval", ft = "lua" })
          end
          if vim.fn.has("nvim-0.11") == 1 then
            ---@diagnostic disable-next-line: duplicate-set-field
            vim._print = function(_, ...)
              notify_info(...)
            end
          else
            vim.print = notify_info
          end
        end,
      })
    end,
  }
}
