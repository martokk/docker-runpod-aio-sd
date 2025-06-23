variable "REGISTRY" {
    default = "docker.io"
}

variable "REGISTRY_USER" {
    default = "martokk"
}

variable "APP" {
    default = "docker-risa-playground"
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

variable "A1111_WEBUI_VERSION" {
    default = "1.10.1"
}

variable "KOHYA_VERSION" {
    default = "v25.2.0"
}

variable "INVOKEAI_VERSION" {
    default = "5.13.0"
}

variable "COMFYUI_VERSION" {
    default = "v0.3.39"
}

variable "CIVITAI_BROWSER_PLUS_VERSION" {
    default = "v3.6.0"
}


target "default" {
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${REGISTRY_USER}/${APP}:${RELEASE}"]
    args = {
        RELEASE = "${RELEASE}"
        INDEX_URL = "https://download.pytorch.org/whl/cu${CU_VERSION}"

        BASE_IMAGE = "nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04"
        REQUIRED_CUDA_VERSION = "12.4"
        PYTHON_VERSION = "${PYTHON_VERSION}"

        RUNPODCTL_VERSION = "${RUNPODCTL_VERSION}"

        TORCH_VERSION = "${TORCH_VERSION}+cu${CU_VERSION}"
        XFORMERS_VERSION = "0.0.29.post3"
        WEBUI_VERSION = "v${A1111_WEBUI_VERSION}"
        CONTROLNET_COMMIT = "56cec5b2958edf3b1807b7e7b2b1b5186dbd2f81"
        CIVITAI_BROWSER_PLUS_VERSION = "${CIVITAI_BROWSER_PLUS_VERSION}"
        VENV_PATH = "/workspace/.cache/venvs/a1111"

        KOHYA_VERSION = "${KOHYA_VERSION}"
        KOHYA_TORCH_VERSION = "2.6.0+cu${CU_VERSION}"
        KOHYA_XFORMERS_VERSION = "0.0.29.post3"

        INVOKEAI_VERSION = "${INVOKEAI_VERSION}"
        INVOKEAI_TORCH_VERSION = "2.7.0+cu${CU_VERSION}"
        INVOKEAI_XFORMERS_VERSION = "0.0.30"

        COMFYUI_VERSION = "${COMFYUI_VERSION}"
        COMFYUI_TORCH_VERSION = "2.6.0+cu${CU_VERSION}"
        COMFYUI_XFORMERS_VERSION = "0.0.29.post3"
    }
    platforms = ["linux/amd64"]
    annotations = ["org.opencontainers.image.authors=${REGISTRY_USER}"]
}
