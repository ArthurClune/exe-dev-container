# Building Docker Images for exe.dev

This document explains the changes needed to make a standard Docker image work with exe.dev's SSH-based container access.

## Required Changes

### 1. Add the Login User Label

exe.dev needs to know which user to use for SSH logins. Add this label to your Dockerfile:

```dockerfile
LABEL exe.dev/login-user="your-username"
```

This label tells exe.dev which user account to use when establishing SSH sessions.

### 2. Create a Non-Root User with UID 1000

Create a user that matches the label above with **UID 1000**:

```dockerfile
RUN useradd -m -s /bin/zsh -u 1000 your-username \
    && echo "your-username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
```

Key points:
- Use `-u 1000` to set UID to 1000 (required by exe.dev)
- Use `-m` to create a home directory
- Use `-s /bin/zsh` or `-s /bin/bash` to set the login shell
- Grant sudo access if needed (recommended for development containers)

### 3. Container Must Run as Root

**Important**: exe.dev requires the container to run as root so it can set up SSH infrastructure. The `exe.dev/login-user` label determines which user SSH sessions use.

```dockerfile
# Do user-specific setup first
USER your-username
RUN setup-user-stuff...

# Then switch back to root at the end
USER root
WORKDIR /home/your-username
```

Do NOT leave `USER your-username` as the final user - exe.dev's init process needs root to configure `/exe.dev/`.

## What exe.dev Provides

When your container runs on exe.dev, the platform automatically injects:

- **`/exe.dev/bin/`** - Custom SSH daemon, SFTP server, and utilities
- **`/exe.dev/etc/ssh/`** - SSH configuration and host keys
- **`/exe.dev/etc/ssh/authorized_keys`** - Your SSH public keys

You don't need to install or configure SSH in your image - exe.dev handles this.

## What NOT to Do

### Don't Rely on ENTRYPOINT for Setup

Docker's `ENTRYPOINT` only runs when using `docker run`. It does **not** run when SSH-ing into the container. If you need first-run setup, put it in shell configuration files like `~/.zprofile` or `~/.bashrc`.

```dockerfile
# Won't work for SSH logins:
ENTRYPOINT ["/entrypoint.sh"]

# Instead, use CMD for the default shell:
CMD ["/bin/zsh"]
```

### Don't Install SSH Server

exe.dev provides its own SSH infrastructure. Installing openssh-server is unnecessary and may conflict.

## Shell Configuration Tips

### Handle Missing TERM Variable

Some edge cases (like `su -`) may not set TERM properly. Add this to your shell config:

```bash
# In ~/.zshenv or ~/.bashrc
[[ "$TERM" == "dumb" || "$TERM" == "unknown" || -z "$TERM" ]] && export TERM=xterm-256color
```

### Login Shell Initialization Order

For **zsh**:
1. `/etc/zsh/zshenv` (system-wide)
2. `~/.zshenv` (user environment variables)
3. `~/.zprofile` (login shell profile)
4. `~/.zshrc` (interactive shell config)

For **bash**:
1. `/etc/profile` (system-wide)
2. `~/.bash_profile` or `~/.profile` (login shell)
3. `~/.bashrc` (interactive shell)

## Example Dockerfile

```dockerfile
FROM ubuntu:24.04

LABEL exe.dev/login-user="devuser"

ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get update && apt-get install -y \
    curl git zsh sudo \
    && rm -rf /var/lib/apt/lists/*

# Create user with sudo access (UID 1000 required)
RUN useradd -m -s /bin/zsh -u 1000 devuser \
    && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy shell configuration
COPY zshrc /tmp/zshrc

# Switch to user for user-specific setup
USER devuser
RUN cp /tmp/zshrc ~/.zshrc

# Switch back to root for exe.dev compatibility
USER root
WORKDIR /home/devuser
```

## Exposing Ports

exe.dev automatically proxies HTTP traffic. Use `EXPOSE` to declare ports:

```dockerfile
EXPOSE 3000 8080
```

Access via `https://your-vm.exe.xyz` (default port) or `https://your-vm.exe.xyz:3000/` for specific ports.
