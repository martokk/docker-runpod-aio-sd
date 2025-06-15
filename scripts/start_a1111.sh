#!/usr/bin/env bash
export PYTHONUNBUFFERED=1
echo "A1111: Starting Stable Diffusion Web UI"
cd /workspace/stable-diffusion-webui
export HF_HOME="/workspace"
export HF_HOME="/workspace/.cache/huggingface"
echo "A1111: Stable Diffusion Web UI started"
echo "A1111: Log file: /workspace/logs/webui.log"
