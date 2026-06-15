# 🌸 Sakura Nonportable Bucket

Apps that require MSI/EXE installers - not portable, but fully managed by Sakura.

## 🚀 Add This Bucket

```powershell
sakura bucket add nonportable
```

## 📦 Available Packages

| Package | Version | Type | Description |
|---------|---------|------|-------------|
| vscode | 1.90.2 | inno | Visual Studio Code |
| notepadplusplus | 8.6.8 | inno | Notepad++ text editor |
| discord | 1.0.9015 | nsis | Discord chat |
| steam | 2024.05.01 | nsis | Steam gaming platform |
| zoom | 5.17.11 | msi | Zoom video meetings |
| postman | 11.3.0 | nsis | Postman API platform |
| 1password | 8.10.34 | inno | 1Password password manager |
| obsidian | 1.6.5 | nsis | Obsidian note-taking |
| firefox | 127.0 | inno | Firefox web browser |
| brave | 1.67.123 | inno | Brave browser |
| signal | 7.12.0 | nsis | Signal messenger |
| slack | 4.39.95 | squirrel | Slack collaboration |

## 🔧 Supported Installer Types

| Type | Description |
|------|-------------|
| `msi` | Microsoft Installer (Windows Installer) |
| `inno` | Inno Setup (most common) |
| `nsis` | NSIS (Nullsoft Scriptable Install System) |
| `squirrel` | Squirrel.Windows (auto-update apps) |
| `7z` | 7-Zip archive (extract only) |
| `autohotkey` | AutoHotkey installer |
| `custom` | Custom script |

## 📋 Manifest Format

Nonportable manifests add an `installer` block:

```json
{
    "name": "my-app",
    "version": "1.0.0",
    "nonportable": true,
    "url": "https://example.com/Setup.exe",
    "bin": ["app.exe"],
    "installer": {
        "type": "inno",
        "args": ["/S", "/SILENT"],
        "admin": false,
        "uninstaller": {
            "args": ["/SILENT"]
        }
    }
}
```

## ⚠️ Notes

- Non-portable apps install to standard Windows locations (Program Files)
- Admin elevation may be required for some apps
- Silent install is used by default (no UI)
- Apps update through their own mechanisms
