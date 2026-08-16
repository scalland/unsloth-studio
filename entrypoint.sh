#!/usr/bin/env bash
set -e

# Export Unsloth Studio environment variables
export UNSLOTH_STUDIO_HOME="/opt/unsloth/studio"
export STUDIO_HOME="/opt/unsloth/studio"
export PATH="/opt/unsloth/studio/bin:/opt/unsloth/studio/unsloth_studio/bin:/root/.local/bin:$PATH"
export HF_HOME="${HF_HOME:-/workspace/.cache/huggingface}"
export UNSLOTH_STUDIO_PASSWORD="${UNSLOTH_STUDIO_PASSWORD:-scalland}"

# Ensure symlinks exist in /root, /workspace, and current $HOME for zero-dependency resolution
mkdir -p /root/.unsloth
ln -sfn /opt/unsloth/studio /root/.unsloth/studio

if [ -d "/workspace" ]; then
    mkdir -p /workspace/.unsloth 2>/dev/null || true
    ln -sfn /opt/unsloth/studio /workspace/.unsloth/studio 2>/dev/null || true
    mkdir -p /workspace/.cache/huggingface 2>/dev/null || true
fi

if [ -n "${HOME:-}" ] && [ "$HOME" != "/root" ] && [ "$HOME" != "/workspace" ]; then
    mkdir -p "$HOME/.unsloth" 2>/dev/null || true
    ln -sfn /opt/unsloth/studio "$HOME/.unsloth/studio" 2>/dev/null || true
fi

# Execute command with proper venv resolution
if [ $# -eq 0 ]; then
    exec /opt/unsloth/studio/unsloth_studio/bin/unsloth studio -H 0.0.0.0 -p 8888
elif [ "$1" = "unsloth" ]; then
    exec /opt/unsloth/studio/unsloth_studio/bin/unsloth "${@:2}"
elif [ "$1" = "studio" ]; then
    exec /opt/unsloth/studio/unsloth_studio/bin/unsloth studio "${@:2}"
else
    exec "$@"
fi
