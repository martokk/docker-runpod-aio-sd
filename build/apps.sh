#!/usr/bin/env bash
# Install Jupyter, gdown and OhMyRunPod
pip3 install -U --no-cache-dir jupyterlab \
    jupyterlab_widgets \
    ipykernel \
    ipywidgets \
    gdown \
    OhMyRunPod \
    yq

# Install code-server
curl -fsSL https://code-server.dev/install.sh | sh

# Install VS Code extensions from local VSIX files
code-server --install-extension /tmp/RSIP-Vision.nvidia-smi-plus-1.0.1.vsix
code-server --install-extension /tmp/vscode-ext.sync-rsync-0.36.0.vsix

# Install VS Code extensions
code-server --install-extension ms-python.python
code-server --install-extension ms-toolsai.jupyter
code-server --install-extension ms-toolsai.vscode-jupyter-powertoys

# Pre-install Jupyter kernel
python3 -m ipykernel install --name "python3" --display-name "Python 3"

# Install rclone
curl https://rclone.org/install.sh | bash

# Update rclone
rclone selfupdate

# Install runpodctl
wget "https://github.com/runpod/runpodctl/releases/download/${RUNPODCTL_VERSION}/runpodctl-linux-amd64" -O runpodctl &&
    chmod a+x runpodctl &&
    mv runpodctl /usr/local/bin

# Install croc
curl https://getcroc.schollz.com | bash

# Install speedtest CLI
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash &&
    apt install -y speedtest

# Install Risa Playground
cd /
git clone https://github.com/martokk/risa.git /apps/risa
cd /apps/risa
pip install poetry

python -m venv /venvs/risa
poetry env use /venvs/risa/bin/python
poetry install --no-interaction --no-ansi
