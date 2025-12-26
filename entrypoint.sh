#!/bin/bash
set -e

if [ ! -f ~/.zshrc ]; then
    echo "=== First run - setting up dotfiles ==="
    
    # Check if gh is authenticated
    if ! gh auth status &>/dev/null; then
        echo "Please authenticate with GitHub:"
        gh auth login
    fi
    
fi

exec "$@"
