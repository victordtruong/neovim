# neovim

My personal Neovim configuration — lazy.nvim based, designed to drop onto any
machine and be ready in a couple of minutes.

## Quick start

The config bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) on its own,
so on any new computer you just need this repo in Neovim's config directory.

### One-liner (recommended)

Clone straight into the config directory and launch:

```sh
git clone https://github.com/victordtruong/neovim.git ~/.config/nvim && nvim
```

On first launch lazy.nvim installs every plugin and Mason installs the language
servers. Wait for it to finish, then restart Neovim.

> Using SSH? Swap the URL for `git@github.com:victordtruong/neovim.git`.

### Install script

If you already have a Neovim setup you don't want to clobber, use the installer
instead — it **backs up** any existing config/data/state/cache, checks your
tools, and syncs plugins for you:

```sh
git clone https://github.com/victordtruong/neovim.git ~/nvim-config
cd ~/nvim-config
./install.sh
```

Re-running `./install.sh` later updates an existing install in place.

## Prerequisites

**Required**

- **Neovim 0.10+**
- **git**

**Recommended** (features degrade gracefully without them)

- **ripgrep** (`rg`) — Telescope live grep / grep-string
- **fd** — faster Telescope file finding
- A **C compiler** (`gcc`/`clang`) + **make** — building treesitter parsers
- **Node.js** + **npm** — many Mason-managed language servers
- **unzip**, **curl** — Mason downloads

Quick installs:

```sh
# macOS (Homebrew)
brew install neovim ripgrep fd node

# Debian / Ubuntu
sudo apt install neovim ripgrep fd-find build-essential nodejs npm

# Arch
sudo pacman -S neovim ripgrep fd base-devel nodejs npm
```

## Config directory by OS

The clone target `~/.config/nvim` is correct for Linux and macOS. On Windows,
clone into `~/AppData/Local/nvim` instead.

## What's included

- **Plugin manager:** lazy.nvim (self-bootstrapping)
- **LSP:** nvim-lspconfig + Mason (`lua_ls` installed by default), conform.nvim
  for formatting, nvim-cmp completion, LuaSnip, fidget.nvim
- **Fuzzy finding:** Telescope
- **Syntax:** nvim-treesitter (lua, bash, java, kotlin, jsdoc, vimdoc, templ, …)
- **Colorschemes:** tokyonight (default) and rose-pine

Plugin versions are pinned in [`lazy-lock.json`](./lazy-lock.json) so every
machine gets the same set. Run `:Lazy update` and commit the updated lockfile to
bump them everywhere.

## Keymaps

Leader is `<Space>`.

| Mapping        | Action                          |
| -------------- | ------------------------------- |
| `<leader>pv`   | Open file explorer (`:Ex`)      |
| `<leader>ff`   | Telescope: find files           |
| `<leader>fg`   | Telescope: live grep            |
| `<leader>fb`   | Telescope: buffers              |
| `<leader>fh`   | Telescope: help tags            |
| `<leader>ps`   | Telescope: grep for a prompt    |

## Layout

```
init.lua                 -> require("vtruong")
lua/vtruong/
  init.lua               -> loads remap + lazy
  remap.lua              -> options & keymaps
  lazy_init.lua          -> bootstraps and configures lazy.nvim
  lazynvim/              -> plugin specs
    colors.lua
    lsp.lua
    telescope.lua
    treesitter.lua
```
