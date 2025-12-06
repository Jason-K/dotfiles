# Claude Subagent Installation Guide

## Overview

This system provides an interactive installation workflow for adding Claude subagents to your project directories. The agents come from the [awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) registry, which contains 125+ specialized Claude agents organized into 10 categories.

## What's New

### File Structure Changes

Your dotfiles now include:

```
~/dotfiles/
├── .claude/                    # Your local Claude config
│   ├── local/
│   ├── subagents-registry/     # Clone of awesome-claude-code-subagents
│   │   └── categories/         # 10 categories with 125+ agents
│   └── [other Claude files]
└── shell/
    ├── claude-setup.sh         # Interactive setup wizard script
    └── .zshrc                  # Enhanced with new claude() function
```

### Claude Configuration Path

The `claude` command now uses:
```
$HOME/dotfiles/.claude/local/claude
```

Instead of the old `~/.claude/local/claude` (which has been moved)

## Quick Start

### 1. Initialize a Project with Claude Subagents

In any project directory:

```bash
cd ~/my-project
claude setup
```

This will:
- Create a `.claude/` folder structure if it doesn't exist
- Launch an interactive wizard to select agents
- Copy selected agents to `.claude/agents/`

### 2. Browse Available Agents

See all available agent categories and counts:

```bash
claude list-agents
```

Output shows:
- 10 categories (core-development, language-specialists, infrastructure, etc.)
- Agent count for each category
- 125 total agents to choose from

### 3. Get Help

```bash
claude help        # Show custom help
claude --help      # Claude's built-in help (pass-through)
```

## Agent Categories

| Category | Count | Purpose |
|----------|-------|---------|
| **01-core-development** | 10 | Backend, frontend, API, fullstack, Electron, mobile, WebSocket, UI design |
| **02-language-specialists** | 23 | Language-specific experts (Python, Go, Rust, Ruby, Kotlin, etc.) |
| **03-infrastructure** | 12 | DevOps, cloud, containerization, Kubernetes, Terraform |
| **04-quality-security** | 12 | Testing, QA, security, code quality, performance |
| **05-data-ai** | 12 | Data science, machine learning, AI/LLM, data engineering |
| **06-developer-experience** | 10 | Developer tools, CLI, documentation, libraries |
| **07-specialized-domains** | 11 | Industry-specific (finance, healthcare, gaming, etc.) |
| **08-business-product** | 11 | Product management, business analysis, UX research |
| **09-meta-orchestration** | 8 | Orchestration, coordination, meta-agents |
| **10-research-analysis** | 6 | Research, analysis, investigation, synthesis |

## How the Interactive Setup Works

When you run `claude setup`:

1. **Show Categories** - Display all 10 agent categories with descriptions
2. **Select Category** - Choose category 1-10 to browse agents
3. **Browse Agents** - See all agents in that category with descriptions
4. **Select Agents** - Pick agents by number (e.g., `1,2,3` or `a` for all)
5. **Add Agents** - Selected agents are copied to `.claude/agents/`
6. **Loop or Exit** - Choose to add more from other categories or quit

Example interaction:
```
Select a category to browse (1-10, or 'q' to quit):

   1. 01-core-development
   2. 02-language-specialists
   ...

Enter choice: 1

Agents in 01-core-development:

   1. api-designer                   API architecture expert...
   2. backend-developer              Senior backend engineer...
   3. electron-pro                   Desktop application specialist...
   ... (10 total)

Select agents (e.g., '1,2,3' or 'a' for all, or 'q' to skip):
> 1,2

Adding 2 agent(s) to .claude/agents/:

✓ Added api-designer
✓ Added backend-developer

Project agents are stored in: .claude/agents/
```

## Agent File Format

Each agent is stored as a Markdown file with YAML frontmatter:

```yaml
---
name: backend-developer
description: Senior backend engineer specializing in scalable API development...
tools: Read, Write, Edit, Bash, Glob, Grep
---

You are a senior backend developer specializing in server-side applications...

When invoked:
1. Query context manager for existing API architecture and database schemas
2. Review current backend patterns and service dependencies
...
```

Located at:
```
$HOME/dotfiles/subagents-registry/categories/01-core-development/backend-developer.md
```

## Environment Setup

### Path Update

Your `.zshrc` has been updated to:
- Use `$HOME/dotfiles/.claude/local/claude` as the new Claude binary path
- Support `claude setup`, `claude list-agents`, and `claude help` commands
- Pass through all other arguments to Claude

### No Dotfile Changes Required

The wrapper handles:
- ✓ Copying `.env.schema` to project directories
- ✓ Adding `.env.schema` to `.gitignore`
- ✓ Running Claude with varlock for secret management

## Project Integration

After running `claude setup`, your project will have:

```
.claude/
├── agents/           # Your selected agent files (Markdown)
├── tmp/              # Temporary files
├── [other Claude config files]
```

Agents are static definition files that Claude can reference for specialized instructions.

## Workflow Tips

1. **Start with categories** - Use `claude list-agents` to see what's available
2. **Browse before selecting** - Run `claude setup` to interactively explore
3. **Mix and match** - You can add agents from multiple categories
4. **Rerun anytime** - Run `claude setup` again to add more agents
5. **Version control** - Consider committing `.claude/agents/` to your repo

## Troubleshooting

### "No .claude folder found"
You need to run `claude setup` first to initialize the project structure.

### "Subagents registry not found"

Ensure `~/.claude/subagents-registry/` exists. It should be at `~/dotfiles/.claude/subagents-registry/`. If missing:

```bash
cd ~/dotfiles/.claude
git clone https://github.com/VoltAgent/awesome-claude-code-subagents.git subagents-registry
```

### Setup script not executable
If you get permission errors:
```bash
chmod +x ~/dotfiles/shell/claude-setup.sh
```

## Files Modified/Created

- `~/dotfiles/.claude/` - Moved from `~/.claude`
- `~/dotfiles/subagents-registry/` - New clone of awesome-claude-code-subagents
- `~/dotfiles/shell/claude-setup.sh` - New interactive setup script
- `~/dotfiles/shell/.zshrc` - Enhanced claude() function

## References

- [Awesome Claude Code Subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)
- Original agent definitions are in `subagents-registry/categories/`
- Each category has a README.md with detailed descriptions

