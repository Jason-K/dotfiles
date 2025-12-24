#!/usr/bin/env python3
"""
Patch .claude.json to remove op:// fallbacks from mcpServers headersHelper.
Creates backup before modification.
"""
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

def patch_mcp_configs(claude_json_path: Path, backup_dir: Path):
    if not claude_json_path.exists():
        print(f"File not found: {claude_json_path}", file=sys.stderr)
        return False

    # Create backup
    backup_dir.mkdir(parents=True, exist_ok=True)
    backup_path = backup_dir / f".claude.json.bak_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    shutil.copy2(claude_json_path, backup_path)
    print(f"Backup created: {backup_path}")

    with open(claude_json_path, 'r') as f:
        data = json.load(f)

    mcp = data.get('mcpServers', {})
    modified = False

    # New clean headersHelper configs
    clean_configs = {
        'web-search-prime': {
            'headersHelper': 'printf \'{"Authorization":"Bearer %s","Accept":"application/json, text/event-stream"}\' "$Z_AI_API_KEY"'
        },
        'web-reader': {
            'headersHelper': 'printf \'{"Authorization":"Bearer %s","Accept":"application/json, text/event-stream"}\' "$Z_AI_API_KEY"'
        },
        'context7-mcp': {
            'headersHelper': 'printf \'{"Authorization":"Bearer %s"}\' "$CONTEXT7_API_KEY"'
        },
        'zai-mcp-server': {
            # Change from shell script with op read to simple npx with env
            'type': 'stdio',
            'command': 'npx',
            'args': ['-y', '@z_ai/mcp-server'],
            'env': {
                'Z_AI_API_KEY': '${Z_AI_API_KEY}',
                'Z_AI_MODE': '${Z_AI_MODE:-search}'
            }
        }
    }

    for name, updates in clean_configs.items():
        if name in mcp:
            old_cfg = mcp[name].copy()
            
            if name == 'zai-mcp-server':
                # Complete replacement for stdio server
                mcp[name] = updates
            else:
                # Just update headersHelper for HTTP servers
                if 'headersHelper' in updates:
                    mcp[name]['headersHelper'] = updates['headersHelper']
            
            if mcp[name] != old_cfg:
                modified = True
                print(f"  ✓ Patched: {name}")

    if modified:
        with open(claude_json_path, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"\n✅ {claude_json_path} updated successfully")
        return True
    else:
        print("No changes needed")
        return False

if __name__ == '__main__':
    home = Path.home()
    claude_json = home / '.claude.json'
    backup_dir = home / 'dotfiles/.claude/claude-secure/backups'
    
    success = patch_mcp_configs(claude_json, backup_dir)
    sys.exit(0 if success else 1)
