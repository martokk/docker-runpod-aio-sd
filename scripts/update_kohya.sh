#!/usr/bin/env bash

cd /workspace/apps/kohya_ss
source venv/bin/activate
git checkout master
git pull
pip3 install -r requirements.txt
pip3 install .
