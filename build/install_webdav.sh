#!/usr/bin/env bash
set -e

# Install apache2-utils for htpasswd authentication
apt install -y apache2-utils

# Install cheroot for webdav server
pip install cheroot

# Install wsgidav for webdav client
pip install "wsgidav[htpasswd]"

mkdir -p /workspace/configs/webdav
