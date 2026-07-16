#!/usr/bin/env bash
#
# Installer for this Neovim configuration.
#
# It will:
#   1. Check for required and recommended tools.
#   2. Back up any existing Neovim config/data/state/cache.
#   3. Place this configuration at your Neovim config directory.
#   4. Optionally sync plugins headlessly so the first launch is instant.
#
# Usage (from a clone of this repo):
#   ./install.sh
#
# Usage (fresh machine, clones for you):
#   NVIM_CONFIG_REPO=https://github.com/victordtruong/neovim.git ./install.sh
#
set -euo pipefail

REPO_URL="${NVIM_CONFIG_REPO:-https://github.com/victordtruong/neovim.git}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
STAMP="$(date +%Y%m%d-%H%M%S)"

# --- pretty output helpers ---------------------------------------------------
bold=$(tput bold 2>/dev/null || true)
red=$(tput setaf 1 2>/dev/null || true)
green=$(tput setaf 2 2>/dev/null || true)
yellow=$(tput setaf 3 2>/dev/null || true)
reset=$(tput sgr0 2>/dev/null || true)

info()  { printf '%s==>%s %s\n' "$green$bold" "$reset" "$*"; }
warn()  { printf '%s==>%s %s\n' "$yellow$bold" "$reset" "$*"; }
err()   { printf '%s==>%s %s\n' "$red$bold" "$reset" "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# --- prerequisite checks -----------------------------------------------------
info "Checking prerequisites"

missing_required=()
for tool in git nvim; do
  if have "$tool"; then
    printf '  [ok]   %s\n' "$tool"
  else
    printf '  [MISS] %s (required)\n' "$tool"
    missing_required+=("$tool")
  fi
done

# Recommended tools. Not fatal, but the config leans on them:
#   ripgrep  -> Telescope live_grep / grep_string
#   fd       -> faster Telescope find_files
#   cc/make  -> building nvim-treesitter parsers
#   node/npm -> many Mason-managed language servers
#   java     -> JDK 17+ for kotlin_language_server (and other JVM servers)
#   unzip/curl -> Mason downloads
declare -a recommended=(rg fd make node npm java unzip curl)
declare -a missing_recommended=()
for tool in "${recommended[@]}"; do
  if have "$tool"; then
    printf '  [ok]   %s\n' "$tool"
  else
    printf '  [warn] %s (recommended)\n' "$tool"
    missing_recommended+=("$tool")
  fi
done

# A C compiler for treesitter (any of these will do).
if have cc || have gcc || have clang; then
  printf '  [ok]   C compiler\n'
else
  printf '  [warn] C compiler (recommended, for treesitter)\n'
  missing_recommended+=("a C compiler (gcc/clang)")
fi

if [ "${#missing_required[@]}" -gt 0 ]; then
  err "Missing required tools: ${missing_required[*]}"
  err "Install them and re-run. Neovim 0.11+ is required."
  exit 1
fi

if [ "${#missing_recommended[@]}" -gt 0 ]; then
  warn "Missing recommended tools: ${missing_recommended[*]}"
  warn "The config will still load; some features (fuzzy grep, LSP installs, treesitter builds) may be limited until you install them."
fi

# --- back up any existing Neovim directories ---------------------------------
backup_if_present() {
  local dir="$1"
  if [ -e "$dir" ] || [ -L "$dir" ]; then
    local backup="${dir}.backup-${STAMP}"
    warn "Backing up existing $dir -> $backup"
    mv "$dir" "$backup"
  fi
}

# If the config dir is already this repo, just update it in place instead.
if [ -d "$CONFIG_DIR/.git" ] && \
   git -C "$CONFIG_DIR" remote get-url origin 2>/dev/null | grep -q "victordtruong/neovim"; then
  info "Existing install detected at $CONFIG_DIR — updating"
  git -C "$CONFIG_DIR" pull --ff-only
else
  info "Preparing a clean install"
  backup_if_present "$CONFIG_DIR"
  backup_if_present "$DATA_DIR"
  backup_if_present "$STATE_DIR"
  backup_if_present "$CACHE_DIR"

  # If we're being run from inside a checkout of this repo, copy it in place;
  # otherwise clone from the remote.
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$script_dir/init.lua" ] && [ -d "$script_dir/lua/vtruong" ]; then
    info "Copying config from $script_dir -> $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    # Copy tracked files if it's a git repo, else copy everything sans .git.
    if [ -d "$script_dir/.git" ]; then
      git -C "$script_dir" archive HEAD | tar -x -C "$CONFIG_DIR"
    else
      cp -R "$script_dir/." "$CONFIG_DIR/"
      rm -rf "$CONFIG_DIR/.git"
    fi
  else
    info "Cloning $REPO_URL -> $CONFIG_DIR"
    git clone "$REPO_URL" "$CONFIG_DIR"
  fi
fi

# --- sync plugins ------------------------------------------------------------
info "Syncing plugins (this may take a minute on first run)"
if nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
  info "Plugins synced"
else
  warn "Headless plugin sync did not complete; plugins will install on first launch."
fi

info "Done. Launch Neovim with: ${bold}nvim${reset}"
