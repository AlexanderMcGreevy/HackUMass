#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

python3 -m venv .venv
source .venv/bin/activate

python3 -m pip install --upgrade pip wheel
python3 -m pip install -r requirements.txt

# Torch CPU wheels for Apple Silicon (arm64) are only published for newer releases.
TORCH_VER="2.9.0"
TORCHAUDIO_VER="2.9.0"
TORCHVISION_VER="0.22.1"  # match torch>=2.9 series for CPU

python3 -m pip install \
  "torch==${TORCH_VER}" \
  "torchaudio==${TORCHAUDIO_VER}" \
  --index-url https://download.pytorch.org/whl/cpu

python3 -m pip install "torchvision==${TORCHVISION_VER}" --index-url https://download.pytorch.org/whl/cpu

python3 -m pip install "ultralytics>=8.2.0" "opencv-python-headless>=4.8.0"

DEFAULT_ARGS=(
  --data merged_dataset.yolov11/data.yaml
  --model yolo11s.pt
  --epochs 60
  --batch 8
  --img 640
  --device cpu
  --patience 8
  --project runs/train
  --name yolov11s-mvp-cpu
)

python3 train_yolov11.py "${DEFAULT_ARGS[@]}" "$@"
