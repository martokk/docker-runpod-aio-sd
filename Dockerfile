# Stage 1: Base
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/London \
    PYTHONUNBUFFERED=1 \
    SHELL=/bin/bash

# Install Ubuntu packages
ARG PYTHON_VERSION
COPY --chmod=755 build/packages.sh /packages.sh
RUN /packages.sh && rm /packages.sh

# Install Torch and xformers
ARG INDEX_URL
ARG TORCH_VERSION
ARG XFORMERS_VERSION

RUN pip3 install --no-cache-dir torch==${TORCH_VERSION} torchvision torchaudio --index-url ${INDEX_URL} && \
    pip3 install --no-cache-dir xformers==${XFORMERS_VERSION} --index-url ${INDEX_URL}

# Stage 2: Install applications
FROM base AS setup

# Install apps
ARG RUNPODCTL_VERSION
ENV RUNPODCTL_VERSION=${RUNPODCTL_VERSION}
COPY code-server/vsix/*.vsix /tmp/
COPY code-server/settings.json /root/.local/share/code-server/User/settings.json
COPY --chmod=755 build/apps.sh /apps.sh
RUN /apps.sh && rm /apps.sh

# Copy the build scripts
WORKDIR /
COPY --chmod=755 build/* ./

# Install A1111
ARG TORCH_VERSION
ARG XFORMERS_VERSION
ARG INDEX_URL
ARG WEBUI_VERSION
ARG CONTROLNET_COMMIT
ARG CIVITAI_BROWSER_PLUS_VERSION

RUN /install.sh

# Install Application Manager
WORKDIR /
ARG APP_MANAGER_VERSION
RUN git clone https://github.com/ashleykleynhans/app-manager.git /app-manager && \
    cd /app-manager && \
    git checkout tags/${APP_MANAGER_VERSION} && \
    npm install
COPY app-manager/config.json /app-manager/public/config.json

# Install Server Status API
RUN pip install poetry
WORKDIR /
ARG SERVER_STATUS_API_VERSION

# Clone the repo and install with Poetry into a fixed venv location
RUN git clone https://github.com/amrtokk/server_status_api.git /server_status_api && \
    cd /server_status_api && \
    poetry config virtualenvs.in-project false && \
    poetry config virtualenvs.path /workspace/venvs && \
    poetry install --no-interaction --no-ansi

# Install CivitAI Model Downloader
ARG CIVITAI_DOWNLOADER_VERSION
RUN git clone https://github.com/ashleykleynhans/civitai-downloader.git && \
    cd civitai-downloader && \
    git checkout tags/${CIVITAI_DOWNLOADER_VERSION} && \
    cp download.py /usr/local/bin/download-model && \
    chmod +x /usr/local/bin/download-model && \
    cd .. && \
    rm -rf civitai-downloader

# Copy Stable Diffusion Web UI config files
COPY a1111/relauncher.py a1111/webui-user.sh a1111/config.json a1111/ui-config.json /stable-diffusion-webui/

# ADD SDXL styles.csv
ADD https://raw.githubusercontent.com/Douleb/SDXL-750-Styles-GPT4-/main/styles.csv /stable-diffusion-webui/styles.csv


# Install InvokeAI
ARG INDEX_URL

# Stage 2: InvokeAI Installation
FROM base AS invokeai-install
ARG INVOKEAI_VERSION
ARG INVOKEAI_TORCH_VERSION
ARG INVOKEAI_XFORMERS_VERSION
WORKDIR /
COPY --chmod=755 build/install_invokeai.sh ./
RUN /install_invokeai.sh && rm /install_invokeai.sh

# Copy InvokeAI config file
COPY invokeai/invokeai.yaml /InvokeAI/

# Install Kohya_ss
FROM invokeai-install AS kohya-install
ARG KOHYA_VERSION
ARG KOHYA_TORCH_VERSION
ARG KOHYA_XFORMERS_VERSION
WORKDIR /
COPY kohya_ss/requirements* ./
COPY --chmod=755 build/install_kohya.sh ./
RUN /install_kohya.sh && rm /install_kohya.sh

# Copy the accelerate configuration
COPY kohya_ss/accelerate.yaml ./

# Install ComfyUI
FROM kohya-install AS comfyui-install
ARG COMFYUI_COMMIT
ARG COMFYUI_TORCH_VERSION
ARG COMFYUI_XFORMERS_VERSION
WORKDIR /
COPY --chmod=755 build/install_comfyui.sh ./
RUN /install_comfyui.sh && rm /install_comfyui.sh

# Copy ComfyUI Extra Model Paths (to share models with A1111)
COPY comfyui/extra_model_paths.yaml /ComfyUI/

# Install Tensorboard
FROM comfyui-install AS tensorboard-install
WORKDIR /
COPY --chmod=755 build/install_tensorboard.sh ./
RUN /install_tensorboard.sh && rm /install_tensorboard.sh

# Finalise Image
FROM tensorboard-install AS final


# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/502.html /usr/share/nginx/html/502.html

# Application Manager config
COPY app-manager/config.json /app-manager/public/config.json

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Set the venv path
ARG VENV_PATH
ENV VENV_PATH=${VENV_PATH}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* ./
RUN mv /manage_venv.sh /usr/local/bin/manage_venv

# Start the container
ARG REQUIRED_CUDA_VERSION
ENV REQUIRED_CUDA_VERSION=${REQUIRED_CUDA_VERSION}
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
