#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

echo "WEBDAV: Starting WebDAV"
export HF_HOME="/workspace/.cache/huggingface"

echo "WEBDAV: Starting WebDAV..."
nohup wsgidav --host=0.0.0.0 --port=9999 --root=/workspace --auth=anonymous >/workspace/logs/webdav.log 2>&1 &
echo "WEBDAV: WebDAV started"
echo "WEBDAV: Log file: /workspace/logs/webdav.log"
