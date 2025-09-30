#!/bin/bash
set -e
source /home/jdh251425/2509\ Gradi-Detection/gradi-detection/bin/activate
python - <<'PY'
import torch
print('✅ Torch', torch.__version__, 'CUDA', torch.cuda.is_available(), 'GPUs', torch.cuda.device_count())
PY
python - <<'PY'
from ultralytics import YOLO
print('🚀 Train YOLOv8n @1280 (large4, multi-GPU)')
YOLO('yolov8n.pt').train(cfg='/home/jdh251425/2509 Gradi-Detection/experiment_routing_0930/yolov8n_imgsz_1280/config_optimized.yaml')
print('✅ Done')
PY
