# Sakura Community Skins

Share and use custom pet skins, themes, and UI styles for Sakura Package Manager!

## How to Use

1. Download a skin folder from this directory
2. Copy it to your `~/.sakura/skins/` directory
3. Set it as active: `sakura config set skin <skin-name>`

## Skin Structure

Each skin folder should contain:

```
my-skin/
├── skin.json          # Skin metadata and configuration
├── pet/               # Custom pet art and species
│   ├── species.json   # Pet species definitions
│   └── art/           # ASCII art for evolution stages
├── theme/             # UI theme colors
│   └── colors.json    # Color scheme
└── README.md          # Description of your skin
```

## skin.json Template

```json
{
    "name": "My Skin",
    "author": "YourName",
    "version": "1.0.0",
    "description": "A custom skin for Sakura",
    "type": "pet",
    "preview": "A preview image URL or description"
}
```

## Contributing

1. Fork this repository
2. Create your skin in `skins/community/<your-skin-name>/`
3. Fill out `skin.json` and add your assets
4. Submit a Pull Request!

## Available Skins

| Name | Type | Description |
|------|------|-------------|
| default | Pet | The original Sakura Spirit |
