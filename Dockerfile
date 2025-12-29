FROM ubuntu:24.04

LABEL exe.dev/login-user="exedev"

ENV DEBIAN_FRONTEND=noninteractive

# System packages
RUN apt-get update && apt-get install -y \
    curl git zsh sudo build-essential ca-certificates gnupg \
    python3 python3-pip \
    eza bat zoxide \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/batcat /usr/local/bin/bat

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 (includes npm and npx)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# uv (install to /usr/local so available for all users)
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Starship
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create user exedev with sudo
RUN useradd -m -s /bin/zsh exedev \
    && echo "exedev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


# Copy Claude configuration files
COPY CLAUDE.global.md /tmp/CLAUDE.global.md
COPY settings.json /tmp/settings.json
COPY skills /tmp/skills

# Copy shell configuration files
COPY zshrc /tmp/zshrc
COPY zshenv /tmp/zshenv
COPY zprofile /tmp/zprofile
COPY config/starship.toml /tmp/starship.toml

USER exedev
WORKDIR /home/exedev

# Install fzf from git (apt version is outdated)
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --all

# Setup per-user Claude configuration
RUN mkdir -p ~/.claude/skills ~/.claude/commands \
    && cp /tmp/CLAUDE.global.md ~/.claude/CLAUDE.md \
    && cp /tmp/settings.json ~/.claude/settings.json \
    && cp -r /tmp/skills/* ~/.claude/skills/

# Setup shell configuration
RUN mkdir -p ~/.config \
    && cp /tmp/zshrc ~/.zshrc \
    && cp /tmp/zshenv ~/.zshenv \
    && cp /tmp/zprofile ~/.zprofile \
    && cp /tmp/starship.toml ~/.config/starship.toml

# exe.dev requires container to run as root for SSH infrastructure setup
# The exe.dev/login-user label determines the SSH login user
USER root
WORKDIR /home/exedev
