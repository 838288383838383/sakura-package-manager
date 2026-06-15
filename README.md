# 🌸 Sakura Package Manager

**Your friendly Windows package manager with a digital companion inside.**

Sakura is a modern, user-friendly package manager for Windows, inspired by Scoop but with a twist — it comes with a built-in Tamagotchi pet that grows and evolves as you use the package manager!

Use `sak` (short alias) or `sakura` — both work identically.

## ✨ Features

### Package Management
- 📦 **Simple package installation** - One command to install apps
- 🔄 **Easy updates** - Keep all your apps up to date
- 🗑️ **Clean uninstallation** - Remove apps without leaving traces
- 📋 **App search** - Find packages quickly
- 🔗 **Dependency resolution** - Automatic dependency handling
- 🏷️ **Bucket system** - Git-based package repositories
- 🔐 **Hash verification** - Secure package integrity checks
- 🛡️ **Isolated installs** - No conflicts, no admin required
- 🚂 **Built-in sl** - Choo choo!

### 🌸 Tamagotchi Pet System
Meet **Sakura-chan**, your digital companion!

- 🐣 **Evolution stages** - Watch your pet grow from Bud to Elder
- 💕 **Mood system** - Your pet reacts to how you treat it
- 🍽️ **Feed** - Keep your pet happy and healthy
- 🎮 **Play** - Play games to boost happiness
- 🐾 **Pet** - Show some love
- 😴 **Nap** - Let your pet rest
- 📊 **Stats tracking** - Track hunger, energy, happiness, health
- 🏆 **Achievements** - Unlock special milestones
- ⬆️ **Level up** - Earn XP for every action

## 🚀 Quick Start

### Installation

```powershell
# Clone the repo
git clone https://github.com/838288383838383/sakura-package-manager.git

# Run the installer
cd sakura-package-manager
.\install.ps1
```

Or use the one-liner:
```powershell
iex (iwr -useb https://raw.githubusercontent.com/838288383838383/sakura-package-manager/main/install.ps1).Content
```

### First Steps

```powershell
# Get help
sak help

# Meet your pet!
sak pet

# Add the community bucket
sak bucket add community

# Add nonportable apps (MSI/EXE)
sak bucket add nonportable

# Search for a package
sak search git

# Install a package
sak install git

# Install with LazyVim (auto-prompted)
sak install neovim

# Install a non-portable app
sak install vscode -viab nonportable

# Check your pet after installing
sak pet

# See a train (mistype on purpose!)
sak sl
```

## 📖 Commands

### Package Commands

| Command | Description |
|---------|-------------|
| `sak install <app>` | Install an application |
| `sak install <app> -viab <bucket>` | Install from specific bucket |
| `sak uninstall <app>` | Remove an application |
| `sak update [app]` | Check for updates |
| `sak update -sak` | Update Sakura itself |
| `sak upgrade` | Update all installed apps |
| `sak search <query>` | Search available packages |
| `sak list` | List installed apps |
| `sak info <app>` | Show app information |

### Bucket Commands

| Command | Description |
|---------|-------------|
| `sak bucket list` | List added buckets |
| `sak bucket add <name>` | Add a bucket (auto-clones from GitHub) |
| `sak bucket rm <name>` | Remove a bucket |

Built-in buckets:
- `community` - Community-maintained portable apps
- `nonportable` - MSI/EXE installer-based apps

### Pet Commands

| Command | Description |
|---------|-------------|
| `sak pet` | Show your pet's status |
| `sak pet feed` | Feed your pet |
| `sak pet play` | Play with your pet |
| `sak pet pet` | Pet your companion |
| `sak pet nap` | Let your pet rest |
| `sak pet evolve` | Check evolution progress |

### Self Update

| Command | Description |
|---------|-------------|
| `sak updt` | Update Sakura from GitHub |
| `sak update -sak` | Same thing, short form |

### Fun Commands

| Command | Description |
|---------|-------------|
| `sak sl` | All aboard! Choo choo! 🚂 |
| `sak train` | Same as sl |
| `sak choo` | Same as sl |

### Config Commands

| Command | Description |
|---------|-------------|
| `sak config get <key>` | Get a config value |
| `sak config set <key> <value>` | Set a config value |
| `sak config list` | Show all config |

## 🐱 Your Pet

### Species: Sakura Spirit
A mystical spirit born from cherry blossoms.

### Evolution Stages

| Stage | Level | Description |
|-------|-------|-------------|
| 🌱 Bud | 1-5 | A tiny seedling just starting out |
| 🌿 Sprout | 6-15 | Growing stronger every day |
| 🌳 Sapling | 16-30 | Becoming a beautiful tree |
| 🌸 Blossom | 31-50 | In full bloom |
| ✨ Elder | 51+ | Ancient and wise |

### Moods
Your pet's mood changes based on how you treat it:
- 🤩 Ecstatic - Over the moon!
- 😊 Happy - Feeling wonderful
- 😌 Content - At peace
- 😐 Neutral - Just okay
- 😑 Bored - Wants attention
- 😢 Sad - Feeling lonely
- 🍽️ Hungry - Needs food!
- 😴 Tired - Needs rest
- 🤒 Sick - Not feeling well

### Achievements
Unlock achievements by using Sakura:
- 🎯 **First Steps** - Install your first app
- 📦 **Collector** - Install 10 apps
- 👑 **Package Master** - Install 100 apps
- 🌱 **Growing Up** - First evolution
- 🌳 **Ancient One** - 5 evolutions
- 🐾 **Animal Lover** - Pet your companion
- 🍽️ **Master Feeder** - Feed 50 times
- 🎮 **Playtime!** - Play 50 times
- 🌙 **Night Owl** - Install after midnight
- 🐦 **Early Bird** - Install before 7 AM

## 📁 Directory Structure

```
~/.sakura/
├── apps/           # Installed applications
├── shims/          # Command shims
├── buckets/        # Package repositories
│   ├── sakura-main/
│   │   └── bucket/ # Portable app manifests
│   ├── community/
│   │   └── bucket/ # Community apps
│   └── sakura-nonportable/
│       └── bucket/ # MSI/EXE installers
├── cache/          # Download cache
├── persist/        # Persistent app data
├── data/           # Sakura data
├── pet/            # Pet data
└── config.json     # Configuration
```

## 🏗️ Manifest Format

Each app is defined by a JSON manifest:

```json
{
    "name": "app-name",
    "version": "1.0.0",
    "description": "App description",
    "homepage": "https://example.com",
    "license": "MIT",
    "url": "https://example.com/app.zip",
    "hash": "sha256...",
    "bin": ["app.exe"],
    "dependencies": ["other-app"],
    "architecture": {
        "64bit": { "url": "..." },
        "32bit": { "url": "..." }
    }
}
```

For non-portable apps:
```json
{
    "name": "my-app",
    "version": "1.0.0",
    "nonportable": true,
    "url": "https://example.com/Setup.exe",
    "installer": {
        "type": "inno",
        "args": ["/S"],
        "admin": false
    }
}
```

## 🎮 Why Sakura?

Unlike other package managers:
- **Fun** - Your pet makes package management enjoyable
- **Gamification** - Earn XP and achievements
- **Modern** - Built for Windows 10/11
- **No admin needed** - Installs to your user directory
- **Isolated** - No conflicts between apps
- **Clean** - No registry pollution
- **Buckets** - Multiple package sources with arrow-key picker
- **Nonportable support** - Handles MSI/EXE installers too
- **Built-in train** - `sak sl` 🚂

## 📝 License

MIT License - See LICENSE file for details.

---

🌸 *Sakura Package Manager - Where package management meets digital companionship* 🌸
