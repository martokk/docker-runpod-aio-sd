### Base ### =================================================================================
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/London \
    PYTHONUNBUFFERED=1 \
    SHELL=/bin/bash

WORKDIR /

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


# Pre-Install: Copy the build scripts and application files
COPY --chmod=755 build/* ./
COPY code-server/vsix/*.vsix /tmp/
COPY code-server/settings.json /root/.local/share/code-server/User/settings.json

# Install: Apps
ARG RUNPODCTL_VERSION
ENV RUNPODCTL_VERSION=${RUNPODCTL_VERSION}
RUN /apps.sh && rm /apps.sh

# Install: Tensorboard
RUN /install_tensorboard.sh && rm /install_tensorboard.sh

# Install: WebDAV
RUN /install_webdav.sh && rm /install_webdav.sh

### InvokeAI Builder ### =====================================================================
FROM base AS invokeai
WORKDIR /

# Copy all build scripts
COPY --chmod=755 build/* ./

# Install: InvokeAI
ARG INDEX_URL
ARG INVOKEAI_VERSION
ARG INVOKEAI_TORCH_VERSION
ARG INVOKEAI_XFORMERS_VERSION
RUN /install_invokeai.sh && rm /install_invokeai.sh

# Post-Install: Copy InvokeAI config file
COPY invokeai/invokeai.yaml /InvokeAI/

### ComfyUI Builder ### =====================================================================
FROM invokeai AS comfyui
WORKDIR /

# Copy all build scripts
COPY --chmod=755 build/* ./

# Install: ComfyUI
ARG COMFYUI_COMMIT
ARG COMFYUI_TORCH_VERSION
ARG COMFYUI_XFORMERS_VERSION
RUN /install_comfyui.sh && rm /install_comfyui.sh

# Post-Install:Copy ComfyUI Extra Model Paths (to share models with A1111)
COPY comfyui/extra_model_paths.yaml /ComfyUI/

### Kohya_ss Builder ### =====================================================================
FROM comfyui AS kohya_ss
WORKDIR /

# Copy all build scripts
COPY --chmod=755 build/* ./

# Pre-Install: Copy the application files
COPY kohya_ss/requirements* ./

# Install: Kohya_ss
ARG KOHYA_VERSION
ARG KOHYA_TORCH_VERSION
ARG KOHYA_XFORMERS_VERSION
RUN /install_kohya.sh && rm /install_kohya.sh

# Post-Install: Copy the accelerate configuration
COPY kohya_ss/accelerate.yaml ./



### A1111 Builder ### ========================================================================
FROM kohya_ss AS a1111
WORKDIR /

# Copy all build scripts
COPY --chmod=755 build/* ./

# Install: A1111
ARG TORCH_VERSION
ARG XFORMERS_VERSION
ARG INDEX_URL
ARG WEBUI_VERSION
ARG CONTROLNET_COMMIT
ARG CIVITAI_BROWSER_PLUS_VERSION
RUN /install.sh && rm /install.sh

# Post-Install:

# Copy Stable Diffusion Web UI config files
COPY a1111/relauncher.py a1111/webui-user.sh a1111/config.json a1111/ui-config.json /apps/stable-diffusion-webui/

# ADD SDXL styles.csv
ADD https://raw.githubusercontent.com/Douleb/SDXL-750-Styles-GPT4-/main/styles.csv /apps/stable-diffusion-webui/styles.csv

### Final Image ### =======================================================================
FROM a1111 AS final

### Finalise Image ###
# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/502.html /usr/share/nginx/html/502.html

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Set the venv path
ARG VENV_PATH
ENV VENV_PATH=${VENV_PATH}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* /
COPY --chmod=755 scripts/* /scripts/
COPY --chmod=755 configs/* /configs/

# Start the container
ARG REQUIRED_CUDA_VERSION
ENV REQUIRED_CUDA_VERSION=${REQUIRED_CUDA_VERSION}
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
