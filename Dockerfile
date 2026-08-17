# Base: Official NVIDIA CUDA 12.6 Development build on Ubuntu 24.04 LTS
FROM nvidia/cuda:12.6.3-devel-ubuntu24.04

# Prevent interactive debconf prompts during apt installation
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# NVIDIA Container Runtime environment variables
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Explicitly pin PyTorch CUDA 12.6 index family for headless Docker builds
ENV UNSLOTH_TORCH_INDEX_FAMILY=cu126

# Permanent system directory for Unsloth Studio environment
ENV UNSLOTH_STUDIO_HOME="/opt/unsloth/studio"
ENV HF_HOME="/workspace/.cache/huggingface"

# llama.cpp prebuilt location (downloaded at container startup with GPU present)
ENV UNSLOTH_LLAMA_CPP_PATH="/opt/unsloth/llama.cpp"

# Force CUDA backend for llama.cpp prebuilt selection
ENV UNSLOTH_LLAMA_CPP_BACKEND="cuda"

# Global paths for Unsloth Studio binaries and virtual environment
ENV PATH="/opt/unsloth/studio/bin:/opt/unsloth/studio/unsloth_studio/bin:/root/.local/bin:$PATH"

# Default Studio web UI authentication password
ENV UNSLOTH_STUDIO_PASSWORD="scalland"

# Install fundamental build tools, networking utilities, and Python 3
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    build-essential \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Run the official Unsloth Studio installer with CUDA 12.6 pre-configuration into /opt/unsloth/studio.
# NOTE: llama.cpp prebuilt binaries (llama-server) are NOT installed here because the build
# environment has no GPU. They are downloaded at container startup by entrypoint.sh via
# 'unsloth studio setup' when the NVIDIA runtime provides GPU access.
RUN mkdir -p /opt/unsloth/studio /opt/unsloth/llama.cpp && \
    UNSLOTH_STUDIO_HOME=/opt/unsloth/studio curl -fsSL https://unsloth.ai/install.sh | sh || true && \
    mkdir -p /root/.unsloth && \
    ln -sfn /opt/unsloth/studio /root/.unsloth/studio && \
    ln -sfn /opt/unsloth/studio/unsloth_studio/bin/unsloth /usr/local/bin/unsloth && \
    ln -sfn /opt/unsloth/studio/unsloth_studio/bin/unsloth /usr/bin/unsloth && \
    echo 'export UNSLOTH_STUDIO_HOME="/opt/unsloth/studio"' >> /etc/bash.bashrc && \
    echo 'export STUDIO_HOME="/opt/unsloth/studio"' >> /etc/bash.bashrc && \
    echo 'export PATH="/opt/unsloth/studio/bin:/opt/unsloth/studio/unsloth_studio/bin:/root/.local/bin:$PATH"' >> /etc/bash.bashrc && \
    echo 'export HF_HOME="/workspace/.cache/huggingface"' >> /etc/bash.bashrc && \
    echo 'export UNSLOTH_STUDIO_PASSWORD="scalland"' >> /etc/bash.bashrc

# Copy runtime entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set default workspace directory
WORKDIR /workspace

# Expose Studio Web UI (8888) and backend API server (8000)
EXPOSE 8888
EXPOSE 8000

# Set entrypoint and default launch command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["unsloth", "studio", "-H", "0.0.0.0", "-p", "8888"]



