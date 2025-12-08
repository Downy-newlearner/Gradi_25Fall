#!/bin/bash
set -e
source /home/jdh251425/2509\ Gradi-Detection/gradi-detection/bin/activate
python - <<'PY'
import torch
print('✅ Torch', torch.__version__, 'CUDA', torch.cuda.is_available(), 'GPUs', torch.cuda.device_count())
PY
python - <<'PY'
from ultralytics import YOLO
print('🚀 Train YOLOv8s @2048')
YOLO('yolov8s.pt').train(cfg='/home/jdh251425/2509 Gradi-Detection/experiment_routing_0930/yolov8s_imgsz_2048/config_optimized.yaml')
print('✅ Done')
PY


