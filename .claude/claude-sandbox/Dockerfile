FROM node:20

# Install basic development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    less \
    git \
    sudo \
    fzf \
    zsh \
    vim \
    nano \
    procps \
    curl \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Create a non-root user 'claude' if 'node' isn't preferred, but official uses 'node'. 
# Let's stick to 'node' to match official, but ensure we can map UID/GID at runtime if needed.
# Official image comes with 'node' user.

# Setup workspace
WORKDIR /workspace
RUN chown node:node /workspace

# Setup config dir for claude
RUN mkdir -p /home/node/.claude \
    && mkdir -p /home/node/.config \
    && chown -R node:node /home/node \
    && chmod -R 777 /home/node

# Switch to node user
USER node
ENV SHELL=/bin/zsh

# Create compatibility symlink for hardcoded paths in plugins
# Access via root before switching user if possible, or use sudo?
# better to do it before switching user.
USER root
RUN mkdir -p /Users && ln -s /home/node /Users/jason
USER node

# Entrypoint - just run shell or claude
ENTRYPOINT ["/bin/zsh"]
