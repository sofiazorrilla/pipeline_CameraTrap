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

# MegaDetector repository: https://github.com/agentmorris/MegaDetector/tree/main
# MegaDetector package: https://pypi.org/project/megadetector/

# Installation instructions:
# 1. Create conda environment `conda create -n megadetector` `conda activate megadetector`
# 2. Install using `pip install megadetector`

###

# --- Run MegaDetector on a folder of images ---

from megadetector.detection.run_detector_batch import load_and_run_detector_batch, write_results_to_file
from megadetector.utils import path_utils
import os

# Pick a folder to run MD on recursively, and an output file
image_folder = os.path.expanduser('~/megadetector_test_images')
output_file = os.path.expanduser('~/megadetector_output_test.json')

# Recursively find images
image_file_names = path_utils.find_images(image_folder,recursive=True)

# This will automatically download MDv5a; you can also specify a filename.
results = load_and_run_detector_batch('MDV5A', image_file_names)

# Write results to a format that Timelapse and other downstream tools like.
write_results_to_file(results,
                      output_file,
                      relative_path_base=image_folder,
                      detector_file=detector_filename)
