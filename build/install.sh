#!/usr/bin/env bash
set -e

mkdir -p /apps
mkdir -p /venvs

# Clone the git repo of the Stable Diffusion Web UI by Automatic1111
# and set version
cd /apps
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd /apps/stable-diffusion-webui
git checkout tags/${WEBUI_VERSION}

# Create and activate venv
python3 -m venv /venvs/a1111
source /venvs/a1111/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install torch and xformers
pip3 install --no-cache-dir torch==${TORCH_VERSION} torchvision torchaudio --index-url ${INDEX_URL}
pip3 install --no-cache-dir xformers==${XFORMERS_VERSION} --index-url ${INDEX_URL}
pip3 install tensorflow[and-cuda]

# Install A1111
pip3 install -r requirements_versions.txt
python3 -c "from launch import prepare_environment; prepare_environment()" --skip-torch-cuda-test

# Clone the Automatic1111 Extensions
git clone https://github.com/Mikubill/sd-webui-controlnet.git extensions/sd-webui-controlnet
git clone --depth=1 https://github.com/ashleykleynhans/a1111-sd-webui-locon.git extensions/a1111-sd-webui-locon
git clone --depth=1 https://github.com/zanllp/sd-webui-infinite-image-browsing.git extensions/infinite-image-browsing
git clone --depth=1 https://github.com/Bing-su/adetailer.git extensions/adetailer
git clone --depth=1 https://github.com/civitai/sd_civitai_extension.git extensions/sd_civitai_extension
git clone https://github.com/BlafKing/sd-civitai-browser-plus.git extensions/sd-civitai-browser-plus

# git clone --depth=1 https://codeberg.org/Gourieff/sd-webui-reactor.git extensions/sd-webui-reactor
# git clone --depth=1 https://github.com/Uminosachi/sd-webui-inpaint-anything.git extensions/inpaint-anything
# git clone --depth=1 https://github.com/deforum-art/sd-webui-deforum.git extensions/deforum
# git clone --depth=1 https://github.com/mcmonkeyprojects/sd-dynamic-thresholding extensions/sd-dynamic-thresholding

# Install dependencies for various extensions
# cd /stable-diffusion-webui/extensions/deforum
# pip3 install -r requirements.txt
# cd /stable-diffusion-webui/extensions/sd-webui-reactor
# pip3 install -r requirements.txt
# pip3 install onnxruntime-gpu
cd /apps/stable-diffusion-webui/extensions/infinite-image-browsing
pip3 install -r requirements.txt
cd /apps/stable-diffusion-webui/extensions/adetailer
python3 -m install
cd /apps/stable-diffusion-webui/extensions/sd_civitai_extension
pip3 install -r requirements.txt

# Install dynamic thresholding extension
# cd /stable-diffusion-webui/extensions/sd-dynamic-thresholding
# sed -i '/license = { file = "LICENSE.txt" }/d' pyproject.toml
# cat >>pyproject.toml <<'EOF'

# [tool.setuptools]
# py-modules = ["__init__"]
# EOF
# pip3 install .

# Install inpaint anything extension
# cd /stable-diffusion-webui/extensions/inpaint-anything
# python3 -m install

# Install dependencies for Civitai Browser+ extension
cd /apps/stable-diffusion-webui/extensions/sd-civitai-browser-plus
pip3 install send2trash beautifulsoup4 ZipUnicode fake-useragent packaging pysocks

# Install dependencies for ControlNet extension last so other extensions don't interfere with it
cd /apps/stable-diffusion-webui/extensions/sd-webui-controlnet
pip3 install -r requirements.txt
pip3 install protobuf==3.20.0
pip3 cache purge
deactivate

# Add inswapper model for the ReActor extension
# mkdir -p /stable-diffusion-webui/models/insightface
# cd /stable-diffusion-webui/models/insightface
# wget -O inswapper_128.onnx "https://huggingface.co/ashleykleynhans/inswapper/resolve/main/inswapper_128.onnx?download=true"

# Configure ReActor to use the GPU instead of the CPU
# echo "CUDA" >/stable-diffusion-webui/extensions/sd-webui-reactor/last_device.txt
