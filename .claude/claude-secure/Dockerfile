# Dockerfile for Claude Secure
FROM node:20-slim

# Install system dependencies
# - git, openssh-client: for git operations
# - curl, less: utilities
# - python3: often needed for scripts
# Install runtime dependencies
# We NEED python3 for the config injection script
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    ssh \
    python3 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
# Install Claude Code globally
# We install as root. Runtime execution will be as the host user (via --user flag).
RUN npm install -g @anthropic-ai/claude-code

# Setup Environment for Runtime User
# 1. Allow writing to /etc/passwd so we can inject the host user at runtime
# 2. Create /home/claude with 777 permissions so ANY user (UID 501, etc) can write to it
RUN chmod 666 /etc/passwd && \
    mkdir -p /home/claude/.config && \
    chmod -R 777 /home/claude

# Set up working directory
WORKDIR /app

# Entry point
ENTRYPOINT ["claude"]
