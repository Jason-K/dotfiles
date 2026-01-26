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
        --run-cmd)
            RUN_CMD_MODE=1
            CLAUDE_ARGS+=("--run-cmd")
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
# -----------------------------------------------------------------------------
# SECRETS & EXECUTION
# -----------------------------------------------------------------------------
SECRET_ARGS=()

# 4. PREPARE CONFIG ARGS (Passed via -e)
# These are safe configuration variables (URLs, models, etc)
CONFIG_KEYS=(
    "Z_AI_MODE"
    "Z_WEBSEARCH_URL"
    "Z_READ_URL"
    "ANTHROPIC_BASE_URL"
    "API_TIMEOUT_MS"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"
    "ANTHROPIC_DEFAULT_OPUS_MODEL"
    "ANTHROPIC_DEFAULT_SONNET_MODEL"
    "ANTHROPIC_DEFAULT_HAIKU_MODEL"
    "HEADERS_HELPER_MODE"
    "HEADERS_HELPER_DISABLE_OP"
    # Also pass these through if they exist in env (host fallback)
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

# -------------------------------------------------------------------------
# 4a. Standard Z.AI Defaults & Configuration
# -------------------------------------------------------------------------
export Z_AI_MODE="${Z_AI_MODE:-ZAI}"
export Z_WEBSEARCH_URL="${Z_WEBSEARCH_URL:-https://api.z.ai/api/mcp/web_search_prime/mcp}"
export Z_READ_URL="${Z_READ_URL:-https://api.z.ai/api/mcp/zread/mcp}"
export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"
export API_TIMEOUT_MS="${API_TIMEOUT_MS:-3000000}"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Force managed mode flags (only if executing claude)
if [[ -z "${RUN_CMD_MODE:-}" ]]; then
    CLAUDE_ARGS+=("--dangerously-skip-permissions")
fi

# Model defaults (from legacy launcher)
export ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-GLM-4.7}"
export ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-GLM-4.7}"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-GLM-4.5-Air}"

# Prevent runtime biometric prompts
export HEADERS_HELPER_MODE="env"
export HEADERS_HELPER_DISABLE_OP="1"

# 4b. Config Args
CONFIG_ARGS=() 
for key in "${CONFIG_KEYS[@]}"; do
    if [[ -n "${!key:-}" ]]; then
        CONFIG_ARGS+=("-e" "$key=${!key}")
    fi
done

# -------------------------------------------------------------------------
# 5. EXECUTION STRATEGY (Robust Wrapper Mode)
# -------------------------------------------------------------------------

# User mapping
USER_ID="$(id -u)"
GROUP_ID="$(id -g)"

# Define the container entrypoint script
# This runs INSIDE the container to handle logic safely with raw keys
CONTAINER_SCRIPT='
    # 1. Backfill Z.AI keys if needed
    if [ -z "${Z_AI_API_KEY:-}" ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        export Z_AI_API_KEY="$ANTHROPIC_API_KEY"
    fi
    if [ -z "${ZAI_API_KEY:-}" ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        export ZAI_API_KEY="$ANTHROPIC_API_KEY"
    fi

    # 2. Resolve Auth Conflict
    if [ -n "${ANTHROPIC_API_KEY:-}" ] && [ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]; then
        unset ANTHROPIC_AUTH_TOKEN
    fi

    # 0. SETUP ENV & USER
    export HOME="/home/claude"
    export XDG_CONFIG_HOME="$HOME/.config"
    export CLAUDE_CONFIG_DIR="$HOME/.config/claude-code"

    # Patch /etc/passwd if whoami fails (fixing "cannot find name for user ID")
    if ! whoami >/dev/null 2>&1; then
        if [ -w /etc/passwd ]; then
            echo "claude:x:$(id -u):$(id -g):Claude:$HOME:/bin/sh" >> /etc/passwd
        fi
    fi

    # -------------------------------------------------------------------------
    # PROXY SETUP (To bypass client-side key validation)
    # -------------------------------------------------------------------------
    # Claude Code enforces "sk-ant-" prefix. Z.AI keys look like "6bcc...".
    # We use a dummy key for Claude Code, and swap it for the REAL key in a local proxy.

    export REAL_ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"
    export PROXY_PORT="8888"
    export LOCAL_PROXY_URL="http://127.0.0.1:$PROXY_PORT"
    
    # Write the Node.js Proxy
    cat > /tmp/auth_proxy.js <<EOF
const http = require("http");
const https = require("https");
const url = require("url");

const TARGET_URL = process.env.REAL_ANTHROPIC_BASE_URL;
const REAL_KEY = process.env.Z_AI_API_KEY;
const DEBUG = process.env.VERBOSE_PROXY === "1";

console.log("[Proxy] Starting Auth Proxy...");
console.log("[Proxy] Target: " + TARGET_URL);
if (!REAL_KEY) {
    console.warn("[Proxy] WARNING: Z_AI_API_KEY is not set! Requests will likely fail.");
}

const server = http.createServer((req, res) => {
    try {
        if (DEBUG) console.log("[Proxy] Request: " + req.method + " " + req.url);

        const target = new URL(TARGET_URL);
        const options = {
            hostname: target.hostname,
            port: target.port || 443,
            path: req.url, // Path usually includes /v1/...
            method: req.method,
            headers: { ...req.headers },
            rejectUnauthorized: false 
        };

        // Key Swap Logic
        // We replace the dummy key (sk-ant-dummy...) with the real Z.AI key
        if (REAL_KEY) {
            options.headers["x-api-key"] = REAL_KEY;
            // Ensure we don"t send conflicting auth tokens if present
            // delete options.headers["authorization"]; 
        }
        
        // Host header should match target
        options.headers["host"] = target.hostname;

        const proxyReq = https.request(options, (proxyRes) => {
            res.writeHead(proxyRes.statusCode, proxyRes.headers);
            proxyRes.pipe(res, { end: true });
        });

        proxyReq.on("error", (e) => {
            console.error("[Proxy] Upstream Error: " + e.message);
            res.writeHead(502);
            res.end("Proxy Upstream Error");
        });

        req.pipe(proxyReq, { end: true });

    } catch (e) {
        console.error("[Proxy] Handler Error: " + e.message);
        res.writeHead(500);
        res.end("Proxy Internal Error");
    }
});

server.listen(parseInt(process.env.PROXY_PORT), "127.0.0.1", () => {
    console.log("[Proxy] Listening on 127.0.0.1:" + process.env.PROXY_PORT);
});
EOF

    # Start Proxy in Background
    # We use nohup to ensure it stays alive, though & is usually enough in entrypoint
    node /tmp/auth_proxy.js > /tmp/proxy.log 2>&1 &
    PROXY_PID=$!
    # Wait a moment for proxy to start
    sleep 1

    # -------------------------------------------------------------------------
    # CONFIG GENERATION
    # -------------------------------------------------------------------------
    
    # We use python3 to generate the JSON safely
    # We use single quotes for the shell variable, so we wrap the python command in escaped single quotes '\''
    # and use double quotes exclusively inside the python script.
    python3 -c '\''
import json
import os
import sys

# Hardcode home since we forced it in shell
home = "/home/claude"
# USE PROXY URL for Claude Code configuration
base_url = os.environ.get("LOCAL_PROXY_URL", "http://127.0.0.1:8888")

# USE DUMMY KEY for validation bypass
# Must start with sk-ant- to satisfy client-side regex
dummy_key = "sk-ant-api03-dummy-key-for-local-proxy-bypass-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-aaaaaa"

# DATA 2: Settings (usually settings.json)
settings_data = {}
settings_data["anthropicBaseUrl"] = base_url
settings_data["ANTHROPIC_BASE_URL"] = base_url
settings_data["verbose"] = True
settings_data["disableTelemetry"] = True
settings_data["hasCompletedOnboarding"] = True 
settings_data["agreedToTerms"] = True
settings_data["theme"] = "dark" 

# Merge Auth into Settings (Critical: claude-code may look for keys in settings.json)
# We inject the DUMMY key here. The PROXY swaps it.
settings_data["primaryApiKey"] = dummy_key
settings_data["apiKey"] = dummy_key
settings_data["ANTHROPIC_API_KEY"] = dummy_key

def write_json(path, data):
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
        print(f"[claude-docker] Wrote config to {path}")
    except Exception as e:
        print(f"[claude-docker] Failed to write {path}: {e}")

# PATH 1: ~/.claude.json (Legacy Root - Memory/Sessions)
# Some versions use this for everything if singular
write_json(os.path.join(home, ".claude.json"), settings_data)

# PATH 2: ~/.claude/config.json (Likely Auth - Keeping for compat)
write_json(os.path.join(home, ".claude", "config.json"), settings_data)

# PATH 3: ~/.claude/settings.json (Main Config for Claude Code)
write_json(os.path.join(home, ".claude", "settings.json"), settings_data)

# PATH 4: XDG Config (~/.config/claude-code/config.json & settings.json)
write_json(os.path.join(home, ".config", "claude-code", "config.json"), settings_data)
write_json(os.path.join(home, ".config", "claude-code", "settings.json"), settings_data)

# PATH 5: XDG Config Alternative (~/.config/claude/settings.json)
write_json(os.path.join(home, ".config", "claude", "settings.json"), settings_data)

# PATH 6: Managed Settings (Global Override - /etc/claude-code/managed-settings.json)
# We try to write this if we have permission (we might not if running as non-root, but we are root or 501?)
# Actually, inside the container we might be root initially? 
# No, we run `python3 -c` via `sh -c`. The `docker run --user` argument sets the user.
# So we likely CANNOT write to /etc. 
# But lets try just in case /etc/claude-code exists and is writable (unlikely).
write_json("/etc/claude-code/managed-settings.json", settings_data)

# Update .bashrc safely (avoiding f-string syntax errors with quotes)
bashrc_path = os.path.join(home, ".bashrc")
try:
    with open(bashrc_path, "a") as f:
        f.write(f"\nexport ANTHROPIC_BASE_URL=\"{base_url}\"\n")
        f.write(f"export ANTHROPIC_API_KEY=\"{dummy_key}\"\n")
    print(f"[claude-docker] Appended env vars to {bashrc_path}")
except Exception as e:
    print(f"[claude-docker] Failed to update .bashrc: {e}")
'\''

    # 4. DIAGNOSTICS & PRE-FLIGHT
    echo "🔍 [claude-docker] Diagnostics:"
    echo "   User: $(whoami) ($(id -u):$(id -g))"
    echo "   HOME: $HOME"
    echo "   XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
    
    echo "   Checking config file permissions:"
    ls -la "$HOME/.claude.json" 2>/dev/null || echo "   ~/.claude.json missing!"
    ls -la "$HOME/.claude/config.json" 2>/dev/null || echo "   ~/.claude/config.json missing!"
    ls -la "$HOME/.claude/settings.json" 2>/dev/null || echo "   ~/.claude/settings.json missing!"
    ls -la "$HOME/.config/claude-code/config.json" 2>/dev/null || echo "   XDG Config missing!"

    # 5. Execute payload
    echo "🚀 [claude-docker] Launching Claude..."
    if [ "$1" = "--debug-env" ]; then
        exec /usr/bin/env
    elif [ "$1" = "--run-cmd" ]; then
        shift
        exec "$@"
    else
        exec claude "$@"
    fi
'

# Split into OPTS and IMAGE args to allow injecting SECRET_ARGS (which are -e flags) 
# BEFORE the image name.
DOCKER_OPTS=(
    "docker" "run" "--rm" "-it"
    "--user" "$USER_ID:$GROUP_ID"
    "--network" "host"
    "-v" "$HOME/.ssh:/home/claude/.ssh:ro"
    "-v" "$HOME/.gitconfig:/home/claude/.gitconfig:ro"
    "${DOCKER_MOUNTS[@]}"
    "-w" "$WORKDIR_TARGET"
    "${CONFIG_ARGS[@]}"
    "--entrypoint" "/bin/sh"
)

DOCKER_IMAGE_ARGS=(
    "$IMAGE_NAME"
    "-c" "$CONTAINER_SCRIPT"
    "claude-wrapper"
)

# Handle DEBUG mode argument passing
if [[ -n "$DEBUG_ENV_MODE" ]]; then
     CLAUDE_ARGS_FINAL=("--debug-env")
else
     CLAUDE_ARGS_FINAL=("${CLAUDE_ARGS[@]:-}")
fi


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
    
    SECRET_ARGS=()
    for key in "${SECRET_KEYS[@]}"; do
         SECRET_ARGS+=("-e" "$key")
    done

    # Final Execution with OP
    # IMPORTANT: SECRET_ARGS must go BEFORE DOCKER_IMAGE_ARGS
    log "Starting container (via op run)..."
    exec op run --no-masking --env-file "$ENV_FILE" -- "${DOCKER_OPTS[@]}" "${SECRET_ARGS[@]}" "${DOCKER_IMAGE_ARGS[@]}" "${CLAUDE_ARGS_FINAL[@]}"

else
    # Fallback / Environment Mode
    # If variables are already in shell (from term-integration), CONFIG_KEYS logic above
    # has already captured them into CONFIG_ARGS via the loop.
    
    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
         log "✅ Using secrets from current environment (Host Fallback)"
    else
         log "⚠️  No secrets found (op missing/failed, and no env vars set). Claude may Prompt for Login."
    fi
    
    log "Starting container (Host Env)..."
    exec "${DOCKER_OPTS[@]}" "${DOCKER_IMAGE_ARGS[@]}" "${CLAUDE_ARGS_FINAL[@]}"
fi
