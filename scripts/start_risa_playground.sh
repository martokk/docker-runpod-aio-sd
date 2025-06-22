#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

echo "RISA PLAYGROUND: Starting Risa Playground"

cd /workspace/apps/risa
export HF_HOME="/workspace/.cache/huggingface"

echo "RISA PLAYGROUND: Pulling latest changes..."
git pull
git checkout dev

echo "RISA PLAYGROUND: Installing dependencies..."
poetry env use /workspace/.cache/venvs/risa/bin/python
poetry install

echo "RISA PLAYGROUND: Starting Risa Playground..."
nohup poetry run python3 -m app >/workspace/.logs/risa_playground.log 2>&1 &

echo "RISA PLAYGROUND: Risa Playground started"
echo "RISA PLAYGROUND: Log file: /workspace/.logs/risa_playground.log"
