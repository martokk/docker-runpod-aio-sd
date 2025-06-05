#!/usr/bin/env bash
set -e

# Install tensorboard into the system (no venv)
pip3 uninstall -y tensorboard tb-nightly
pip3 install tensorboard==2.15.2 tensorflow==2.15.0.post1
pip3 cache purge
