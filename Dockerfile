### Stage 1: Base ### =================================================================================
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/London \
    PYTHONUNBUFFERED=1 \
    SHELL=/bin/bash

# Install Ubuntu packages
ARG PYTHON_VERSION
COPY --chmod=755 build/packages.sh /packages.sh
RUN /packages.sh && rm /packages.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Torch and xformers
ARG INDEX_URL
ARG TORCH_VERSION
ARG XFORMERS_VERSION

RUN pip3 install --no-cache-dir torch==${TORCH_VERSION} torchvision torchaudio --index-url ${INDEX_URL} && \
    pip3 install --no-cache-dir xformers==${XFORMERS_VERSION} --index-url ${INDEX_URL}


### Stage 2: Install Base Aplications ### ================================================================
WORKDIR /

# Pre-Install: Copy the build scripts and application files
COPY --chmod=755 build/* ./
COPY code-server/vsix/*.vsix /tmp/
COPY code-server/settings.json /root/.local/share/code-server/User/settings.json

# Install: Apps
ARG RUNPODCTL_VERSION
ENV RUNPODCTL_VERSION=${RUNPODCTL_VERSION}
ARG APP_MANAGER_VERSION
RUN /apps.sh && rm /apps.sh

# Post-Install: Copy app files
COPY app-manager/config.json /app-manager/public/config.json


### Stage 3: Install A1111 ### ========================================================================
WORKDIR /

# Install: A1111
ARG TORCH_VERSION
ARG XFORMERS_VERSION
ARG INDEX_URL
ARG WEBUI_VERSION
ARG CONTROLNET_COMMIT
ARG CIVITAI_BROWSER_PLUS_VERSION
RUN /install.sh

# Post-Install:
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


### Stage 4: Install InvokeAI ### =====================================================================
WORKDIR /

# Install: InvokeAI
ARG INDEX_URL
ARG INVOKEAI_VERSION
ARG INVOKEAI_TORCH_VERSION
ARG INVOKEAI_XFORMERS_VERSION
RUN /install_invokeai.sh && rm /install_invokeai.sh

# Post-Install: Copy InvokeAI config file
COPY invokeai/invokeai.yaml /InvokeAI/


### Stage 5: Install Kohya_ss ### =====================================================================
WORKDIR /

# Pre-Install: Copy the build scripts and application files
COPY kohya_ss/requirements* ./

# Install: Kohya_ss
ARG KOHYA_VERSION
ARG KOHYA_TORCH_VERSION
ARG KOHYA_XFORMERS_VERSION
RUN /install_kohya.sh && rm /install_kohya.sh

# Post-Install: Copy the accelerate configuration
COPY kohya_ss/accelerate.yaml ./

### Stage 7: Install ComfyUI ### =====================================================================
WORKDIR /

# Install: ComfyUI
ARG COMFYUI_COMMIT
ARG COMFYUI_TORCH_VERSION
ARG COMFYUI_XFORMERS_VERSION
RUN /install_comfyui.sh && rm /install_comfyui.sh

# Post-Install:Copy ComfyUI Extra Model Paths (to share models with A1111)
COPY comfyui/extra_model_paths.yaml /ComfyUI/


### Stage 8: Install Tensorboard ### ==================================================================
WORKDIR /

# Install: Tensorboard
RUN /install_tensorboard.sh && rm /install_tensorboard.sh

### Stage 9: Finalise Image ### =======================================================================

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
