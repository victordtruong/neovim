-- ============================================================================
-- Neovim configuration — single file.
--
-- Layout of this file:
--   1. Leader keys      (must come before anything that uses <leader>)
--   2. Options
--   3. Core keymaps
--   4. lazy.nvim bootstrap
--   5. Plugins
--
-- Requires Neovim 0.11+ (uses vim.lsp.config).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Leader keys
--    Set before lazy.nvim loads so plugin mappings resolve correctly.
-- ----------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ----------------------------------------------------------------------------
-- 2. Options
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- 3. Core keymaps
--    Plugin-specific maps live with their plugin spec in section 5.
-- ----------------------------------------------------------------------------
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Open file explorer" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

-- ----------------------------------------------------------------------------
-- 4. lazy.nvim bootstrap
--    Clones lazy.nvim on first launch so a bare `git clone` of this repo is
--    all that is needed on a new machine.
-- ----------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local out = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- ----------------------------------------------------------------------------
-- 5. Plugins
-- ----------------------------------------------------------------------------
require("lazy").setup({

    -- ---- Colorschemes ------------------------------------------------------
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000, -- load before other plugins so highlights are set early
        config = function()
            vim.cmd.colorscheme("tokyonight-night")
        end,
    },
    {
        -- Available via `:colorscheme rose-pine`; tokyonight stays the default.
        "rose-pine/neovim",
        name = "rose-pine",
        lazy = true,
        opts = {
            disable_background = true,
            styles = { italic = false },
        },
    },

    -- ---- Fuzzy finding -----------------------------------------------------
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup({})
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
            vim.keymap.set("n", "<leader>ps", function()
                builtin.grep_string({ search = vim.fn.input("Grep > ") })
            end, { desc = "Telescope grep for prompt" })
        end,
    },

    -- ---- Syntax / treesitter -----------------------------------------------
    {
        "nvim-treesitter/nvim-treesitter",
        -- The `main` branch is a full incompatible rewrite that removed
        -- `nvim-treesitter.configs`, `ensure_installed`, `:TSInstall {lang}`,
        -- etc. Stay on `master` (locked, but supported for Nvim 0.11
        -- back-compat) until this config is ported to the new API.
        branch = "master",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "vimdoc", "java", "kotlin", "lua", "jsdoc", "bash",
                },
                sync_install = false,
                -- Install missing parsers when entering a buffer.
                auto_install = true,
                indent = { enable = true },
                highlight = {
                    enable = true,
                    disable = function(lang, buf)
                        if lang == "html" then
                            return true
                        end
                        -- Skip treesitter on very large files.
                        local max_filesize = 100 * 1024 -- 100 KB
                        local ok, stats =
                            pcall((vim.uv or vim.loop).fs_stat, vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            vim.notify(
                                "File larger than 100KB, treesitter disabled for performance",
                                vim.log.levels.WARN,
                                { title = "Treesitter" }
                            )
                            return true
                        end
                    end,
                    additional_vim_regex_highlighting = { "markdown" },
                },
            })

            -- templ (Go templating) ships no upstream parser; register it here.
            require("nvim-treesitter.parsers").get_parser_configs().templ = {
                install_info = {
                    url = "https://github.com/vrischmann/tree-sitter-templ.git",
                    files = { "src/parser.c", "src/scanner.c" },
                    branch = "master",
                },
            }
            vim.treesitter.language.register("templ", "templ")
        end,
    },

    -- ---- LSP, completion, formatting ---------------------------------------
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "stevearc/conform.nvim",
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "j-hui/fidget.nvim",
        },
        config = function()
            -- Formatting -----------------------------------------------------
            require("conform").setup({
                formatters_by_ft = {
                    lua = { "stylua" },
                },
                format_on_save = {
                    lsp_fallback = true,
                    timeout_ms = 1000,
                },
            })
            vim.keymap.set({ "n", "v" }, "<leader>f", function()
                require("conform").format({ async = true, lsp_fallback = true })
            end, { desc = "Format buffer" })

            -- LSP keymaps, bound per-buffer when a server attaches ------------
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
                callback = function(event)
                    local map = function(keys, fn, desc)
                        vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
                    end
                    map("gd", vim.lsp.buf.definition, "Go to definition")
                    map("gD", vim.lsp.buf.declaration, "Go to declaration")
                    map("gi", vim.lsp.buf.implementation, "Go to implementation")
                    map("gr", vim.lsp.buf.references, "References")
                    map("K", vim.lsp.buf.hover, "Hover")
                    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
                    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
                    map("<leader>D", vim.lsp.buf.type_definition, "Type definition")
                    vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help,
                        { buffer = event.buf, desc = "LSP: Signature help" })
                end,
            })

            -- Completion -----------------------------------------------------
            local cmp = require("cmp")
            local cmp_select = { behavior = cmp.SelectBehavior.Select }
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
                    ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                }),
            })

            -- Servers --------------------------------------------------------
            require("fidget").setup({})
            require("mason").setup()

            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                require("cmp_nvim_lsp").default_capabilities()
            )

            -- Defaults for every server; per-server blocks merge over these.
            vim.lsp.config("*", { capabilities = capabilities })

            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = { version = "Lua 5.1" },
                        diagnostics = {
                            globals = {
                                "bit", "vim", "it", "describe", "before_each", "after_each",
                            },
                        },
                    },
                },
            })

            vim.lsp.config("kotlin_language_server", {
                root_markers = {
                    "settings.gradle", "settings.gradle.kts",
                    "build.gradle", "build.gradle.kts",
                    "pom.xml", ".git",
                },
            })

            vim.lsp.config("zls", {
                root_markers = { ".git", "build.zig", "zls.json" },
                settings = {
                    zls = {
                        enable_inlay_hints = true,
                        enable_snippets = true,
                        warn_style = true,
                    },
                },
            })
            vim.g.zig_fmt_parse_errors = 0
            vim.g.zig_fmt_autosave = 0

            -- mason-lspconfig v2 auto-enables installed servers through
            -- vim.lsp.enable, honoring the vim.lsp.config values above.
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "kotlin_language_server" },
                automatic_enable = true,
            })

            -- Diagnostics ----------------------------------------------------
            vim.diagnostic.config({
                float = {
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            })
        end,
    },

}, {
    install = { colorscheme = { "tokyonight-night", "habamax" } },
    checker = { enabled = true },
    change_detection = { notify = false },
})
