---
name: exe-test-image
description: Test the exe-dev-container image by spawning a new VM on exe.dev. Use to verify the container image works correctly with exe.dev SSH login.
---

# exe.dev Container Image Test Skill

This skill spawns a new exe.dev VM using the custom container image to verify it works correctly with exe.dev's SSH infrastructure.

## Image Location

The image is published to GitHub Container Registry:
```
ghcr.io/arthurclune/exe-dev-container:main
```

## Usage

When the user invokes this skill, perform the following steps:

### 1. Spawn a Test VM

Create a new VM with the custom image:

```bash
ssh exe.dev new --image=ghcr.io/arthurclune/exe-dev-container:main --name=container-test
```

If the name is taken, let exe.dev auto-generate one by omitting `--name`.

### 2. Wait and Connect

After the VM is created, exe.dev will output the VM name. SSH into it:

```bash
ssh <vmname>.exe.xyz
```

### 3. Run Validation Tests

Once connected, verify the environment:

```bash
# Check user and shell
whoami          # Should be: exedev
echo $SHELL     # Should be: /bin/zsh

# Check key tools
which claude gh node uv starship

# Check Claude configuration
ls ~/.claude/

# Test starship prompt
starship prompt

# Check zoxide
zoxide --version
```

### 4. Report Results

Report to the user:
- VM name and SSH command
- Whether login worked correctly
- Any issues found during validation
- The public URL: `https://<vmname>.exe.xyz/`

### 5. Cleanup (Optional)

Ask the user if they want to keep or delete the test VM:

```bash
ssh exe.dev rm <vmname>
```

## Expected Behavior

A successful test should show:
- SSH login works without password prompt
- User is `exedev` with zsh shell
- Starship prompt renders correctly
- All tools (claude, gh, node, uv, etc.) are available
- Claude Code configuration is present in ~/.claude/

## Troubleshooting

### Login fails
- Check that `exe.dev/login-user` label is set in Dockerfile
- Verify image was pushed to ghcr.io after latest changes

### Tools missing
- Image may be outdated, check GitHub Actions for latest build
- Verify Dockerfile installs all required packages

### Shell configuration issues
- Check that zshrc, zshenv, zprofile are copied correctly
- Verify TERM fix is present in zshenv
