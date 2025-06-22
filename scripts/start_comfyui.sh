#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

echo "COMFYUI: Starting ComfyUI"

source /workspace/.cache/venvs/comfyui/bin/activate

cd /workspace/apps/ComfyUI

TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

python3 /workspace/apps/ComfyUI/main.py --listen 0.0.0.0 --port 3021 >/workspace/.logs/comfyui.log 2>&1 &

echo "COMFYUI: ComfyUI started"
echo "COMFYUI: Log file: /workspace/.logs/comfyui.log"
deactivate
