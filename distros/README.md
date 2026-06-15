# 🌸 Sakura Distros - Build Guide

Build your own Sakura Linux distros for WSL.

## Quick Build

```bash
# Build a single distro
cd ubuntu-sakura
docker build -t ubuntu-sakura .
docker export $(docker create ubuntu-sakura) | gzip > ubuntu-sakura.tar.gz

# Import to WSL
wsl --import Ubuntu-Sakura C:\WSL\Ubuntu-Sakura ubuntu-sakura.tar.gz
```

## Build All

```powershell
.\build-all.ps1
```

## What Each Distro Includes

Every Sakura distro comes with:
- 🌸 Sakura-themed bash prompt (pink cherry blossom colors)
- 📦 Pre-installed dev tools: curl, wget, git, nodejs, npm, python3, pip
- 🔧 Build essentials: gcc, make, etc.
- 📝 Editors: vim, neovim
- 🔍 Modern CLI tools: ripgrep, fd, fzf, bat, zoxide
- 📊 System tools: htop, tmux, tree
- 🐙 GitHub CLI (gh)
- 🎨 Custom tmux theme
- 📋 Pre-configured git

## Distros

| Distro | Base | Package Manager |
|--------|------|-----------------|
| ubuntu-sakura | Ubuntu 24.04 | apt |
| arch-sakura | Arch Linux | pacman |
| fedora-sakura | Fedora 40 | dnf |
| alpine-sakura | Alpine 3.20 | apk |
| debian-sakura | Debian 12 | apt |
| void-sakura | Void Linux | xbps |

## Customization

Edit `setup.sh` in each distro folder to customize:
- Installed packages
- Shell config (.bashrc, .zshrc)
- Neovim config
- Tmux theme
- MOTD message
