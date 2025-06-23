#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

echo "RISA PLAYGROUND: Starting Risa Playground"

cd /workspace/apps/risa
export HF_HOME="/workspace/.cache/huggingface"

echo "RISA PLAYGROUND: Pulling latest changes..."
git pull
git checkout dev

echo "RISA PLAYGROUND: Installing dependencies..."
source /workspace/.cache/venvs/risa/bin/activate
# Configure Poetry to use the existing virtual environment
poetry config virtualenvs.create false
poetry config virtualenvs.in-project false
poetry install --no-interaction --no-ansi

echo "RISA PLAYGROUND: Starting Risa Playground..."
nohup poetry run python3 -m app >/workspace/.logs/risa_playground.log 2>&1 &

echo "RISA PLAYGROUND: Risa Playground started"
echo "RISA PLAYGROUND: Log file: /workspace/.logs/risa_playground.log"
