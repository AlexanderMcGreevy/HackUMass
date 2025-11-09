#!/bin/bash -l
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
#SBATCH -t 4:00:00
#SBATCH -A cis220051-gpu
#SBATCH -p gpu
#SBATCH --gpus-per-node=1
#SBATCH -o slurm-%j.out

# -------------------------
# Modules (keep exactly as requested)
# -------------------------
module use /anvil/projects/tdm/opt/core
module load tdm
module load python/seminar

set -euo pipefail

# -------------------------
# User-configurable paths
# -------------------------
DATA_YAML="merged_dataset.yolov11/data.yaml"   # <- make sure this exists
RUN_NAME="yolov11-merged"
EPOCHS=100
BATCH=32
IMGSZ=640
WORKERS=24
DEVICE=0
MODEL_PT="yolov11s.pt"  # small, good baseline

# -------------------------
# Sanity checks
# -------------------------
if [ ! -f "$DATA_YAML" ]; then
  echo "ERROR: Dataset YAML not found at: $DATA_YAML"
  exit 1
fi

echo "===> PWD: $(pwd)"
echo "===> Using dataset YAML: $DATA_YAML"

# -------------------------
# Python deps (install CUDA-enabled Torch, fallback logic)
# -------------------------
python3 - <<'PY'
import sys
print("Python:", sys.version)
PY

pip3 install --user --upgrade pip >/dev/null

# Try CUDA 12.1 wheel first
pip3 install --user torch==2.4.1+cu121 torchvision==0.19.1+cu121 \
  --extra-index-url https://download.pytorch.org/whl/cu121 >/dev/null || true

# If CUDA still not visible, try CUDA 11.8 wheels
python3 - <<'PY'
import torch, sys
print("Installed torch:", getattr(torch, "__version__", "missing"))
print("torch.cuda.is_available():", torch.cuda.is_available())
sys.exit(0 if torch.cuda.is_available() else 1)
PY
if [ $? -ne 0 ]; then
  echo "CUDA not visible after cu121 wheels. Trying cu118 wheels..."
  pip3 install --user --force-reinstall torch==2.3.1+cu118 torchvision==0.18.1+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118 >/dev/null
fi

# Ultralytics + OpenCV (headless)
pip3 install --user "ultralytics>=8.2.0" "opencv-python-headless>=4.8.0" >/dev/null

# -------------------------
# GPU / CUDA visibility checks
# -------------------------
echo "===> nvidia-smi:"
nvidia-smi || echo "nvidia-smi not found or no GPU visible (job may still run if PyTorch can use CUDA runtime)"

python3 - <<'PY'
import torch
print("torch:", torch.__version__)
print("torch.cuda.is_available():", torch.cuda.is_available())
print("torch.version.cuda:", torch.version.cuda)
if torch.cuda.is_available():
    print("GPU 0:", torch.cuda.get_device_name(0))
PY

# Hard fail if CUDA still not visible to PyTorch
python3 - <<'PY'
import torch, sys
sys.exit(0 if torch.cuda.is_available() else 2)
PY

# -------------------------
# Get YOLOv11 weights if missing
# -------------------------
if [ ! -f "$MODEL_PT" ]; then
  echo "===> Downloading $MODEL_PT ..."
  wget -q --show-progress "https://github.com/ultralytics/assets/releases/download/v8.2.0/${MODEL_PT}"
fi

# -------------------------
# Launch training (Ultralytics CLI)
# -------------------------
echo "===> Starting training..."
~/.local/bin/yolo detect train \
  data="$DATA_YAML" \
  model="$MODEL_PT" \
  epochs="$EPOCHS" \
  imgsz="$IMGSZ" \
  batch="$BATCH" \
  workers="$WORKERS" \
  device="$DEVICE" \
  project="runs/train" \
  name="$RUN_NAME" \
  patience=30 \
  cos_lr=True \
  exist_ok=True

echo "===> Training complete."
echo "===> Checkpoints should be at: runs/train/${RUN_NAME}/weights/{best.pt,last.pt}"
