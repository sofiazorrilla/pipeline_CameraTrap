######
# Script : Generar tabla de metadatos para las imagenes extraidas de los videos
# Author: Sofía Zorrilla and César Díaz
# Date: 2024-12-08
# Description: Extraction of metadata from image folders
# Arguments:
#   - Input: 
#   - Output: 
#######

# --- Load packages ---
# remotes::install_github("jniedballa/camtrapR")
library(camtrapR)
library(stringr)
library(data.table)
library(tidyverse)


# Leer las listas de archivos filtradas (fotos en las que se detectó algun animal)

metadata_dir <- "data/img_from_video_metadata"
img_dir <- "data/images_from_videos"

file_paths <- list.files(metadata_dir, full.names = T)[-6] # eliminar el leopardo porque no tiene datos

filtered_images <- lapply(file_paths, fread, select = c('img_id', 'label', 'certainty')) %>% do.call(rbind,.) 

filtered_images[filtered_images$label == "person"]  %>% data.frame() # Las revise manualmente y la mayoría son errores. Son animales que fueron identificados como personas. Los casos en los que no, los eliminé

filtered_images[,img_id := str_remove(img_id, "../")]
dim(filtered_images) # 11711     3

# 1. Check whether the file_paths stored in column img_id exist. If the file doesn't exist, remove the row from a copy of the table.
filtered_images <- filtered_images[file.exists(img_id)]
dim(filtered_images) # 11510     3

# 2. Extract file metadata for time and date of capture
metadata <- recordTable(
  inDir = img_dir,
  IDfrom = "directory",
  removeDuplicateRecords = FALSE,
  timeZone = "UTC",
  video = list(file_formats = c("jpg", "AVI", "mp4", "m4v"), dateTimeTag = "QuickTime:CreateDate")
) %>% as.data.table()

# Generate a column named file_path by joining the directory and the FileName columns with a /
metadata[, file_path := file.path(Directory, FileName)]

# Join the filtered_images with the metadata table, keeping all rows in filtered_images
result <- merge(filtered_images, metadata, by.x = "img_id", by.y = "file_path", all.x = TRUE)

# Extract the folder name from the img_id column
result[, folder := sub("data/images_from_videos/([^/]+)/.*", "\\1", img_id)]

# Remove the _extracted or _<number>_extracted part from the folder name to get the label
result[, lab := sub("_\\d{1,}_extracted$|_extracted$", "", folder)]

# Read the annotations file
annotations <- fread("bin/finetunning_files/PW_FT_classification/data/imgs/annotation_example.csv")

# Get unique classifications and labels from the annotations
classification <- unique(annotations[, .(classification, label)])

# Merge the result with the classification data on the label
result <- merge(result, classification, by.x = "lab", by.y = "label", all.x = TRUE)

# Assign a unique classification to rows with NA classification, starting from 16
result[is.na(result$classification), classification := .GRP + 15, by = lab]

# Keep and rename the selected columns
annotations <- result[, .(path = img_id, classification, label, Photo_Time = DateTimeOriginal, Location = folder)]


annotations[, new_path := paste0("bin/finetunning_files/PW_FT_classification/data/imgs/",label,"_video_",basename(path))]

# Copy files to a single folder in the finetunning
annotations[, file.copy(from = path, to = new_path, overwrite = TRUE), by = 1:nrow(annotations)]

# Save metadata 
video_annots <- annotations[,.(path = basename(new_path),classification, label, Photo_Time, Location )] 

# video_annots %>% write.csv(.,file = "data/annotations_video.csv", row.names = F)


##### 

# Join jpg annotations with video annotations

annots_jpg <- fread("bin/finetunning_files/PW_FT_classification/data/imgs/annotation_example.csv")
annotations_join <- rbind(annots_jpg, video_annots)

write.csv(annotations_join,file = "bin/finetunning_files/PW_FT_classification/data/imgs/annotations_join.csv", row.names = F)
