#!/usr/bin/env bash

echo "PRE-START: START ---------------------------------------------------------------"

export PYTHONUNBUFFERED=1

TEMPLATE_NAME="stable-diffusion-webui"
TEMPLATE_VERSION_FILE="/workspace/apps/stable-diffusion-webui/template.json"

echo "TEMPLATE NAME: ${TEMPLATE_NAME}"
echo "TEMPLATE VERSION: ${TEMPLATE_VERSION}"
echo "VENV PATH: ${VENV_PATH}"

if [[ -e ${TEMPLATE_VERSION_FILE} ]]; then
    EXISTING_TEMPLATE_NAME=$(jq -r '.template_name // empty' "$TEMPLATE_VERSION_FILE")

    if [[ -n "${EXISTING_TEMPLATE_NAME}" ]]; then
        if [[ "${EXISTING_TEMPLATE_NAME}" != "${TEMPLATE_NAME}" ]]; then
            EXISTING_VERSION="0.0.0"
        else
            EXISTING_VERSION=$(jq -r '.template_version // empty' "$TEMPLATE_VERSION_FILE")
        fi
    else
        EXISTING_VERSION="0.0.0"
    fi
else
    EXISTING_VERSION="0.0.0"
fi

save_template_json() {
    cat <<EOF >${TEMPLATE_VERSION_FILE}
{
    "template_name": "${TEMPLATE_NAME}",
    "template_version": "${TEMPLATE_VERSION}"
}
EOF
}

sync_directory() {
    local src_dir="$1"
    local dst_dir="$2"

    echo "SYNC: Syncing from ${src_dir} to ${dst_dir}, please wait (this can take a few minutes)..."

    # Ensure destination directory exists
    mkdir -p "${dst_dir}"

    # Free up memory by clearing page cache, dentries, and inodes.
    # This requires root privileges.
    sync
    if [ -w /proc/sys/vm/drop_caches ]; then
        echo 3 >/proc/sys/vm/drop_caches
    fi

    # Using rsync as it can be more memory-efficient than cp for large numbers of files.
    # -a: archive mode (preserves attributes, copies recursively)
    # -u: update (copies only when the SOURCE file is newer than the destination file or when the destination file is missing)
    rsync -au "${src_dir}/" "${dst_dir}/"

    # Remove the source directory
    rm -rf "${src_dir}"

}

sync_apps() {
    echo "PRE-START: SYNCING APPLICATIONS ------------------------------------------------"

    # Start the timer
    start_time=$(date +%s)

    echo "SYNC: Sync /configs"
    sync_directory "/configs" "/workspace/configs"

    echo "SYNC: Sync /scripts"
    sync_directory "/scripts" "/workspace/configs/scripts"

    echo "SYNC: Sync /apps"
    sync_directory "/apps" "/workspace/apps"

    echo "SYNC: Sync /venvs"
    for venv_name in a1111 comfyui invokeai kohya_ss risa; do
        if [ -d "/venvs/${venv_name}" ]; then
            sync_directory "/venvs/${venv_name}" "/workspace/.cache/venvs/${venv_name}"
        fi
    done

    save_template_json

    # echo "${VENV_PATH}" >"/workspace/.cache/venvs/a1111"

    # End the timer and calculate the duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    # Convert duration to minutes and seconds
    minutes=$((duration / 60))
    seconds=$((duration % 60))

    echo "SYNC: Syncing COMPLETE!"
    printf "SYNC: Time taken: %d minutes, %d seconds\n" ${minutes} ${seconds}
}

create_symlinks() {
    local symlinks_config="/workspace/configs/symlinks.yaml"

    if [[ ! -f "${symlinks_config}" ]]; then
        echo "SYMLINK: Config file not found at ${symlinks_config}. Skipping."
        return
    fi

    yq -r '[.[] | .source, .destination] | join("\u0000")' "${symlinks_config}" | while IFS= read -r -d '' source && IFS= read -r -d '' destination; do
        # Remove trailing slashes
        source="${source%/}"
        destination="${destination%/}"

        if [[ -z "$source" || -z "$destination" ]]; then
            echo "SYMLINK: Skipping invalid entry."
            continue
        fi

        echo "SYMLINK: Processing link from '${source}' to '${destination}'"

        # If source does not exist but destination does, move destination to source.
        if [[ ! -e "${source}" && ! -L "${source}" && -e "${destination}" && ! -L "${destination}" ]]; then
            echo "SYMLINK: Source '${source}' not found, but destination '${destination}' exists. Moving it."
            mkdir -p "$(dirname "${source}")"
            mv "${destination}" "${source}"
            echo "SYMLINK: Move complete. '${destination}' is now at '${source}'."
        fi

        # After the potential move, if source still doesn't exist, we can't do anything.
        if [[ ! -e "${source}" && ! -L "${source}" ]]; then
            echo "SYMLINK: Source '${source}' does not exist. Cannot create symlink. Skipping."
            continue
        fi

        # Now, source exists. Let's prepare the destination.
        if [[ -L "${destination}" ]]; then
            # Destination is a symlink. Check if it's correct.
            if [[ "$(readlink -f "${destination}")" == "$(readlink -f "${source}")" ]]; then
                echo "SYMLINK: Correct symlink already exists at '${destination}'. Skipping."
                continue
            else
                echo "SYMLINK: Incorrect symlink at '${destination}'. Removing it."
                rm "${destination}"
            fi
        elif [[ -e "${destination}" ]]; then
            # Destination exists and is a file or directory. This happens if both source and destination existed initially.
            # We back up the destination.
            destination_no_slash="${destination%/}"
            echo "SYMLINK: Destination '${destination}' already exists. Renaming to '${destination_no_slash}.old'."
            if [[ -e "${destination_no_slash}.old" || -L "${destination_no_slash}.old" ]]; then
                rm -rf "${destination_no_slash}.old"
            fi
            mv "${destination}" "${destination_no_slash}.old"
        fi

        # Destination path is now clear. Create the symlink.
        echo "SYMLINK: Creating symlink from '${source}' to '${destination}'"
        mkdir -p "$(dirname "${destination}")"
        ln -s "${source}" "${destination}"
    done

    echo "SYMLINK: Symlink creation complete."
}

fix_venvs() {
    echo "VENV: Fixing A1111 Web UI venv..."
    /fix_venv.sh /venvs/a1111 /workspace/.cache/venvs/a1111

    echo "VENV: Fixing Kohya venv..."
    /fix_venv.sh /venvs/kohya_ss /workspace/.cache/venvs/kohya_ss

    echo "VENV: Fixing InvokeAI venv..."
    /fix_venv.sh /venvs/invokeai /workspace/.cache/venvs/invokeai

    echo "VENV: Fixing ComfyUI venv..."
    /fix_venv.sh /venvs/comfyui /workspace/.cache/venvs/comfyui

    echo "VENV: Fixing Risa venv..."
    /fix_venv.sh /venvs/risa /workspace/.cache/venvs/risa
}

create_directories() {
    mkdir -p /workspace/.cache/venvs
    mkdir -p /workspace/.logs
    mkdir -p /workspace/__INPUTS__
    mkdir -p /workspace/__OUTPUTS__
    mkdir -p /workspace/apps
    mkdir -p /workspace/apps/stable-diffusion-webui
    mkdir -p /workspace/apps/stable-diffusion-webui/output
    mkdir -p /workspace/apps/kohya_ss
    mkdir -p /workspace/apps/comfyui
    mkdir -p /workspace/apps/invokeai
    mkdir -p /workspace/configs
    mkdir -p /workspace/configs/scripts
    mkdir -p /workspace/configs/webdav
    mkdir -p /workspace/configs/docker-risa-playground
    mkdir -p /workspace/configs/a1111
    mkdir -p /workspace/configs/kohya_ss
    mkdir -p /workspace/configs/comfyui
    mkdir -p /workspace/configs/invokeai
    mkdir -p /workspace/configs/risa
    mkdir -p /workspace/configs/webdav
    mkdir -p /workspace/configs/jupyter
    mkdir -p /workspace/configs/tensorboard
    mkdir -p /workspace/hub
    mkdir -p /workspace/hub/models
    mkdir -p /workspace/hub/models/SDXL
    mkdir -p /workspace/hub/models/SDXL/checkpoints
    mkdir -p /workspace/hub/models/SDXL/loras
    mkdir -p /workspace/hub/models/SDXL/embeddings
}

echo "PRE-START: STRUCTURING DIRECTORIES ---------------------------------------------"
create_directories

echo "PRE-START: SYNCING APPLICATIONS ------------------------------------------------"
sync_apps

echo "PRE-START: CREATING SYMLINKS ---------------------------------------------------"
create_symlinks

echo "PRE-START: FIXING VENVS --------------------------------------------------------"
fix_venvs

echo "PRE-START: CONFIGURING ACCELERATE ----------------------------------------------"
mkdir -p /root/.cache/huggingface/accelerate
mv /accelerate.yaml /root/.cache/huggingface/accelerate/default_config.yaml

echo "PRE-START: LAUNCHING APPLICATIONS ----------------------------------------------"

echo "ENV START VARIABLES"
echo "==================="
echo "START_CODE_SERVER=${START_CODE_SERVER}"
echo "START_JUPYTER=${START_JUPYTER}"
echo "START_RISA_PLAYGROUND=${START_RISA_PLAYGROUND}"
echo "START_WEBDAV=${START_WEBDAV}"
echo "START_JUPYTER=${START_JUPYTER}"
echo "START_TENSORBOARD=${START_TENSORBOARD}"
echo "START_A1111=${START_A1111}"
echo "START_KOHYA=${START_KOHYA}"
echo "START_COMFYUI=${START_COMFYUI}"
echo "START_INVOKEAI=${START_INVOKEAI}"

if [ ${START_CODE_SERVER} ]; then
    echo "\n    ---- LAUNCHING: Code Server ----------------------------------------------"
    /workspace/configs/scripts/start_code_server.sh
fi

if [ ${START_JUPYTER} ]; then
    echo "\n    ---- LAUNCHING: Jupyter ----------------------------------------------------"
    /workspace/configs/scripts/start_jupyter.sh
fi

if [ ${START_RISA_PLAYGROUND} ]; then
    echo "\n    ---- LAUNCHING: Risa Playground ------------------------------------------"
    /workspace/configs/scripts/start_risa_playground.sh
fi

if [ ${START_WEBDAV} ]; then
    echo "\n    ---- LAUNCHING: WebDAV -----------------------------------------------------"
    /workspace/configs/scripts/start_webdav.sh
fi

if [ ${START_JUPYTER} ]; then
    echo "\n    ---- LAUNCHING: Jupyter ----------------------------------------------------"
    /workspace/configs/scripts/start_jupyter.sh
fi

if [ ${START_TENSORBOARD} ]; then
    echo "\n    ---- LAUNCHING: TensorBoard ------------------------------------------------"
    /workspace/configs/scripts/start_tensorboard.sh
fi

if [ ${START_A1111} ]; then
    echo "\n    ---- LAUNCHING: A1111 ------------------------------------------------------"
    /workspace/configs/scripts/start_a1111.sh
fi

if [ ${START_KOHYA} ]; then
    echo "\n    ---- LAUNCHING: Kohya ------------------------------------------------------"
    /workspace/configs/scripts/start_kohya.sh
fi

if [ ${START_COMFYUI} ]; then
    echo "\n    ---- LAUNCHING: ComfyUI ----------------------------------------------------"
    /workspace/configs/scripts/start_comfyui.sh
fi

if [ ${START_INVOKEAI} ]; then
    echo "\n    ---- LAUNCHING: InvokeAI --------------------------------------------------"
    /workspace/configs/scripts/start_invokeai.sh
fi

echo "PRE-START: DONE ------------------------------------------------------------"
echo "----------------------------------------------------------------------------\n\n"
