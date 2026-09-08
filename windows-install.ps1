<#
.SYNOPSIS
    Installer for this Neovim configuration on Windows.

.DESCRIPTION
    Installs Neovim and the recommended toolchain via winget, backs up
    any existing Neovim config/data/state/cache, places this
    configuration at %LOCALAPPDATA%\nvim, and syncs plugins headlessly
    so the first real launch is instant.

.EXAMPLE
    # From a local clone of this repo:
    .\windows-install.ps1

.EXAMPLE
    # Fresh machine, remote install (repo must be public):
    iwr -useb https://raw.githubusercontent.com/victordtruong/neovim/main/windows-install.ps1 | iex
#>

[CmdletBinding()]
param(
    [string]$RepoUrl = 'https://github.com/victordtruong/neovim.git'
)

$ErrorActionPreference = 'Stop'

# --- pretty output helpers --------------------------------------------------
function Write-Info  ($m) { Write-Host "==> $m" -ForegroundColor Green }
function Write-Warn2 ($m) { Write-Host "==> $m" -ForegroundColor Yellow }
function Write-Err2  ($m) { Write-Host "==> $m" -ForegroundColor Red }

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Update-PathFromEnvironment {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

# --- winget bootstrap -------------------------------------------------------
if (-not (Test-Command winget)) {
    Write-Err2 "winget was not found on this machine."
    Write-Err2 "Install 'App Installer' from the Microsoft Store, then re-run this script."
    exit 1
}

# --- install the recommended toolchain --------------------------------------
# Each entry: winget package id + the command it provides once installed.
$packages = @(
    @{ Id = 'Neovim.Neovim';                   Cmd = 'nvim' }
    @{ Id = 'Git.Git';                         Cmd = 'git'  }
    @{ Id = 'BurntSushi.ripgrep.MSVC';         Cmd = 'rg'   }
    @{ Id = 'sharkdp.fd';                      Cmd = 'fd'   }
    @{ Id = 'OpenJS.NodeJS.LTS';               Cmd = 'node' }
    @{ Id = 'EclipseAdoptium.Temurin.17.JDK';  Cmd = 'java' }
)

Write-Info "Checking / installing tools via winget"
foreach ($pkg in $packages) {
    if (Test-Command $pkg.Cmd) {
        Write-Host ("  [ok]   {0} ({1})" -f $pkg.Cmd, $pkg.Id)
        continue
    }
    Write-Host ("  [inst] {0} ({1})" -f $pkg.Cmd, $pkg.Id)
    winget install -e --id $pkg.Id --silent `
        --accept-package-agreements --accept-source-agreements | Out-Null
}

# Refresh PATH so freshly-installed tools are visible in this session.
Update-PathFromEnvironment

foreach ($pkg in $packages) {
    if (-not (Test-Command $pkg.Cmd)) {
        Write-Warn2 ("Command '{0}' still not on PATH after installing {1}." -f $pkg.Cmd, $pkg.Id)
        Write-Warn2  "You may need to open a new PowerShell window before the first run."
    }
}

if (-not (Test-Command git))  { Write-Err2 "git is required. Aborting."; exit 1 }
if (-not (Test-Command nvim)) { Write-Err2 "nvim is required. Aborting."; exit 1 }

# --- paths ------------------------------------------------------------------
$configDir = Join-Path $env:LOCALAPPDATA 'nvim'
$dataDir   = Join-Path $env:LOCALAPPDATA 'nvim-data'
$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'

function Backup-IfPresent($path) {
    if (Test-Path -LiteralPath $path) {
        $backup = "$path.backup-$stamp"
        Write-Warn2 "Backing up existing $path -> $backup"
        Move-Item -LiteralPath $path -Destination $backup
    }
}

# If the config dir is already this repo, update in place.
$existingRemote = $null
if ((Test-Path (Join-Path $configDir '.git')) -and (Test-Command git)) {
    $existingRemote = (git -C $configDir remote get-url origin 2>$null)
}

if ($existingRemote -and $existingRemote -match 'victordtruong/neovim') {
    Write-Info "Existing install detected at $configDir — updating"
    git -C $configDir pull --ff-only
} else {
    Write-Info "Preparing a clean install"
    Backup-IfPresent $configDir
    Backup-IfPresent $dataDir

    # $MyInvocation.MyCommand.Path is null when invoked via `iwr | iex`; in
    # that case there is no local checkout to copy from, so always clone.
    $scriptDir = if ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else { $null }
    if ($scriptDir -and
        (Test-Path (Join-Path $scriptDir 'init.lua')) -and
        (Test-Path (Join-Path $scriptDir 'lazy-lock.json'))) {
        Write-Info "Copying config from $scriptDir -> $configDir"
        New-Item -ItemType Directory -Force -Path $configDir | Out-Null
        # Copy tracked contents; skip .git so the deploy is not a working tree.
        Get-ChildItem -LiteralPath $scriptDir -Force |
            Where-Object { $_.Name -ne '.git' } |
            ForEach-Object {
                Copy-Item -LiteralPath $_.FullName -Destination $configDir -Recurse -Force
            }
    } else {
        Write-Info "Cloning $RepoUrl -> $configDir"
        git clone $RepoUrl $configDir
    }
}

# --- sync plugins -----------------------------------------------------------
Write-Info "Syncing plugins (this may take a minute on first run)"
$proc = Start-Process -FilePath nvim `
    -ArgumentList '--headless','+Lazy! sync','+qa' `
    -NoNewWindow -PassThru -Wait
if ($proc.ExitCode -eq 0) {
    Write-Info "Plugins synced"
} else {
    Write-Warn2 "Headless plugin sync did not complete; plugins will install on first launch."
}

Write-Info "Done. Launch Neovim with: nvim"
