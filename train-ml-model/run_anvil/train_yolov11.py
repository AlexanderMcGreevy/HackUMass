#!/usr/bin/env python3
"""Train a YOLOv11 model on the merged dataset.

This wrapper builds on the Ultralytics `YOLO` interface and provides a single entry-point
for launching training against the `merged_dataset.yolov11/data.yaml` file created by
`merge_yolov11_datasets.py`.
"""

import argparse
import ssl
import sys
import urllib.error
import urllib.request
from pathlib import Path

try:
    from ultralytics import YOLO
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Ultralytics is required. Install it with `pip install ultralytics`."
    ) from exc

try:
    import torch
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "PyTorch is required. Install it with `pip install torch`."
    ) from exc


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train YOLOv11 on the merged dataset.")
    parser.add_argument(
        "--data",
        type=str,
        default="merged_dataset.yolov11/data.yaml",
        help="Path to the dataset YAML file.",
    )
    parser.add_argument(
        "--model",
        type=str,
        default="yolo11n.pt",
        help="Name or path of the YOLOv11 checkpoint to fine-tune (e.g. yolo11n.pt, yolo11s.pt).",
    )
    parser.add_argument("--epochs", type=int, default=50, help="Number of epochs to train.")
    parser.add_argument("--img", type=int, default=640, help="Image size for training.")
    parser.add_argument("--batch", type=int, default=16, help="Batch size.")
    parser.add_argument(
        "--device",
        type=str,
        default="auto",
        help="Training device (e.g. '0' for GPU, 'cpu', 'mps', or 'auto').",
    )
    parser.add_argument(
        "--project",
        type=str,
        default="runs/train",
        help="Project directory for Ultralytics run outputs.",
    )
    parser.add_argument(
        "--name",
        type=str,
        default="yolov11-merged",
        help="Run name for Ultralytics outputs.",
    )
    parser.add_argument("--workers", type=int, default=8, help="Number of dataloader workers.")
    parser.add_argument("--patience", type=int, default=50, help="Early stopping patience.")
    parser.add_argument(
        "--save-period",
        type=int,
        default=-1,
        help="Save a checkpoint every N epochs (-1 disables periodic saves).",
    )
    parser.add_argument("--seed", type=int, default=0, help="Random seed.")
    parser.add_argument("--lr0", type=float, default=0.01, help="Initial learning rate.")
    parser.add_argument("--lrf", type=float, default=0.01, help="Final learning rate multiplier.")
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Resume training from the last checkpoint in the run directory.",
    )
    parser.add_argument(
        "--exist-ok",
        action="store_true",
        help="Allow overwrite of existing project/name directory.",
    )
    return parser.parse_args()


def download_weights_if_needed(model_path: Path) -> Path:
    """Download the requested YOLO checkpoint from HuggingFace if missing."""

    alias_map = {
        "yolov11n.pt": "yolo11n.pt",
        "yolov11s.pt": "yolo11s.pt",
        "yolov11m.pt": "yolo11m.pt",
        "yolov11l.pt": "yolo11l.pt",
        "yolov11x.pt": "yolo11x.pt",
    }

    filename = model_path.name
    resolved_name = alias_map.get(filename, filename)
    target_path = model_path if resolved_name == filename else model_path.with_name(resolved_name)

    if target_path.exists():
        return target_path

    hf_url = f"https://huggingface.co/ultralytics/yolo11/resolve/main/{resolved_name}?download=1"
    print(f"Checkpoint '{resolved_name}' not found locally. Downloading from {hf_url} ...")

    context = ssl.create_default_context()
    try:
        cafile = __import__("certifi").where()  # type: ignore[assignment]
        context.load_verify_locations(cafile=cafile)
    except (ModuleNotFoundError, ssl.SSLError):
        pass

    try:
        with urllib.request.urlopen(hf_url, context=context) as response, target_path.open("wb") as dst:
            dst.write(response.read())
    except urllib.error.URLError as exc:
        raise SystemExit(
            f"Failed to download {resolved_name} from HuggingFace: {exc}. "
            "Download manually and re-run."
        ) from exc

    if target_path.stat().st_size < 1024:
        target_path.unlink(missing_ok=True)
        raise SystemExit(
            f"Downloaded file for {resolved_name} is unexpectedly small. "
            "Check the filename and try again."
        )

    print(f"Downloaded checkpoint to {target_path.resolve()}")
    return target_path


def main() -> int:
    args = parse_args()

    data_path = Path(args.data).expanduser().resolve()
    if not data_path.exists():
        raise SystemExit(f"Dataset YAML not found: {data_path}")

    model_path = Path(args.model)
    if not model_path.is_absolute():
        model_path = Path.cwd() / model_path
    model_path = download_weights_if_needed(model_path)

    model = YOLO(str(model_path))

    device_arg = args.device
    if device_arg == "auto" and not torch.cuda.is_available():
        print("No CUDA device detected. Using CPU.")
        device_arg = "cpu"

    train_kwargs = dict(
        data=str(data_path),
        epochs=args.epochs,
        imgsz=args.img,
        batch=args.batch,
        device=device_arg,
        project=args.project,
        name=args.name,
        workers=args.workers,
        patience=args.patience,
        save_period=args.save_period,
        seed=args.seed,
        lr0=args.lr0,
        lrf=args.lrf,
        exist_ok=args.exist_ok,
    )

    if args.resume:
        train_kwargs["resume"] = True

    print("Launching training with arguments:")
    for key, value in sorted(train_kwargs.items()):
        print(f"  {key}: {value}")

    results = model.train(**train_kwargs)
    print("Training finished. Metrics summary:")
    for metric, value in results.items():
        print(f"  {metric}: {value}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
