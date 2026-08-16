# Unsloth Studio by Scalland (Ubuntu 24.04 + CUDA 12.6)

A lean, zero-bloat Docker template for deploying Unsloth Studio with full GPU acceleration on RunPod built in [Scalland Consultancy Services](https://scalland.com). You can also use this [docker image](https://hub.docker.com/r/scallandtech/unsloth-studio/tags) directly on your local machine.

## Description

This template provides an optimized environment for running, fine-tuning, and serving large language models (LLMs) like Qwen, Llama, and DeepSeek using Unsloth Studio. Built on top of Ubuntu 24.04 LTS and NVIDIA CUDA 12.6 development toolkits, it pre-configures Unsloth Studio, accelerated CUDA backends, and Python dependencies. It routes all model caching, databases, and Hugging Face weights to persistent network volumes mounted at `/workspace`, preventing data loss across pod restarts while exposing native Web UI and OpenAI-compatible API endpoints.

## Getting Started

### Dependencies

* An active [RunPod](https://www.runpod.io/) account with compute credits.
* An NVIDIA GPU pod instance (e.g., RTX 3090, RTX 4090, RTX A6000, L40S, or A100).
* (Optional) Hugging Face Access Token (`HF_TOKEN`) for gated models.
* SSH client installed locally (OpenSSH, PowerShell, or Git Bash).

### Using the template

* **Deploy the Pod:**
  1. Go to **RunPod Console** -> **Pods** -> **Deploy**.
  2. Select your preferred GPU and pick this template: `scallandtech/unsloth-studio:24.04` (or `shammishailaj/unsloth-studio:24.04`).
  3. Set **Container Disk** to `25 GB` and **Volume Disk** to `100 GB+` mounted at `/workspace`.
  4. Ensure HTTP ports `8888, 8000` and TCP port `22` are open.

* **Connect to the Web UI:**
  * Direct access: Click **Connect** -> **Connect to Port 8888** on your RunPod pod dashboard.
  * Direct SSH tunnel (recommended to prevent timeout issues on large prompts):

```bash
# Forward Studio UI (8888) and API server (8000) to localhost
ssh -L 8888:localhost:8888 -L 8000:localhost:8000 root@<POD_IP> -p <POD_SSH_PORT> -i ~/.ssh/id_ed25519
```

* **CLI Execution & Inference:**

```bash
# Serve model with custom context length
unsloth run --model unsloth/Qwen3.8-27B-GGUF:UD-Q6_K_XL --ctx-size 262144

# Launch Studio with a public Cloudflare tunnel
unsloth studio --secure
```

## Help

* **RunPod 60-Second Proxy Disconnect:** RunPod's built-in HTTP proxy times out after 60s of idle response during massive prompt prefills. Use direct SSH port forwarding (`-L 8888:localhost:8888`) or launch with `unsloth studio --secure`.
* **Persistent Weights:** Verify `HF_HOME=/workspace/.cache/huggingface` is set so model downloads persist across pod restarts.

```bash
# Verify GPU availability
nvidia-smi

# Check installed Unsloth Studio version
unsloth --version
```

## Authors

[![LinkedIn - Scalland Consultancy Services](https://img.shields.io/badge/LinkedIn-Scalland_Consultancy_Services-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/company/scalland/)

[![LinkedIn - Shammi Shailaj](https://img.shields.io/badge/LinkedIn-Shammi_Shailaj-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/shammishailaj/)

[![Reach Us - Scalland Consultancy Services](https://img.shields.io/badge/Reach_Us-Scalland_Consultancy_Services-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://scalland.com/contactus)


## Docker Details

<!-- Docker Hub & Social Badges -->
[![Docker Hub - scallandtech](https://img.shields.io/badge/Docker_Hub-scallandtech%2Funsloth--studio-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/r/scallandtech/unsloth-studio)

[![Docker Pulls](https://img.shields.io/docker/pulls/scallandtech/unsloth-studio?style=for-the-badge&logo=docker&logoColor=white&color=0db7ed)](https://hub.docker.com/r/scallandtech/unsloth-studio)

[![Docker Image Size](https://img.shields.io/docker/image-size/scallandtech/unsloth-studio/24.04?style=for-the-badge&logo=docker&logoColor=white&color=blue)](https://hub.docker.com/r/scallandtech/unsloth-studio)


## Version History

* 24.04
    * Base OS: Ubuntu 24.04 LTS with NVIDIA CUDA 12.6.3 development toolkits.
    * Pinned `UNSLOTH_TORCH_INDEX_FAMILY=cu126` to guarantee CUDA-enabled PyTorch and GPU inference backends during headless container builds.
    * Configured NVIDIA container runtime flags (`NVIDIA_VISIBLE_DEVICES=all`, `NVIDIA_DRIVER_CAPABILITIES=compute,utility`).
    * Isolated Unsloth Studio binaries in the immutable image layer (`/root/.unsloth/studio`) to prevent persistent volume shadowing when mounting `/workspace`.
    * Pre-configured persistent Hugging Face cache under `/workspace/.cache/huggingface`.
* ubuntu2404-unsloth2026.6.18
    * Initial Release

