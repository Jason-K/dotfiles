# Dockerfile for Claude Secure
FROM node:20-slim

# Install system dependencies
# - git, openssh-client: for git operations
# - curl, less: utilities
# - python3: often needed for scripts
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    curl \
    less \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
# We install as root. Runtime execution will be as the host user (via --user flag).
RUN npm install -g @anthropic-ai/claude-code

# Create a writable home directory for the runtime user (whatever UID it is)
RUN mkdir -p /home/claude && chmod 777 /home/claude
ENV HOME=/home/claude

# Set up working directory
WORKDIR /app

# Entry point
ENTRYPOINT ["claude"]
