# How exe.dev Runtime Injection Works

## Boot Sequence

1. **VM Boot**: The kernel boots with `init=/exe.dev/bin/exe-init`
2. **exe-init** (Go binary, PID 1 initially):
   - Reads `/exe.dev/etc/image.conf` (extracted from container's OCI config)
   - Starts `/exe.dev/bin/sshd` with `/exe.dev/etc/ssh/sshd_config`
   - sshd reads authorized_keys from `/exe.dev/etc/ssh/authorized_keys`
   - Execs the container's CMD (from image.conf), e.g., `/usr/local/bin/init`
3. **Container init** (`/usr/local/bin/init`):
   - Sets up cgroups, unprivileged ports
   - Execs `/sbin/init` (systemd)
4. **systemd** takes over as PID 1, sshd is reparented to it

## What exe.dev Injects at Runtime

These paths are injected by exe.dev and are not part of your container image.

### Core Infrastructure (`/exe.dev/`)

| Path | Purpose |
|------|---------|
| `/exe.dev/bin/exe-init` | Initial PID 1 that bootstraps everything |
| `/exe.dev/bin/sshd` | Musl-linked SSH daemon |
| `/exe.dev/bin/sftp-server` | SFTP server for file transfers |
| `/exe.dev/etc/image.conf` | Container OCI config (Cmd, Labels, Env) |
| `/exe.dev/etc/ssh/sshd_config` | SSH daemon configuration |
| `/exe.dev/etc/ssh/authorized_keys` | User's SSH public keys |
| `/exe.dev/etc/ssh/ssh_host_ed25519_key` | Host key for SSH |
| `/exe.dev/lib/ld-musl.so.1` | Musl dynamic linker for exe.dev binaries |

### Headless Chrome (`/headless-shell/`)

A headless Chromium browser for automation, screenshots, and PDF generation.

| Path | Purpose |
|------|---------|
| `/headless-shell/headless-shell` | Headless Chromium binary (~207MB) |
| `/headless-shell/run.sh` | Wrapper script to launch with DevTools Protocol |
| `/headless-shell/libEGL.so` | OpenGL ES/EGL library |
| `/headless-shell/libGLESv2.so` | OpenGL ES 2.0 implementation |
| `/headless-shell/libvk_swiftshader.so` | SwiftShader Vulkan (software renderer) |
| `/headless-shell/libvulkan.so.1` | Vulkan loader |
| `/headless-shell/vk_swiftshader_icd.json` | SwiftShader ICD config |
| `/headless-shell/.stamp` | Version stamp (e.g., `141.0.7390.55`) |

**Usage**: Run `/headless-shell/run.sh` to start headless Chrome with:
- Chrome DevTools Protocol on port 9222
- Software rendering via SwiftShader (no GPU required)
- `--no-sandbox` mode (container is already isolated)

Example with Puppeteer/Playwright:
```javascript
const browser = await puppeteer.launch({
  executablePath: '/headless-shell/headless-shell',
  args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader']
});
```

## Container Requirements

For exe.dev compatibility, your container image needs:

1. **Label**: `exe.dev/login-user` - specifies the SSH login user
2. **User**: Must exist with UID 1000
3. **PAM config**: `/etc/pam.d/sshd` (from `openssh-server` package)
4. **Init**: CMD should run systemd (or compatible init)
