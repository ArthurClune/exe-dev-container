FROM ubuntu:24.04

LABEL exe.dev/login-user=exedev

# # Default proxy ports for exe.dev HTTPS proxy
# EXPOSE 8000 9999

ENV DEBIAN_FRONTEND=noninteractive

USER root
RUN touch /etc/.custom-image

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

# Create user exedev with sudo (UID 1000 required by exe.dev)
# Ubuntu 24.04 has a default 'ubuntu' user with UID 1000, remove it first
# Add to same groups as exeuntu base image, with matching GECOS field
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -s /bin/zsh -u 1000 -c "exe.dev user" -G adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev exedev \
    && echo "exedev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


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

RUN touch .hushlogin

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

# Copy and set up init script (required for systemd)
USER root
COPY files/init /usr/local/bin/init
RUN chmod +x /usr/local/bin/init

USER exedev
CMD ["/usr/local/bin/init"]
