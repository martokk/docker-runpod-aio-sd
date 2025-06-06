variable "REGISTRY" {
    default = "ghcr.io"
}

variable "REGISTRY_USER" {
    default = "martokk"
}

variable "APP" {
    default = "stable-diffusion-docker"
}

variable "RELEASE" {
    default = "latest"
}

variable "RUNPODCTL_VERSION" {
    default = "v1.14.4"
}

variable "CU_VERSION" {
    default = "124"
}

variable "CUDA_VERSION" {
    default = "12.4.1"
}

variable "TORCH_VERSION" {
    default = "2.6.0"
}

variable "PYTHON_VERSION" {
    default = "3.10"
}

variable "WEBUI_VERSION" {
    default = "1.10.1"
}

target "default" {
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${REGISTRY_USER}/${APP}:${RELEASE}"]
    args = {
        RELEASE = "${RELEASE}"
        INDEX_URL = "https://download.pytorch.org/whl/cu${CU_VERSION}"

        BASE_IMAGE = "nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04"
        REQUIRED_CUDA_VERSION = "12.4"
        PYTHON_VERSION = "3.10"

        RUNPODCTL_VERSION = "${RUNPODCTL_VERSION}"

        TORCH_VERSION = "${TORCH_VERSION}+cu${CU_VERSION}"
        XFORMERS_VERSION = "0.0.29.post3"
        WEBUI_VERSION = "v${WEBUI_VERSION}"
        CONTROLNET_COMMIT = "56cec5b2958edf3b1807b7e7b2b1b5186dbd2f81"
        CIVITAI_BROWSER_PLUS_VERSION = "v3.6.0"
        APP_MANAGER_VERSION = "1.2.2"
        CIVITAI_DOWNLOADER_VERSION = "2.1.0"
        VENV_PATH = "/workspace/venvs/a1111"

        KOHYA_VERSION = "v25.1.2"
        KOHYA_TORCH_VERSION = "2.6.0+cu${CU_VERSION}"
        KOHYA_XFORMERS_VERSION = "0.0.29.post3"

        INVOKEAI_VERSION = "5.13.0"
        INVOKEAI_TORCH_VERSION = "2.7.0+cu${CU_VERSION}"
        INVOKEAI_XFORMERS_VERSION = "0.0.30"

        COMFYUI_VERSION = "v0.3.39"
        COMFYUI_TORCH_VERSION = "2.6.0+cu${CU_VERSION}"
        COMFYUI_XFORMERS_VERSION = "0.0.29.post3"

        VENV_PATH = "/workspace/venvs/a1111"
    }
    platforms = ["linux/amd64"]
    annotations = ["org.opencontainers.image.authors=${REGISTRY_USER}"]
}
