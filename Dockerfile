# Base: Official NVIDIA CUDA 12.6 Development build on Ubuntu 24.04 LTS
FROM nvidia/cuda:12.6.3-devel-ubuntu24.04

# Prevent interactive debconf prompts during apt installation
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Global paths for Unsloth Studio binaries and HF cache
ENV PATH="/root/.local/bin:/workspace/.studio/bin:$PATH"
ENV UNSLOTH_STUDIO_HOME="/workspace/.studio"
ENV HF_HOME="/workspace/.cache/huggingface"

# Install fundamental build tools, networking utilities, and Python 3
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Run the official Unsloth Studio installer
RUN curl -fsSL https://unsloth.ai/install.sh | sh

# Set default workspace directory
WORKDIR /workspace

# Expose Studio Web UI (8888) and backend API server (8000)
EXPOSE 8888
EXPOSE 8000

# Start Unsloth Studio bound to 0.0.0.0 on container launch
CMD ["unsloth", "studio", "-H", "0.0.0.0", "-p", "8888"]
