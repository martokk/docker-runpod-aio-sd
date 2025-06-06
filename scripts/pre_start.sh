#!/usr/bin/env bash

echo "PRE-START: Running pre-start script..."

export PYTHONUNBUFFERED=1
export APP="stable-diffusion-webui"

TEMPLATE_NAME="${APP}"
TEMPLATE_VERSION_FILE="/workspace/${APP}/template.json"

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
    local use_compression=${3:-false}

    echo "SYNC: Syncing from ${src_dir} to ${dst_dir}, please wait (this can take a few minutes)..."

    # Ensure destination directory exists
    mkdir -p "${dst_dir}"

    # Check whether /workspace is fuse, overlay, or xfs
    local workspace_fs=$(df -T /workspace | awk 'NR==2 {print $2}')
    echo "SYNC: File system type: ${workspace_fs}"

    if [ "${workspace_fs}" = "fuse" ]; then
        if [ "$use_compression" = true ]; then
            echo "SYNC: Using tar with zstd compression for sync"
        else
            echo "SYNC: Using tar without compression for sync"
        fi

        # Get total size of source directory
        local total_size=$(du -sb "${src_dir}" | cut -f1)

        # Base tar command with optimizations
        local tar_cmd="tar --create \
            --file=- \
            --directory="${src_dir}" \
            --exclude='*.pyc' \
            --exclude='__pycache__' \
            --exclude='*.log' \
            --blocking-factor=64 \
            --record-size=64K \
            --sparse \
            ."

        # Base tar extract command
        local tar_extract_cmd="tar --extract \
            --file=- \
            --directory="${dst_dir}" \
            --blocking-factor=64 \
            --record-size=64K \
            --sparse"

        if [ "$use_compression" = true ]; then
            $tar_cmd | zstd -T0 -1 | pv -s ${total_size} | zstd -d -T0 | $tar_extract_cmd
        else
            $tar_cmd | pv -s ${total_size} | $tar_extract_cmd
        fi

    elif [ "${workspace_fs}" = "overlay" ] || [ "${workspace_fs}" = "xfs" ]; then
        echo "SYNC: Using rsync for sync"
        rsync -rlptDu "${src_dir}/" "${dst_dir}/"
    else
        echo "SYNC: Unknown filesystem type (${workspace_fs}) for /workspace, defaulting to rsync"
        rsync -rlptDu "${src_dir}/" "${dst_dir}/"
    fi
}

sync_apps() {
    # Only sync if the DISABLE_SYNC environment variable is not set
    if [ -z "${DISABLE_SYNC}" ]; then
        echo "SYNC: Syncing to persistent storage started"

        # Start the timer
        start_time=$(date +%s)

        echo "SYNC: Sync 1 of 6"
        sync_directory "/venv" "${VENV_PATH}"
        echo "SYNC: Sync 2 of 6"
        sync_directory "/${APP}" "/workspace/${APP}"
        echo "SYNC: Sync 3 of 6"
        sync_directory "/kohya_ss" "/workspace/kohya_ss"
        echo "SYNC: Sync 4 of 6"
        sync_directory "/ComfyUI" "/workspace/ComfyUI"
        echo "SYNC: Sync 5 of 6"
        sync_directory "/InvokeAI" "/workspace/InvokeAI"
        echo "SYNC: Sync 6 of 6"
        sync_directory "/scripts" "/workspace/scripts"
        save_template_json
        echo "${VENV_PATH}" >"/workspace/${APP}/venv_path"

        # End the timer and calculate the duration
        end_time=$(date +%s)
        duration=$((end_time - start_time))

        # Convert duration to minutes and seconds
        minutes=$((duration / 60))
        seconds=$((duration % 60))

        echo "SYNC: Syncing COMPLETE!"
        printf "SYNC: Time taken: %d minutes, %d seconds\n" ${minutes} ${seconds}
    fi
}

fix_venvs() {
    echo "VENV: Fixing A1111 Web UI venv..."
    /fix_venv.sh /venv ${VENV_PATH}

    echo "VENV: Fixing ComfyUI venv..."
    /fix_venv.sh /ComfyUI/venv /workspace/ComfyUI/venv
}

if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        sync_apps
        fix_venvs

        # Configure accelerate
        echo "Configuring accelerate..."
        mkdir -p /root/.cache/huggingface/accelerate
        mv /accelerate.yaml /root/.cache/huggingface/accelerate/default_config.yaml

        # Create logs directory
        mkdir -p /workspace/logs
    else
        echo "SYNC: Existing version is the same as the template version, no syncing required."
    fi
else
    echo "SYNC: Existing version is newer than the template version, not syncing!"
fi

# Add VENV_PATH to webui-user.sh
sed -i "s|venv_dir=VENV_PATH|venv_dir=\"${VENV_PATH}\"|" /workspace/stable-diffusion-webui/webui-user.sh

# Start application manager
cd /app-manager
npm start >/workspace/logs/app-manager.log 2>&1 &

# if [[ ${DISABLE_AUTOLAUNCH} ]]; then
#     echo "Auto launching is disabled so the applications will not be started automatically"
#     echo "You can launch them manually using the launcher scripts:"
#     echo ""
#     echo "   Stable Diffusion Web UI:"
#     echo "   ---------------------------------------------"
#     echo "   /start_a1111.sh"
#     echo ""
#     echo "   Kohya_ss"
#     echo "   ---------------------------------------------"
#     echo "   /start_kohya.sh"
#     echo ""
#     echo "   ComfyUI"
#     echo "   ---------------------------------------------"
#     echo "   /start_comfyui.sh"
#     echo ""
#     echo "   InvokeAI"
#     echo "   ---------------------------------------------"
#     echo "   /start_invokeai.sh"
# else
#     /start_a1111.sh
#     /start_kohya.sh
#     /start_comfyui.sh
#     /start_invokeai.sh
# fi

if [ ${START_SERVER_STATUS_API} ]; then
    /workspace/scripts/start_server_status_api.sh
fi

if [ ${START_JUPYTER} ]; then
    /workspace/scripts/start_jupyter.sh
fi

if [ ${START_TENSORBOARD} ]; then
    /workspace/scripts/start_tensorboard.sh
fi

if [ ${START_A1111} ]; then
    /workspace/scripts/start_a1111.sh
fi

if [ ${START_KOHYA} ]; then
    /workspace/scripts/start_kohya.sh
fi

if [ ${START_COMFYUI} ]; then
    /workspace/scripts/start_comfyui.sh
fi

if [ ${START_INVOKEAI} ]; then
    /workspace/scripts/start_invokeai.sh
fi

echo "PRE-START: Done"
