FROM ghcr.io/boldsoftware/exeuntu:latest

LABEL exe.dev/login-user="exedev"

ENV DEBIAN_FRONTEND=noninteractive

# System packages
# Note: openssh-server provides /etc/pam.d/sshd needed by exe.dev's sshd
# libssh-gcrypt-4 and openssh-sftp-server match exeuntu base image
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

# Copy Claude configuration files (chown to exedev for later copy)
COPY --chown=1000:1000 files/claude/CLAUDE.global.md /tmp/CLAUDE.global.md
COPY --chown=1000:1000 files/claude/settings.json /tmp/settings.json
COPY --chown=1000:1000 files/claude/skills /tmp/skills

# Copy shell configuration files
COPY --chown=1000:1000 files/shell/zshrc /tmp/zshrc
COPY --chown=1000:1000 files/shell/zshenv /tmp/zshenv
COPY --chown=1000:1000 files/shell/zprofile /tmp/zprofile
COPY --chown=1000:1000 files/config/starship.toml /tmp/starship.toml

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

CMD ["/usr/local/bin/init"]
