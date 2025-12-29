# Building Docker Images for exe.dev

This document explains the changes needed to make a standard Docker image work with exe.dev's SSH-based container access.

## Quick Reference

Your Dockerfile must have:

| Requirement | Example |
|-------------|---------|
| Login user label | `LABEL exe.dev/login-user="exedev"` |
| User with UID 1000 | `useradd -m -s /bin/zsh -u 1000 exedev` |
| Container runs as root | `USER root` at end of Dockerfile |
| EXEUNTU env var | `ENV EXEUNTU=1` |
| Expose ports | `EXPOSE 8000 9999` |

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
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -s /bin/zsh -u 1000 your-username \
    && echo "your-username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
```

Key points:
- Use `-u 1000` to set UID to 1000 (required by exe.dev)
- Use `-m` to create a home directory
- Use `-s /bin/zsh` or `-s /bin/bash` to set the login shell
- Grant sudo access if needed (recommended for development containers)

#### Ubuntu Base Image Note

Ubuntu 24.04 (and some other versions) ships with a default `ubuntu` user that already has UID 1000:

```
ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash
```

You must remove this user before creating your own user with UID 1000, otherwise `useradd -u 1000` will fail with "UID 1000 is not unique". The `userdel -r ubuntu` command removes both the user and their home directory. The `2>/dev/null || true` ensures the build doesn't fail if the user doesn't exist (for base images without a default user).

### 3. Container Must Run as Root

**Important**: exe.dev requires the container to run as root so it can set up SSH infrastructure. The `exe.dev/login-user` label determines which user SSH sessions use.

### 4. Set the EXEUNTU Environment Variable

exe.dev requires the `EXEUNTU=1` environment variable to identify compatible images:

```dockerfile
ENV EXEUNTU=1
```

Without this, SSH authentication will fail with "unable to authenticate".

### 5. Container Must End with USER root

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
EXPOSE 8000 9999
ENV EXEUNTU=1
ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get update && apt-get install -y \
    curl git zsh sudo \
    && rm -rf /var/lib/apt/lists/*

# Create user with sudo access (UID 1000 required)
# Remove default ubuntu user first (has UID 1000 in Ubuntu 24.04)
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -s /bin/zsh -u 1000 devuser \
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

## Connecting to Your VM

### SSH Connection Syntax

**Important**: exe.dev routes SSH connections based on the **username**, not the hostname. The user must be `exedev`

```bash
# Correct - connects to VM named "myvm"
ssh exedev@myvm.exe.xyz

# WRONG - connects to VM named "arthur", not "myvm"!
ssh arthur@myvm.exe.xyz
```

## Troubleshooting

### SSH Authentication Fails ("SSH keys are required")

**Cause**: User UID is not 1000, or container is not running as root.

**Fix**: Ensure your Dockerfile has:
```dockerfile
RUN useradd -m -s /bin/zsh -u 1000 your-username  # Note: -u 1000
# ... at end of file:
USER root
```

**Verify**:
```bash
docker inspect your-image --format '{{.Config.User}}'  # Should be: root (or empty)
docker run --rm your-image id your-username            # Should show: uid=1000
```

### Logs In As Root Instead of Expected User

**Cause**: Missing `exe.dev/login-user` label.

**Fix**: Add the label to your Dockerfile:
```dockerfile
LABEL exe.dev/login-user=exedev
```

### Shell Configuration Not Loading

**Cause**: ENTRYPOINT scripts don't run for SSH logins.

**Fix**: Put setup in shell config files (`~/.zshrc`, `~/.zprofile`, `~/.bashrc`) instead of entrypoint scripts.

### TERM Variable Issues (No Colors, Broken Prompt)

**Cause**: Some SSH clients or terminal emulators don't set TERM properly.

**Fix**: Add to `~/.zshenv` or `~/.bashrc`:
```bash
[[ "$TERM" == "dumb" || -z "$TERM" ]] && export TERM=xterm-256color
```

### SSH Connects to Wrong VM

**Cause**: You specified a username in the SSH command.

exe.dev uses the SSH username to determine which VM to connect to:
```bash
ssh alice@myvm.exe.xyz  # Connects to VM "alice", NOT "myvm"!
```

**Fix**: User must be exedev
```bash
ssh exedev@myvm.exe.xyz  # Connects to VM "myvm"
```
