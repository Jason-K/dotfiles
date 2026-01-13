---
title: Karabiner Configuration Guide
created: 2025-11-15
last_updated: 2026-01-12
category: components
tags: [karabiner, keyboard, remapping]
---

# Karabiner-Elements Configuration

[![CI](https://github.com/Jason-K/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/Jason-K/dotfiles/actions/workflows/ci.yml)

This directory contains the Karabiner-Elements configuration built with [karabiner.ts](https://github.com/evan-liu/karabiner.ts).

## Structure

```
karabiner/
└── karabiner.ts/          # TypeScript-based config builder
    ├── src/
    │   ├── index.ts       # Main configuration file
    │   └── lib/           # Helper functions and builders
    ├── package.json       # Dependencies
    └── karabiner-output.json  # Generated output (not used, writes to ~/.config/karabiner/)
```

## Setup

1. Install dependencies:
   ```bash
   cd ~/dotfiles/karabiner/karabiner.ts
   npm install
   ```

2. Build and deploy configuration:
   ```bash
   npm run build
   ```

This will generate `~/.config/karabiner/karabiner.json` from the TypeScript source.

## Usage

### Modify Configuration

Edit `src/index.ts` to change key mappings, layers, or behaviors.

### Rebuild

After making changes:
```bash
cd ~/dotfiles/karabiner/karabiner.ts
npm run build
```

The configuration will be automatically written to `~/.config/karabiner/karabiner.json`.

### Update karabiner.ts

To update the karabiner.ts library:
```bash
npm run update
```

## Key Features

The configuration includes:

- **Tap-Hold Keys**: Keys that behave differently when tapped vs held
- **Space Layer**: Space bar as a layer key for sublayers (Downloads, Apps, Folders)
- **Caps Lock Modifiers**: Multiple behaviors based on press patterns
- **Custom Modifiers**: HYPER, SUPER, MEH combinations
- **App-Specific Rules**: CMD+Q protection, HOME/END fixes, etc.

## Development

The project uses:
- TypeScript for type safety
- ESLint for code quality
- tsx for TypeScript execution
- karabiner.ts for rule generation

See `src/index.ts` for detailed configuration documentation.

## Notes

- The original project location was `/Users/jason/Scripts/Metascripts/karabiner.ts`
- This is now the canonical location in dotfiles
- Symlinks to Hammerspoon scripts are preserved in `src/karabiner_layer_indicator.lua`
