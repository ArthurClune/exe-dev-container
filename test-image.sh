#!/bin/bash
# Test harness for exe-dev-container image
# Builds locally and runs validation tests

set -e

IMAGE_NAME="exe-dev-container-test"
CONTAINER_NAME="exe-dev-test-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }
info() { echo -e "${YELLOW}→ $1${NC}"; }

cleanup() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        info "Cleaning up container..."
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# Change to script directory
cd "$(dirname "$0")"

echo "============================================"
echo "exe-dev-container Test Harness"
echo "============================================"
echo

# Test 1: Build the image
info "Building Docker image..."
if docker build -t "$IMAGE_NAME" . ; then
    pass "Image built successfully"
else
    fail "Image build failed"
fi
echo

# Test 2: Check required label exists
info "Checking exe.dev/login-user label..."
LABEL=$(docker inspect "$IMAGE_NAME" --format '{{index .Config.Labels "exe.dev/login-user"}}' 2>/dev/null || echo "")
if [ "$LABEL" = "exedev" ]; then
    pass "Label exe.dev/login-user=exedev is set"
else
    fail "Label exe.dev/login-user is missing or incorrect (got: '$LABEL')"
fi
echo

# Test 2b: Check container runs as root (required for exe.dev)
info "Checking container runs as root..."
IMGUSER=$(docker inspect "$IMAGE_NAME" --format '{{.Config.User}}' 2>/dev/null || echo "")
if [ "$IMGUSER" = "root" ] || [ -z "$IMGUSER" ]; then
    pass "Container runs as root (required for exe.dev SSH setup)"
else
    fail "Container runs as '$IMGUSER', must run as root for exe.dev"
fi
echo

# Test 3: Check user exists and has correct shell
info "Checking user configuration..."
docker run --rm "$IMAGE_NAME" id exedev >/dev/null 2>&1 && pass "User 'exedev' exists" || fail "User 'exedev' not found"

SHELL=$(docker run --rm "$IMAGE_NAME" getent passwd exedev | cut -d: -f7)
if [ "$SHELL" = "/bin/zsh" ]; then
    pass "User shell is /bin/zsh"
else
    fail "User shell is '$SHELL', expected /bin/zsh"
fi
echo

# Test 4: Check key tools are installed
info "Checking installed tools..."
TOOLS="zsh git node npm gh uv starship bat eza zoxide fzf claude"
for tool in $TOOLS; do
    if docker run --rm "$IMAGE_NAME" which "$tool" >/dev/null 2>&1; then
        pass "$tool is installed"
    else
        fail "$tool is not installed"
    fi
done
echo

# Test 5: Check shell configuration files
info "Checking shell configuration..."
for file in .zshrc .zshenv .zprofile; do
    if docker run --rm "$IMAGE_NAME" test -f "/home/exedev/$file"; then
        pass "$file exists"
    else
        fail "$file is missing"
    fi
done
echo

# Test 6: Check Claude configuration
info "Checking Claude Code configuration..."
for path in .claude/CLAUDE.md .claude/settings.json .claude/skills; do
    if docker run --rm "$IMAGE_NAME" test -e "/home/exedev/$path"; then
        pass "$path exists"
    else
        fail "$path is missing"
    fi
done
echo

# Test 7: Check starship config
info "Checking starship configuration..."
if docker run --rm "$IMAGE_NAME" test -f "/home/exedev/.config/starship.toml"; then
    pass "starship.toml exists"
else
    fail "starship.toml is missing"
fi
echo

# Test 8: Check sudo access
info "Checking sudo access..."
if docker run --rm "$IMAGE_NAME" sudo -n true 2>/dev/null; then
    pass "Passwordless sudo works"
else
    fail "Passwordless sudo not configured"
fi
echo

# Test 9: Test shell initialization (non-interactive)
info "Testing shell initialization..."
if docker run --rm "$IMAGE_NAME" zsh -c 'echo $SHELL' | grep -q '/bin/zsh'; then
    pass "Shell initializes correctly"
else
    fail "Shell initialization failed"
fi
echo

# Test 10: Check TERM fix in zshenv
info "Checking TERM fix in zshenv..."
if docker run --rm "$IMAGE_NAME" grep -q 'TERM.*dumb' /home/exedev/.zshenv; then
    pass "TERM fix is present in zshenv"
else
    fail "TERM fix is missing from zshenv"
fi
echo

echo "============================================"
echo -e "${GREEN}All tests passed!${NC}"
echo "============================================"
echo
echo "Next steps:"
echo "  1. Push changes to trigger GitHub Actions build"
echo "  2. Use /exe-test-image skill to spawn on exe.dev"
echo
