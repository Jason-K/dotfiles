#!/bin/bash
set -euo pipefail

# Configuration
IMAGE_NAME="claude-secure:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="$SCRIPT_DIR/Dockerfile"
ENV_FILE="$SCRIPT_DIR/.claude-env"
TOML_CONFIG="$SCRIPT_DIR/projects.toml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[claude-docker]${NC} $*"; }
info() { echo -e "${BLUE}[claude-docker]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die() { error "$*"; exit 1; }

# 1. Check prerequisites
if ! command -v docker &>/dev/null; then
    die "Docker is not installed or not in PATH. Please install Docker or OrbStack."
fi

# 2. Build image if needed
if [[ "$(docker images -q "$IMAGE_NAME" 2> /dev/null)" == "" ]]; then
    log "Image $IMAGE_NAME not found. Building..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
fi


# -----------------------------------------------------------------------------
# TOML HELPER (Runs inside Docker to ensure python3.11+ / tomllib availability)
# -----------------------------------------------------------------------------
run_python_in_docker() {
    # $1 source file (mounted to /input)
    # $2 arg2 (passed as sys.argv[2])
    # $3 python script
    
    # We mount the config file to /tmp/config.toml
    docker run --rm \
        -v "$1:/tmp/config.toml:ro" \
        --entrypoint python3 \
        "$IMAGE_NAME" \
        -c "$3" \
        "/tmp/config.toml" "$2" 2>/dev/null
}

toml_to_json() {
  local cfg="$1"
  local name="$2"
  
  run_python_in_docker "$cfg" "$name" '
import sys, json, os

# Only stdlib usage (python 3.11+ in docker image has tomllib)
try:
    import tomllib as toml
except ImportError:
    # This should not happen in our node:20-slim (bookworm) image
    sys.exit(1)

path, name = sys.argv[1], sys.argv[2]

with open(path, "rb") as f:
    data = toml.load(f)

block = None
if name in data and isinstance(data[name], dict):
    block = data[name]
elif isinstance(data.get("projects"), dict) and isinstance(data["projects"].get(name), dict):
    block = data["projects"][name]

if block is None:
    # Signal not found
    print("PRESET_NOT_FOUND")
    sys.exit(0)

def to_list(x):
    if x is None: return []
    if isinstance(x, list): return [str(v) for v in x]
    return [str(x)]

# We act as if we are on the host, so we trust the paths in TOML.
# We CANNOT resolve symlinks reliably because we are inside the container 
# and the host filesystem structure is not fully mounted yet.
# However, projects.toml should usually contain resolved paths or paths valid on host.
def resolve(p):
    # Just expand user (~), do not realpath because we lack visibility
    if not p: return ""
    return os.path.expanduser(p).replace("/root", os.path.expanduser("~")) 

# Hack: we are running as root or claude user inside docker. 
# $HOME inside docker might be /root or /home/claude.
# But we want to resolve "~" to the HOST user home if possible?
# The paths in projects.toml are absolute host paths. 
# Typically they do not use `~` but full paths. 
# If they do use `~`, it probably refers to host home.
# We will just return strings as-is if absolute, or handle ~ simplisticly.

out = {
    "project_root": str(block.get("project_root") or block.get("project") or ""),
    "allow_rw": to_list(block.get("allow_rw")),
    "allow_ro": to_list(block.get("allow_ro")),
    "env_vars": to_list(block.get("env_vars")),
}
print(json.dumps(out))
'
}

detect_preset() {
  local cfg="$1"
  local cwd="$2"
  
  run_python_in_docker "$cfg" "$cwd" '
import sys, os

try:
    import tomllib as toml
except ImportError:
    sys.exit(0)

path, cwd = sys.argv[1], sys.argv[2]
# We cannot resolve matching symlinks inside container for host path.
# We rely on exact string matching or prefix matching.

try:
    with open(path, "rb") as f:
        data = toml.load(f)
except Exception:
    sys.exit(0)

projects = {}
if "projects" in data:
    projects.update(data["projects"])
for k, v in data.items():
    if k != "projects" and isinstance(v, dict) and ("project_root" in v or "project" in v):
        projects[k] = v

best_match = None
max_len = 0

for name, block in projects.items():
    root = block.get("project_root") or block.get("project")
    if not root: continue
    
    # Simple prefix match
    if cwd == root or cwd.startswith(root + os.sep):
        if len(root) > max_len:
            max_len = len(root)
            best_match = name

if best_match:
    print(best_match)
'
}

# -----------------------------------------------------------------------------
# ARGUMENT PARSING
# -----------------------------------------------------------------------------
DOCKER_MOUNTS=()
CLAUDE_ARGS=()
PRESET=""
DEBUG_ENV_MODE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset)
            if [[ -z "${2:-}" ]]; then die "Missing argument for --preset"; fi
            PRESET="$2"
            shift 2
            ;;
        --mount-ro)
            if [[ -z "${2:-}" ]]; then die "Missing path for --mount-ro"; fi
            ABS_PATH="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
            if [[ "$2" == *":"* ]]; then
               DOCKER_MOUNTS+=("-v" "$2:ro")
            else
               TARGET="/mnt/$(basename "$2")"
               DOCKER_MOUNTS+=("-v" "$ABS_PATH:$TARGET:ro")
               log "Mounting (RO): $ABS_PATH -> $TARGET"
            fi
            shift 2
            ;;
        --mount-rw)
            if [[ -z "${2:-}" ]]; then die "Missing path for --mount-rw"; fi
            ABS_PATH="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
             if [[ "$2" == *":"* ]]; then
               DOCKER_MOUNTS+=("-v" "$2")
            else
               TARGET="/mnt/$(basename "$2")"
               DOCKER_MOUNTS+=("-v" "$ABS_PATH:$TARGET")
               log "Mounting (RW): $ABS_PATH -> $TARGET"
            fi
            shift 2
            ;;
        --debug-env)
            DEBUG_ENV_MODE=1
            shift
            ;;
        *)
            CLAUDE_ARGS+=("$1")
            shift
            ;;
    esac
done

# -----------------------------------------------------------------------------
# PRESET LOGIC
# -----------------------------------------------------------------------------
if [[ -z "$PRESET" && -r "$TOML_CONFIG" ]]; then
    PRESET="$(detect_preset "$TOML_CONFIG" "$PWD")"
    if [[ -n "$PRESET" ]]; then
        info "🎯 Auto-detected preset: $PRESET"
    else
        info "🔥 No preset detected for $PWD"
    fi
fi

WORKDIR_TARGET="/app"
PROJECT_ROOT_MOUNT=""

if [[ -n "$PRESET" && -r "$TOML_CONFIG" ]]; then
    
    # Needs to handle failure
    JSON="$(toml_to_json "$TOML_CONFIG" "$PRESET" 2>/dev/null || echo "")"
    if [[ -z "$JSON" || "$JSON" == "PRESET_NOT_FOUND" ]]; then
        error "Failed to load preset '$PRESET' (or not found)"
    else
        # Parse JSON output
        # Rely on python again to avoid jq dependency requirement
        # We need to extract lists into arrays.
        
        # Write json to temp file to read it safely
        TMP_JSON="/tmp/claude_preset_$$.json"
        echo "$JSON" > "$TMP_JSON"
        
        # Read scalar vars
        PROJECT_ROOT_REAL=$(python3 -c "import json; print(json.load(open('$TMP_JSON'))['project_root'])")
        
        # Read mounts
        # For simplicity, we just generate the -v flags via python loop
        
        # Allow RW
        while read -r path; do
            [[ -n "$path" ]] && DOCKER_MOUNTS+=("-v" "$path:$path")
        done < <(python3 -c "import json; print('\n'.join(json.load(open('$TMP_JSON'))['allow_rw']))")
        
        # Allow RO
        while read -r path; do
             [[ -n "$path" ]] && DOCKER_MOUNTS+=("-v" "$path:$path:ro")
        done < <(python3 -c "import json; print('\n'.join(json.load(open('$TMP_JSON'))['allow_ro']))")
        
        rm -f "$TMP_JSON"

        # MAIN MOUNT STRATEGY FOR PRESETS
        # Mount project root to its EXACT host path
        if [[ -d "$PROJECT_ROOT_REAL" ]]; then
             DOCKER_MOUNTS+=("-v" "$PROJECT_ROOT_REAL:$PROJECT_ROOT_REAL")
             WORKDIR_TARGET="$PWD" # Because PWD should be inside PROJECT_ROOT_REAL, and we mounted it same-same
             PROJECT_ROOT_MOUNT="1"
        fi
    fi
fi

# If no project root mounted (no preset, or failed), fallback to generic /app
if [[ -z "$PROJECT_ROOT_MOUNT" ]]; then
    DOCKER_MOUNTS+=("-v" "$PWD:/app")
    WORKDIR_TARGET="/app"
fi


# -----------------------------------------------------------------------------
# SECRETS & EXECUTION
# -----------------------------------------------------------------------------
SECRET_ARGS=()

if [[ -f "$ENV_FILE" && -x "$(command -v op)" ]]; then
    log "Authenticating with 1Password..."
    SECRET_KEYS=(
        "ANTHROPIC_API_KEY"
        "ANTHROPIC_AUTH_TOKEN"
        "Z_AI_API_KEY"
        "ZAI_API_KEY"
        "CONTEXT7_API_KEY"
        "SMITHERY_API_KEY"
        "GITHUB_TOKEN"
        "GEMINI_API_KEY"
        "DEEPSEEK_API_KEY"
        "OPENAI_API_KEY"
        "OPENROUTER_API_KEY"
    )

    # PASS_ENV_ARGS logic replaced by SECRET_ARGS logic below


    # -------------------------------------------------------------------------
    # 4a. Standard Z.AI Defaults
    # -------------------------------------------------------------------------
    export Z_AI_MODE="${Z_AI_MODE:-ZAI}"
    export Z_WEBSEARCH_URL="${Z_WEBSEARCH_URL:-https://api.z.ai/api/mcp/web_search_prime/mcp}"
    export Z_READ_URL="${Z_READ_URL:-https://api.z.ai/api/mcp/zread/mcp}"
    export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"
    export API_TIMEOUT_MS="${API_TIMEOUT_MS:-3000000}"
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    
    # -------------------------------------------------------------------------
    # 4b. Secrets from 1Password
    # -------------------------------------------------------------------------
    # Load secrets into current shell environment first
    # This avoids 'op run' wrapping the interactive docker process.
    log "Loading secrets from 1Password..."
    
    # We filter only the keys we care about
    OP_OUTPUT=$(op run --env-file="$ENV_FILE" -- /usr/bin/env | tr -d '\r')
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^(ANTHROPIC_|Z_AI_|ZAI_|CONTEXT7_|SMITHERY_|GITHUB_|GEMINI_|DEEPSEEK_|OPENAI_|OPENROUTER_).+=.+ ]]; then
             export "$line"
        fi
    done <<< "$OP_OUTPUT"

    # Resolve Auth Conflict (Match legacy behavior)
    # If both API Key and Auth Token are present, prefer API Key and drop Token
    if [[ -n "${ANTHROPIC_API_KEY:-}" && -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
        log "Resolving auth conflict: unset ANTHROPIC_AUTH_TOKEN (preferring API Key)"
        unset ANTHROPIC_AUTH_TOKEN
    fi

    # Construct -e flags for ALL relevant variables (Secrets + Config)
    # We explicitly list the config vars we just set defaults for.
    SECRET_ARGS=()
    
    # Config keys
    CONFIG_KEYS=(
        "Z_AI_MODE"
        "Z_WEBSEARCH_URL"
        "Z_READ_URL"
        "ANTHROPIC_BASE_URL"
        "API_TIMEOUT_MS"
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"
    )
    for key in "${CONFIG_KEYS[@]}"; do
         SECRET_ARGS+=("-e" "$key")
    done

    # Secret keys (dynamic check)
    for key in "${SECRET_KEYS[@]}"; do
        if [[ -n "${!key:-}" ]]; then
             SECRET_ARGS+=("-e" "$key")
        fi
    done

    # User mapping
    USER_ID="$(id -u)"
    GROUP_ID="$(id -g)"
    
    # Base Docker Args
    DOCKER_CMD=(
        "docker" "run" "--rm" "-it"
        "--user" "$USER_ID:$GROUP_ID"
        "--network" "host"
        "-v" "$HOME/.ssh:/home/claude/.ssh:ro"
        "-v" "$HOME/.gitconfig:/home/claude/.gitconfig:ro"
        "${DOCKER_MOUNTS[@]}"
        "-w" "$WORKDIR_TARGET"
        "${SECRET_ARGS[@]}"
    )
    
    if [[ -n "$DEBUG_ENV_MODE" ]]; then
        log "DEBUG MODE: Starting container with /usr/bin/env..."
        exec "${DOCKER_CMD[@]}" --entrypoint /usr/bin/env "$IMAGE_NAME"
    else
        log "Starting container..."
        exec "${DOCKER_CMD[@]}" "$IMAGE_NAME" "${CLAUDE_ARGS[@]:-}"
    fi
    
else
    log "WARNING: Secrets not injected (1Password not found or env file missing)"
    
    # Base Docker Args for Fallback
    DOCKER_CMD=(
        "docker" "run" "--rm" "-it"
        "--user" "$(id -u):$(id -g)"
        "--network" "host"
        "-v" "$HOME/.ssh:/home/claude/.ssh:ro"
        "-v" "$HOME/.gitconfig:/home/claude/.gitconfig:ro"
        "${DOCKER_MOUNTS[@]}"
        "-w" "$WORKDIR_TARGET"
    )

    if [[ -n "$DEBUG_ENV_MODE" ]]; then
        exec "${DOCKER_CMD[@]}" --entrypoint /usr/bin/env "$IMAGE_NAME"
    else
        exec "${DOCKER_CMD[@]}" "$IMAGE_NAME" "${CLAUDE_ARGS[@]:-}"
    fi
fi
