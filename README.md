# 🌸 Sakura Package Manager

**Your friendly Windows package manager with a digital companion inside.**

Sakura is a modern, user-friendly package manager for Windows, inspired by Scoop but with a twist — it comes with a built-in Tamagotchi pet that grows and evolves as you use the package manager!

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
# Clone or download Sakura
git clone https://github.com/yourusername/sakura.git

# Run the installer
cd sakura
.\install.ps1
```

### First Steps

```powershell
# Get help
sakura help

# Meet your pet!
sakura pet

# Search for a package
sakura search git

# Install a package
sakura install git

# Check your pet after installing
sakura pet
```

## 📖 Commands

### Package Commands

| Command | Description |
|---------|-------------|
| `sakura install <app>` | Install an application |
| `sakura uninstall <app>` | Remove an application |
| `sakura update [app]` | Check for updates |
| `sakura upgrade` | Update all installed apps |
| `sakura search <query>` | Search available packages |
| `sakura list` | List installed apps |
| `sakura info <app>` | Show app information |

### Bucket Commands

| Command | Description |
|---------|-------------|
| `sakura bucket list` | List added buckets |
| `sakura bucket add <name>` | Add a bucket |
| `sakura bucket rm <name>` | Remove a bucket |

### Pet Commands

| Command | Description |
|---------|-------------|
| `sakura pet` | Show your pet's status |
| `sakura pet feed` | Feed your pet |
| `sakura pet play` | Play with your pet |
| `sakura pet pet` | Pet your companion |
| `sakura pet nap` | Let your pet rest |
| `sakura pet evolve` | Check evolution progress |

### Config Commands

| Command | Description |
|---------|-------------|
| `sakura config get <key>` | Get a config value |
| `sakura config set <key> <value>` | Set a config value |
| `sakura config list` | Show all config |

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
│   └── sakura-main/
│       └── bucket/ # Manifest files
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

## 🎮 Why Sakura?

Unlike other package managers:
- **Fun** - Your pet makes package management enjoyable
- **Gamification** - Earn XP and achievements
- **Modern** - Built for Windows 10/11
- **No admin needed** - Installs to your user directory
- **Isolated** - No conflicts between apps
- **Clean** - No registry pollution

## 📝 License

MIT License - See LICENSE file for details.

---

🌸 *Sakura Package Manager - Where package management meets digital companionship* 🌸
