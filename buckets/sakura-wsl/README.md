# 🌸 Sakura WSL Bucket

Custom WSL distributions for Sakura Package Manager.

## 🚀 Add This Bucket

```powershell
sak bucket add wsl
```

## 🐧 Available Distros

| Package | Version | Description |
|---------|---------|-------------|
| ubuntu-sakura | 24.04 | Ubuntu with dev tools pre-installed |
| arch-sakura | rolling | Arch Linux minimal + dev tools |
| fedora-sakura | 40 | Fedora with modern Linux tools |
| alpine-sakura | 3.20 | Lightweight Alpine |
| debian-sakura | 12 | Stable Debian |
| void-sakura | rolling | Independent distro with runit |

## 📦 Install a Distro

```powershell
# Install Ubuntu with dev tools
sak install ubuntu-sakura

# Install Arch
sak install arch-sakura

# Force WSL bucket
sak install ubuntu-sakura -viab sakura-wsl
```

Each distro auto-installs:
- curl, wget, git
- build tools (gcc, make, etc.)
- Node.js, npm
- Python, pip
- Vim, Neovim
- GitHub CLI (gh)

## 📋 Create Your Own Distro

Add a JSON manifest to `bucket/`:

```json
{
    "name": "my-distro",
    "version": "1.0",
    "description": "My custom WSL distro",
    "url": "https://example.com/distro.tar.gz",
    "wsl": true,
    "wsl_name": "MyDistro",
    "wsl_version": 2,
    "installer": {
        "type": "wsl",
        "post_install": [
            "wsl -d MyDistro -- bash -c 'apt update && apt install -y my-stuff'"
        ]
    }
}
```

## 🛠️ WSL Commands

```powershell
wsl -d Ubuntu-Sakura          # Launch distro
wsl -l -v                     # List all distros
wsl --set-default Ubuntu-Sakura  # Set default
wsl --terminate Ubuntu-Sakura    # Stop distro
wsl --unregister Ubuntu-Sakura   # Remove distro
```

## 📜 Rules for Submitting Distros

- Must be a valid rootfs tarball or .tar.gz
- Must work with WSL 1 or 2
- No malware or backdoors
- Include post_install scripts for common tools
- Test before submitting PR
