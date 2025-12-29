# exe.dev Environment

You are running in an exe.dev VM - a virtual machine with persistent disk, on the internet.

## Quick Reference

### Environment
- **Disk**: Persistent across reboots
- **Network**: Full internet access
- **Database**: SQLite works great, use freely

### Installed Tools
- **Python**: `python3`, `uv` (fast package manager)
- **Node.js**: `node`, `npm`
- **GitHub CLI**: `gh` (authenticate with `gh auth login`)

### Common Commands
```bash
# Python
uv pip install <pkg>          # Install packages
uv venv && source .venv/bin/activate  # Create venv
uv run script.py              # Run without venv

# Node.js
npm install <pkg>             # Install packages

# GitHub
gh auth login                 # Authenticate
```

## Skills

Use these specialized skills for common exe.dev workflows:

- **exe-web-deploy**: Deploy web applications with automatic HTTPS proxy
  - Use when: Running web servers, deploying apps, exposing services

- **exe-systemd-service**: Create persistent services that survive reboots
  - Use when: Running background services, auto-starting apps, ensuring restart on failure

## Important Notes

- **Web servers**: Always bind to `localhost` (ports 3000-9999 auto-proxied to HTTPS)
- **Public URLs**: Access at `https://<vmname>.exe.xyz:<port>/`
- **Privacy**: Sites are private by default (`ssh exe.dev share set-public <vm>` to make public)
- **Auth headers**: `X-ExeDev-UserID` and `X-ExeDev-Email` available when users are authenticated

For detailed proxy information: https://exe.dev/docs/proxy.md
