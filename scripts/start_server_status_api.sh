#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

echo "SERVER_STATUS_API: Starting Server Status API"

cd /server_status_api
export HF_HOME="/workspace/.cache/huggingface"

echo "SERVER_STATUS_API: Pulling latest changes..."
git pull

echo "SERVER_STATUS_API: Installing dependencies..."
poetry install

echo "SERVER_STATUS_API: Starting Server Status API..."
nohup poetry run python3 -m app >/workspace/logs/server_status_api.log 2>&1 &
echo "SERVER_STATUS_API: Server Status API started"
echo "SERVER_STATUS_API: Log file: /workspace/logs/server_status_api.log"
