vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Line numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Column marker
vim.opt.colorcolumn = "80"

-- True colors, required by tokyonight / rose-pine to render correctly
vim.opt.termguicolors = true

-- Search
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- UI
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.updatetime = 50

-- Persistent undo instead of a swapfile / backup
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true

-- Share the system clipboard
vim.opt.clipboard = "unnamedplus"

-- Diagnostic navigation
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
