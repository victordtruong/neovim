# neovim

My personal Neovim configuration — a single `init.lua`, lazy.nvim based,
designed to drop onto any machine and be ready in a couple of minutes.

## Quick start

The config bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) on its own,
so on any new computer you just need this repo in Neovim's config directory.

### One-liner (recommended)

Back up any existing config (skip if you don't have one), then clone straight
into the config directory and launch:

```sh
if [ -e ~/.config/nvim ]; then mv ~/.config/nvim ~/.config/nvim.backup-$(date +%Y%m%d-%H%M%S); fi
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

Or run the installer straight from the web, no clone needed:

```sh
curl -fsSL https://raw.githubusercontent.com/victordtruong/neovim/main/install.sh | bash
```

### Windows

If Neovim and git are already installed, back up any existing config, then
clone straight into the config directory and launch:

```powershell
if (Test-Path $env:LOCALAPPDATA\nvim) { Rename-Item $env:LOCALAPPDATA\nvim "nvim.backup-$(Get-Date -Format yyyyMMdd-HHmmss)" }
git clone https://github.com/victordtruong/neovim.git $env:LOCALAPPDATA\nvim
nvim
```

Starting from scratch? This PowerShell one-liner installs Neovim and the
whole recommended toolchain via `winget`, clones the config into
`%LOCALAPPDATA%\nvim`, refreshes `PATH`, and launches Neovim (Windows 10
1809+ / Windows 11):

```powershell
foreach ($p in 'Neovim.Neovim','Git.Git','BurntSushi.ripgrep.MSVC','sharkdp.fd','OpenJS.NodeJS.LTS','EclipseAdoptium.Temurin.17.JDK') { winget install -e --id $p --silent --accept-package-agreements --accept-source-agreements }; git clone https://github.com/victordtruong/neovim.git $env:LOCALAPPDATA\nvim; $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User'); nvim
```

Or the equivalent scripted installer, which also backs up any existing
Neovim config/data and does a headless plugin sync before first launch:

```powershell
iwr -useb https://raw.githubusercontent.com/victordtruong/neovim/main/windows-install.ps1 | iex
```

Prereqs: `winget` (bundled with modern Windows; if missing, install *App
Installer* from the Microsoft Store) and PowerShell (not `cmd.exe`).

## Prerequisites

**Required**

- **Neovim 0.11+** (uses `vim.lsp.config` for LSP setup)
- **git**

**Recommended** (features degrade gracefully without them)

- **ripgrep** (`rg`) — Telescope live grep / grep-string
- **fd** — faster Telescope file finding
- A **C compiler** (`gcc`/`clang`) + **make** — building treesitter parsers
- **Node.js** + **npm** — many Mason-managed language servers
- **JDK 17+** (`java`) — `kotlin_language_server` and other JVM servers
- **unzip**, **curl** — Mason downloads

Quick installs:

```sh
# macOS (Homebrew)
brew install neovim ripgrep fd node openjdk@17

# Debian / Ubuntu
sudo apt install neovim ripgrep fd-find build-essential nodejs npm openjdk-17-jdk

# Arch
sudo pacman -S neovim ripgrep fd base-devel nodejs npm jdk17-openjdk
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

The whole configuration is one file. `init.lua` reads top to bottom:

```
1. Leader keys        -- set before anything that uses <leader>
2. Options            -- numbers, indent, search, undo, clipboard
3. Core keymaps       -- file explorer, diagnostic navigation
4. lazy.nvim bootstrap
5. Plugins            -- colorschemes, Telescope, treesitter, LSP stack
```

Everything else in the repo is supporting material: `lazy-lock.json` pins
plugin versions, and `install.sh` / `windows-install.ps1` are the optional
installers.
