#!/usr/bin/env bash
set -euo pipefail

# ── Export Unsloth Studio environment variables ──
export UNSLOTH_STUDIO_HOME="/opt/unsloth/studio"
export STUDIO_HOME="/opt/unsloth/studio"
export PATH="/opt/unsloth/studio/bin:/opt/unsloth/studio/unsloth_studio/bin:/root/.local/bin:$PATH"
export HF_HOME="${HF_HOME:-/workspace/.cache/huggingface}"
export UNSLOTH_STUDIO_PASSWORD="${UNSLOTH_STUDIO_PASSWORD:-scalland}"

# ── Ensure home/workspace symlinks for zero-dependency resolution ──
# RunPod may mount /workspace as HOME or change HOME after the build.
mkdir -p /root/.unsloth 2>/dev/null || true
ln -sfn /opt/unsloth/studio /root/.unsloth/studio 2>/dev/null || true

if [ -d "/workspace" ]; then
    mkdir -p /workspace/.unsloth 2>/dev/null || true
    ln -sfn /opt/unsloth/studio /workspace/.unsloth/studio 2>/dev/null || true
    mkdir -p /workspace/.cache/huggingface 2>/dev/null || true
fi

if [ -n "${HOME:-}" ] && [ "$HOME" != "/root" ] && [ "$HOME" != "/workspace" ]; then
    mkdir -p "$HOME/.unsloth" 2>/dev/null || true
    ln -sfn /opt/unsloth/studio "$HOME/.unsloth/studio" 2>/dev/null || true
fi

UNSLOTH_BIN="/opt/unsloth/studio/unsloth_studio/bin/unsloth"
UNSLOTH_PYTHON="/opt/unsloth/studio/unsloth_studio/bin/python"

# ── Install llama.cpp prebuilt at runtime (requires GPU) ──
# The Docker build environment (GitHub Actions) has no GPU, so the prebuilt
# llama-server binary cannot be downloaded during `docker build`. We download
# it at container startup when the NVIDIA GPU is accessible via the runtime.
LLAMA_CPP_DIR="/opt/unsloth/llama.cpp"
export UNSLOTH_LLAMA_CPP_PATH="$LLAMA_CPP_DIR"

_setup_llama_cpp() {
    echo "==> [startup] llama.cpp prebuilt not found – running 'unsloth studio setup'..."
    echo "==> [startup] This downloads the CUDA llama-server for your GPU arch; takes ~1-2 min."
    mkdir -p "$LLAMA_CPP_DIR" 2>/dev/null || true
    # UNSLOTH_LLAMA_CPP_BACKEND=cuda  → force CUDA prebuilt (not CPU/Vulkan)
    # UNSLOTH_STUDIO_LLAMA_ONLY=1     → only download/update llama.cpp, skip
    #                                    frontend/python stack (already done)
    UNSLOTH_STUDIO_HOME="$UNSLOTH_STUDIO_HOME" \
    UNSLOTH_LLAMA_CPP_PATH="$LLAMA_CPP_DIR" \
    UNSLOTH_LLAMA_CPP_BACKEND="${UNSLOTH_LLAMA_CPP_BACKEND:-cuda}" \
        "$UNSLOTH_BIN" studio setup 2>&1 | sed 's/^/  [setup] /' || {
        echo "==> [WARN] llama.cpp setup encountered errors; GGUF inference may be limited."
        echo "==>        Retry manually: unsloth studio setup"
    }
}

if [ ! -f "$LLAMA_CPP_DIR/UNSLOTH_PREBUILT_INFO.json" ]; then
    _setup_llama_cpp
else
    echo "==> [startup] llama.cpp prebuilt already installed."
fi

# ── Pre-seed Studio settings: Remote Access API auto-start ──
# Unsloth Studio stores user settings in a SQLite DB at
#   $UNSLOTH_STUDIO_HOME/settings.db  (or similar)
# The "Remote Access → Start Automatically" toggle maps to a settings key.
# We pre-seed it here so the API starts immediately on first boot.
_preseed_settings() {
    "$UNSLOTH_PYTHON" - <<'PYEOF' 2>/dev/null || true
import sqlite3, os, pathlib, json

studio_home = pathlib.Path(os.environ.get("UNSLOTH_STUDIO_HOME", "/opt/unsloth/studio"))

# Studio may store settings in different DB files depending on version.
# Try common locations.
db_candidates = [
    studio_home / "settings.db",
    studio_home / "auth" / "auth.db",
    studio_home / "studio.db",
]

# Settings we want to pre-seed:
# remote_access_enabled  = true  → "Start Automatically" enabled
# remote_access_port     = 8000  → API port
settings_to_seed = {
    "remote_access_enabled": "true",
    "remote_access_auto_start": "true",
    "remote_access_port": "8000",
}

for db_path in db_candidates:
    if not db_path.exists():
        continue
    try:
        conn = sqlite3.connect(str(db_path))
        conn.execute("PRAGMA busy_timeout=3000")
        # Check if a settings table exists
        tables = {row[0] for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
        )}
        if "app_settings" in tables or "settings" in tables:
            tbl = "app_settings" if "app_settings" in tables else "settings"
            for key, value in settings_to_seed.items():
                conn.execute(
                    f"INSERT OR REPLACE INTO {tbl} (key, value) VALUES (?, ?)",
                    (key, value)
                )
            conn.commit()
            print(f"  [startup] Pre-seeded Remote Access settings in {db_path}")
        conn.close()
    except Exception as e:
        print(f"  [startup] Could not seed settings in {db_path}: {e}")
PYEOF
}

_preseed_settings

# ── Launch Studio ──
echo "==> [startup] Starting Unsloth Studio..."

if [ $# -eq 0 ]; then
    exec "$UNSLOTH_BIN" studio -H 0.0.0.0 -p 8888
elif [ "$1" = "unsloth" ]; then
    exec "$UNSLOTH_BIN" "${@:2}"
elif [ "$1" = "studio" ]; then
    exec "$UNSLOTH_BIN" studio "${@:2}"
else
    exec "$@"
fi
