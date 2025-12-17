# Claude Smart Launcher Setup

## Overview
This setup provides an intelligent Claude launcher that automatically detects your project configuration and launches Claude in a secure sandbox. It works with iTerm2 and provides a seamless experience for both preset projects and ad-hoc development.

## Files Created

All files are organized in `/Users/jason/dotfiles/.claude/claude-secure/`:

### 1. Core Scripts
- **`claude-secure-wrapper.sh`** - The main sandbox wrapper (fixed to work with your config)
- **`claude-smart-simple`** - Smart launcher that detects presets
- **`projects.toml`** - Project configuration (updated with necessary directories)

### 2. Integration
- **`iterm2-integration.sh`** - Shell aliases and iTerm2 integration
- **`SETUP.md`** - This file (setup instructions)

### 3. Supporting Files
- **`shims/`** - Directory containing tool shims for secure execution
- **`claude-smart`** - Alternative implementation (using TOML parsing)

## Quick Setup

### 1. Add to Shell Profile
Add this to your `~/.zshrc` (or `~/.bashrc`):

```bash
# Claude Smart Launcher
source /Users/jason/dotfiles/.claude/claude-secure/iterm2-integration.sh
```

Then reload your shell:
```bash
source ~/.zshrc
```

### 2. Usage
Now you can use these commands anywhere:

```bash
# Launch Claude in smart mode (detects presets)
claude

# Launch with yolo mode
claude --dangerously-skip-permissions

# Quick aliases
c --dangerously-skip-permissions          # Same as claude --dangerously-skip-permissions
cl --help         # Show help
```

## How It Works

### Smart Detection
- **If you're in a configured project** (like `/Users/jason/Scripts/Metascripts/hsLauncher`):
  - Uses the predefined preset from `projects.toml`
  - Shows: 🎯 Found preset: hsLauncher

- **If you're in any other directory**:
  - Creates a temporary sandbox for just that directory
  - Shows: 🔥 No preset found - creating temporary sandbox

### Security Features
- **Sandboxed**: Every session runs in macOS sandbox
- **No home access**: By default, denies access to your home directory
- **Whitelist only**: Only allows explicitly permitted directories
- **Audit logging**: All sessions logged to `/Users/jason/Library/Logs/claude-secure/audit.log`

### Current Presets
Your `projects.toml` includes:
- **hsLauncher**: Your Hammerspoon launcher project
  - Project: `/Users/jason/Scripts/Metascripts/hsLauncher`
  - Additional R/W: `/Users/jason/Scripts/Metascripts/hsStringEval`
  - Config access: `/Users/jason/dotfiles`, `/Users/jason/.claude`
  - Read-only: `/Users/jason/.hammerspoon`

## Adding New Projects

To add a new project preset, edit `/Users/jason/dotfiles/.claude/claude-secure/projects.toml`:

```toml
[my_project]
project_root = "/path/to/my/project"
mode = "rw"
network = true
no_home = true
strict_temp = true
audit_log = "/Users/jason/Library/Logs/claude-secure/audit.log"

allow_rw = ["/path/to/my/project", "/path/to/related/project"]
allow_ro = ["/path/to/readonly/stuff"]
```

## iTerm2 Integration (Optional)

For enhanced iTerm2 experience, you can add shell triggers:

1. **Open iTerm2 Preferences → Profiles → Keys → Key Bindings**
2. **Add new shortcut**:
   - Keyboard Shortcut: `⌘⌥C` (or your preference)
   - Action: `Run Shell Command`
   - Command: `claude --dangerously-skip-permissions`
   - Working Directory: `Integration Directory`

3. **Right-click menu**: Add a Shell Integration trigger for right-click → "Launch Claude"

## Testing

Test the setup:

```bash
# In hsLauncher directory (should use preset)
cd /Users/jason/Scripts/Metascripts/hsLauncher
claude --help

# In a random directory (should create temp sandbox)
cd /tmp
claude --help

# Test aliases
c --help
cl --version
```

## Troubleshooting

### Issues and Solutions

1. **"claude command not found"**
   - Make sure you added the integration to your shell profile
   - Reload your shell with `source ~/.zshrc`

2. **Permission errors**
   - Check that the scripts are executable: `chmod +x /Users/jason/dotfiles/.claude/claude-secure/*`
   - Verify the wrapper script path is correct

3. **Sandbox errors**
   - Check the audit log: `tail -f /Users/jason/Library/Logs/claude-secure/audit.log`
   - Make sure your project directories are added to `allow_rw` in the preset

4. **Preset not detected**
   - Verify the `project_root` exactly matches your directory
   - Use `realpath` to check the actual path: `realpath $(pwd)`

## Files Summary

```
/Users/jason/dotfiles/.claude/claude-secure/
├── claude-secure-wrapper.sh     # Main sandbox wrapper
├── claude-smart-simple           # Smart preset detector
├── claude-smart                  # Alternative TOML parser version
├── projects.toml                 # Project configurations
├── iterm2-integration.sh         # Shell integration
├── README.md                      # Quick overview
├── SETUP.md                      # This file (setup instructions)
└── shims/                        # Tool shims for secure execution
```

## Security Notes

- **Always sandboxed**: Even temporary sandboxes restrict access to your system
- **No internet restrictions**: Network access is enabled (can be disabled per preset)
- **Home directory protection**: Default `no_home=true` prevents access to sensitive files
- **Audit trail**: All sessions are logged with timestamps and configurations

Your Claude launcher is now ready for secure, intelligent development! 🚀
