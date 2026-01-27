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
    gosu \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
# Install Claude Code globally
# Install Claude Code globally (pinned to 2.0.72)
# We match the user's local working version to ensure Z.AI auth compatibility
# and avoid stricter checks in 2.1.x
RUN npm install -g @anthropic-ai/claude-code@2.0.72 --unsafe-perm=true

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
