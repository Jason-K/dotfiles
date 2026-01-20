import sys
import os
import re

# Usage: python3 generate_args.py <path_to_projects.toml>

if len(sys.argv) < 2:
    sys.exit(0)

toml_file = sys.argv[1]
cwd = os.getcwd()

def parse_toml(path):
    # Simple, brittle parser sufficient for this projects.toml structure
    data = {}
    current_section = None
    try:
        with open(path, "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"): continue
                
                # Section
                m_sec = re.match(r"^\[(.*)\]$", line)
                if m_sec:
                    current_section = m_sec.group(1)
                    data[current_section] = {"allow_rw": [], "allow_ro": [], "env_vars": []}
                    continue
                
                if not current_section: continue
                
                # Key-Value
                # project_root = "..."
                m_kv = re.match(r"^(\w+)\s*=\s*\"([^\"]+)\"", line)
                if m_kv:
                    if m_kv.group(1) == "project_root":
                        data[current_section]["project_root"] = m_kv.group(2)
                    elif m_kv.group(1) == "default_model":
                         data[current_section]["default_model"] = m_kv.group(2)
                    continue
                
                # Arrays: allow_rw = ["...", "..."]
                m_arr = re.match(r"^(\w+)\s*=\s*\[(.*)\]", line)
                if m_arr:
                    key = m_arr.group(1)
                    if key in ["allow_rw", "allow_ro", "env_vars"]:
                        raw_list = m_arr.group(2)
                        # extract strings
                        items = re.findall(r"\"([^\"]+)\"", raw_list)
                        data[current_section][key] = items
    except Exception as e:
        pass
    return data

data = parse_toml(toml_file)

def match_project(data, cwd):
    best_match = None
    max_len = 0
    for name, section in data.items():
        root = section.get("project_root")
        if not root: continue
        root = os.path.expanduser(root)
        if cwd == root or cwd.startswith(root + os.sep):
            if len(root) > max_len:
                max_len = len(root)
                best_match = section
    return best_match

project = match_project(data, cwd)
mounts = []

if project:
    root = os.path.expanduser(project.get("project_root"))
    mounts.append("-v")
    mounts.append(f"{root}:{root}")
    for p in project.get("allow_rw", []):
        p = os.path.expanduser(p)
        mounts.append("-v")
        mounts.append(f"{p}:{p}")
    for p in project.get("allow_ro", []):
        p = os.path.expanduser(p)
        mounts.append("-v")
        mounts.append(f"{p}:{p}:ro")
    
    if "default_model" in project:
        print("export ANTHROPIC_MODEL=\"" + project["default_model"] + "\"")

else:
    mounts.append("-v")
    mounts.append(f"{cwd}:{cwd}")

# Always mount dotfiles RO
dotfiles = os.path.expanduser("~/dotfiles")
mounts.append("-v")
mounts.append(f"{dotfiles}:{dotfiles}:ro")

# Mount ~/.claude/commands and plugins if they exist
user_home = os.path.expanduser("~")
for subdir in ["commands", "plugins"]:
    host_path = os.path.join(user_home, ".claude", subdir)
    if os.path.exists(host_path):
        # Mount to /home/node/.claude/subdir
        container_path = f"/home/node/.claude/{subdir}"
        mounts.append("-v")
        mounts.append(f"{host_path}:{container_path}")

# Print args one per line
for m in mounts:
    print(m)
