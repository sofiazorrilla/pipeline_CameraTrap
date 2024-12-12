######
# Script : Detect animals, persons or vehicles in Camera Trap images
# Author: Sofía Zorrilla and César Díaz
# Date: 2024-12-08
# Description: Use megadetector to identify where in the image the animal/person/vehicle can be found.
# Arguments:
#   - Input: 
#   - Output: 
#######

### Aditional information ###

# Tools:
# Pytorch-Wildlife

# Installation instructions:
# 1. Create conda environment `conda create -n pytorch_wildlife python=3.8 -y` `conda activate pytorch_wildlife`
# 2. Install using `pip install PytorchWildlife`

# Detection model: MegaDetector V6
# MegaDetector repository: https://github.com/agentmorris/MegaDetector/tree/main
# MegaDetector package: https://pypi.org/project/megadetector/

# Image Detector PyTorchWildlife

# --- Import packages ---

import numpy as np
import os
from PIL import Image
import torch
from torch.utils.data import DataLoader
from PytorchWildlife.models import detection as pw_detection
from PytorchWildlife.data import transforms as pw_trans
from PytorchWildlife.data import datasets as pw_data
from PytorchWildlife import utils as pw_utils

# --- Model initialization ---

DEVICE = "cpu"  # Use "cuda" if GPU is available "cpu" if no GPU is available
detection_model = pw_detection.MegaDetectorV6(device=DEVICE, pretrained=True, version="yolov9c")


# --- Single image detection ---

tgt_img_path = os.path.join("/mnt", "STORAGE", "csar", "pipo_images", "PUMA_CONCOLOR_2022", "I_00058a.JPG")
results = detection_model.single_image_detection(tgt_img_path)
pw_utils.save_detection_images(results, os.path.join(".","demo_output"), overwrite=False)


tgt_img_path = "/mnt/STORAGE/csar/pipo_images/PUMA_CONCOLOR_2022/I_00058a.JPG"
img = np.array(Image.open(tgt_img_path).convert("RGB"))
transform = pw_trans.MegaDetector_v6_Transform(target_size=detection_model.IMAGE_SIZE,stride=detection_model.STRIDE)
detection_result = detection_model.single_image_detection(img)

pw_utils.save_detection_images(detection_result, "./output.JPG")
pw_utils.save_detection_images(detection_result, "batch_output")
pw_utils.save_detection_json(detection_result, "./batch_output.json",categories=detection_model.CLASS_NAMES)


print(detection_result)