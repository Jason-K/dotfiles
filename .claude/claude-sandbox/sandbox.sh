#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="claude-sandbox:v3"
PROJECTS_TOML="$SCRIPT_DIR/../claude-secure/projects.toml"
ENV_FILE="$SCRIPT_DIR/../claude-secure/.claude-env"
GEN_ARGS_SCRIPT="$SCRIPT_DIR/generate_args.py"

# Build if needed
if [[ "$(docker images -q "$IMAGE_NAME" 2> /dev/null)" == "" ]]; then
    echo "Building $IMAGE_NAME..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
fi

run_container() {
    if ! command -v op &>/dev/null; then
        echo "Error: 1Password CLI (op) is not installed."
        exit 1
    fi

    # 1. Defaults
    export Z_AI_MODE="${Z_AI_MODE:-ZAI}"
    export Z_WEBSEARCH_URL="${Z_WEBSEARCH_URL:-https://api.z.ai/api/mcp/web_search_prime/mcp}"
    export Z_READ_URL="${Z_READ_URL:-https://api.z.ai/api/mcp/zread/mcp}"
    export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"
    export API_TIMEOUT_MS="${API_TIMEOUT_MS:-3000000}"
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    
    export ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-GLM-4.7}"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-GLM-4.7}"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-GLM-4.5-Air}"
    
    export HEADERS_HELPER_MODE="env"
    export HEADERS_HELPER_DISABLE_OP="1"

    # 2. Parse Project Config using external Python script
    DOCKER_ARGS=()
    PYTHON_OUTPUT="$(python3 "$GEN_ARGS_SCRIPT" "$PROJECTS_TOML")"

    # Read the lines into the array
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            # If the line starts with export, we eval it in the shell
            if [[ "$line" == export* ]]; then
                eval "$line"
            else
                DOCKER_ARGS+=("$line")
            fi
        fi
    done <<< "$PYTHON_OUTPUT"

    echo "Starting Claude Sandbox..."
    echo "Mounts: ${DOCKER_ARGS[*]}"
    
    ENTRYPOINT_SCRIPT="$SCRIPT_DIR/entrypoint.sh"
    
    op run --no-masking --env-file "$ENV_FILE" -- \
    docker run --rm -it \
        --user "$(id -u):$(id -g)" \
        -e HOME=/home/node \
        -v "/etc/passwd:/etc/passwd:ro" \
        -v "/etc/group:/etc/group:ro" \
        -v "$HOME/.ssh:/home/node/.ssh:ro" \
        -v "$HOME/.gitconfig:/home/node/.gitconfig:ro" \
        -v "$ENTRYPOINT_SCRIPT:/usr/local/bin/sandbox-entrypoint.sh:ro" \
        "${DOCKER_ARGS[@]}" \
        -e ANTHROPIC_API_KEY \
        -e ANTHROPIC_BASE_URL \
        -e Z_AI_API_KEY \
        -e ZAI_API_KEY \
        -e OPENAI_API_KEY \
        -e CONTEXT7_API_KEY \
        -e SMITHERY_API_KEY \
        -e GITHUB_TOKEN \
        -e Z_AI_MODE \
        -e Z_WEBSEARCH_URL \
        -e Z_READ_URL \
        -e API_TIMEOUT_MS \
        -e CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC \
        -e ANTHROPIC_DEFAULT_OPUS_MODEL \
        -e ANTHROPIC_DEFAULT_SONNET_MODEL \
        -e ANTHROPIC_DEFAULT_HAIKU_MODEL \
        -e HEADERS_HELPER_MODE \
        -e HEADERS_HELPER_DISABLE_OP \
        -e ANTHROPIC_MODEL \
        -w "$PWD" \
        "$IMAGE_NAME" \
        -c "bash /usr/local/bin/sandbox-entrypoint.sh"
}

run_container
