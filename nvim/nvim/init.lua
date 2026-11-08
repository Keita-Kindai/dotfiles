-- Minimal Neovim config for competitive programming.
-- No plugins. Everything else is Neovim's default.

vim.g.mapleader = " "

-- Options ---------------------------------------------------------------
local o = vim.opt
o.number = true            -- absolute line numbers (no relativenumber)
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.expandtab = true
o.ignorecase = true
o.smartcase = true
o.undofile = true
o.signcolumn = "yes"       -- keep text from shifting when diagnostics appear
o.clipboard = "unnamedplus" -- yank/paste via the system clipboard
if vim.fn.has("wsl") == 1 and vim.fn.executable("win32yank.exe") == 1 then
  -- WSL: share the clipboard with Windows.
  vim.g.clipboard = {
    name = "win32yank",
    copy = { ["+"] = "win32yank.exe -i --crlf", ["*"] = "win32yank.exe -i --crlf" },
    paste = { ["+"] = "win32yank.exe -o --lf", ["*"] = "win32yank.exe -o --lf" },
    cache_enabled = 0,
  }
end
o.completeopt = { "menu", "menuone", "noselect" } -- Enter never auto-accepts
o.pumheight = 10

-- Transparent background (the terminal's background shows through).
local function transparent()
  for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "FloatBorder",
                           "SignColumn", "LineNr", "EndOfBuffer" }) do
    vim.api.nvim_set_hl(0, group, { bg = "NONE", fg = vim.api.nvim_get_hl(0, { name = group }).fg })
  end
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = transparent })
transparent()

-- Diagnostics: show the message at the end of the line.
vim.diagnostic.config({ virtual_text = true, severity_sort = true })

-- LSP (clangd, built-in client) -------------------------------------------
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--header-insertion=never",       -- never add #include lines on completion
    "--function-arg-placeholders=0",  -- complete "push_back(" only, no arg snippets
  },
  filetypes = { "c", "cpp" },
  root_markers = { "compile_flags.txt", ".clangd", ".git" },
})
vim.lsp.enable("clangd")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or not client:supports_method("textDocument/completion") then
      return
    end
    -- Pop up completion only after ".", "->" and "::" (e.g. v.push_back).
    local cp = client.server_capabilities.completionProvider
    if cp then
      cp.triggerCharacters = { ".", ">", ":" }
    end
    vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
  end,
})

-- Ctrl-Space: open completion manually.
vim.keymap.set("i", "<C-Space>", function() vim.lsp.completion.get() end)
-- Tab / Shift-Tab: move in the completion menu.
vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })
vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })

-- Competitive programming -------------------------------------------------
-- Run a command in a terminal split, in the directory of the current file.
local function run_in_term(cmd)
  vim.cmd("silent! write")
  local dir = vim.fn.expand("%:p:h")
  vim.cmd("botright 15split | enew")
  vim.fn.jobstart(cmd, { term = true, cwd = dir })
  vim.cmd("startinsert")
end

-- F5: build and test against samples (test/*.in). F6: build and run with stdin.
vim.keymap.set("n", "<F5>", function() run_in_term({ "cpt" }) end, { desc = "Build + oj test" })
vim.keymap.set("n", "<F6>", function()
  run_in_term({ "sh", "-c", "cp-build main.cpp a.out && ./a.out" })
end, { desc = "Build + run" })

-- F8: test and submit (cps) the problem in the current file's directory.
vim.keymap.set("n", "<F8>", function() run_in_term({ "cps" }) end, { desc = "Test + submit" })

-- Switch problems inside contests/<contest>/<task>/main.cpp.
--   :P b         open problem b
--   <Space>n/p   next / previous problem
local function problems()
  local contest = vim.fn.expand("%:p:h:h")
  local names = {}
  for name, kind in vim.fs.dir(contest) do
    if kind == "directory" and vim.uv.fs_stat(contest .. "/" .. name .. "/main.cpp") then
      table.insert(names, name)
    end
  end
  table.sort(names)
  return contest, names
end

local function open_problem(name)
  local contest = problems()
  local file = contest .. "/" .. name .. "/main.cpp"
  if not vim.uv.fs_stat(file) then
    vim.notify("no problem: " .. name, vim.log.levels.WARN)
    return
  end
  vim.cmd("silent! update")
  vim.cmd.edit(vim.fn.fnameescape(file))
  vim.cmd.cd(vim.fn.fnameescape(contest .. "/" .. name)) -- so :!cps uses this problem
end

local function step_problem(delta)
  local _, names = problems()
  local current = vim.fn.expand("%:p:h:t")
  for i, name in ipairs(names) do
    if name == current and names[i + delta] then
      return open_problem(names[i + delta])
    end
  end
end

vim.api.nvim_create_user_command("P", function(opts) open_problem(opts.args:lower()) end, {
  nargs = 1,
  complete = function(arglead)
    local _, names = problems()
    return vim.tbl_filter(function(n) return vim.startswith(n, arglead) end, names)
  end,
})
vim.keymap.set("n", "<leader>n", function() step_problem(1) end, { desc = "Next problem" })
vim.keymap.set("n", "<leader>p", function() step_problem(-1) end, { desc = "Previous problem" })

-- :Lib NAME  inserts a library from icpc-kit/my-library before int main().
local lib_cmd = (vim.env.ICPC_KIT or vim.fn.expand("~/CP/icpc-kit")) .. "/bin/lib"
vim.api.nvim_create_user_command("Lib", function(opts)
  vim.cmd("silent! write")
  local cmd = vim.list_extend({ lib_cmd }, opts.fargs)
  local res = vim.system(cmd, { cwd = vim.fn.expand("%:p:h"), text = true }):wait()
  vim.cmd("checktime")
  vim.notify(vim.trim((res.stdout or "") .. (res.stderr or "")))
end, {
  nargs = "+",
  complete = function(arglead)
    local out = vim.system({ lib_cmd, "--list" }, { text = true }):wait().stdout or ""
    local names = {}
    for name in out:gmatch("(%S+)[^\n]*\n") do
      if vim.startswith(name, arglead) then
        table.insert(names, name)
      end
    end
    return names
  end,
})

-- Terminal: Esc leaves terminal mode.
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])
