# Claude Smart Launcher Setup

## Overview

This setup provides multiple Claude execution modes:

1. **`claude`** – Vanilla Claude with no modifications (direct binary)
2. **`claude-smart`** – Intelligent sandboxed mode with preset auto-detection (recommended)
3. **`claude-sandbox <preset>`** – Explicit sandbox with specific preset

The integration works with iTerm2 and provides security by default while allowing full access when needed.

## Files Created

All files are organized in `/Users/jason/dotfiles/.claude/claude-secure/`:

### 1. Core Scripts

- **`claude-secure-wrapper.sh`** - Sandbox wrapper (used by `claude-smart` and `claude-sandbox`)
- **`claude-secure-nosandbox.sh`** - Direct execution with secrets (not exposed in shell)
- **`claude-smart-simple`** - Smart launcher that detects presets (called by `claude-smart`)
- **`projects.toml`** - Project configuration (presets for known projects)

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

Now you can use these commands:

```bash
# Vanilla Claude (no wrapper, no sandbox)
claude --help
claude --dangerously-skip-permissions

# Docker Sandbox (RECOMMENDED)
claude-docker --help
cdocker --dangerously-skip-permissions

# Smart sandbox (Legacy deprecated macOS sandbox)
claude-smart --help
claude-smart --dangerously-skip-permissions

# Quick aliases
c --help                         # claude-smart
cl --dangerously-skip-permissions # claude-smart
cdocker --help                   # claude-docker

# Explicit preset sandbox
claude-sandbox hsLauncher --help
claude-sandbox hsLauncher --dangerously-skip-permissions
```

## How It Works

### Command Modes

**`claude`** – Vanilla (no modifications)

- Runs the Claude binary directly
- No sandboxing, no secrets injection
- Use when you want raw Claude behavior

**`claude-smart`** – Intelligent sandbox (recommended)

- Detects presets from `projects.toml`
- If in configured project → uses preset
- If not → creates temporary sandbox for current directory
- Shows: 🎯 Found preset: hsLauncher
- Shows: 🔥 No preset found - creating temporary sandbox

**`claude-sandbox <preset>`** – Explicit preset

- Manually specify which preset to use
- Lists available presets if none specified
- Advanced usage for fine-grained control

### Security Features (Sandbox Mode Only)

- **Sandboxed**: `claude-smart` and `claude-sandbox` run in macOS sandbox
- **No home access**: By default, denies access to your home directory
- **Whitelist only**: Only allows explicitly permitted directories
- **Audit logging**: All sessions logged to `/Users/jason/Library/Logs/claude-secure/audit.log`
- **Preset detection**: Auto-uses safe presets for known projects
- **Temporary fallback**: Creates isolated sandbox for unknown directories

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
   - Command: `claude-smart --dangerously-skip-permissions`
   - Working Directory: `Integration Directory`

3. **Right-click menu**: Add a Shell Integration trigger for right-click → "Launch Claude Smart"

## Testing

Test each mode:

```bash
# Vanilla mode (no sandbox)
claude --version
claude --help

# Smart mode in configured project (should detect preset)
cd /Users/jason/Scripts/Metascripts/hsLauncher
claude-smart --help

# Smart mode in random directory (should create temp sandbox)
cd /tmp
claude-smart --help

# Quick aliases
c --version
cl --help

# Explicit preset
claude-sandbox hsLauncher --help
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
├── claude-secure-wrapper.sh       # Sandbox wrapper (used by smart/sandbox)
├── claude-secure-nosandbox.sh     # Direct execution (used internally)
├── claude-smart-simple            # Smart preset detector
├── claude-smart                   # Alternative TOML parser version
├── projects.toml                  # Project presets
├── iterm2-integration.sh          # Shell integration (provides all functions)
├── README.md                      # Quick overview
├── SETUP.md                       # This file (setup instructions)
└── shims/                         # Tool shims for secure execution
```

## Security Notes

- **Vanilla mode** (`claude`): No sandbox, full system access — use when you trust the operation
- **Smart mode** (recommended): Sandboxes by default with preset detection
- **Temporary sandboxes**: Unknown directories get isolated sandboxes automatically
- **No internet restrictions**: Network access is enabled (can be disabled per preset)
- **Home directory protection**: Default `no_home=true` prevents access to sensitive files
- **Audit trail**: All sandboxed sessions logged with timestamps and configurations

## Decision Tree

Choose based on your needs:

```
Do you want full system access?
  ├─ YES → use `claude` (vanilla mode)
  └─ NO → use `claude-smart` (recommended)
       ├─ In configured project? → auto-uses preset (Docker supports this too!)
       └─ In unknown directory? → creates temp container/sandbox

Need explicit preset control?
  └─ YES → use `cdocker --preset <name>` (or `claude-sandbox` for legacy)
```

Default aliases (`c`, `cl`) point to `claude-smart` for safety.
