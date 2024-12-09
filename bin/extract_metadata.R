######
# Script : title
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

## Ruta al directorio parental que contiene todas las carpetas.
dir <- "/mnt/STORAGE/csar/pipo_images/test"

## Genera tabla con metadatos de las imagenes. 
## Station: nombre del folder que contiene las fotos
## IDfrom: (directory name or metadata if it has tags)
## cameraID: puede extraer el id de la camara del directorio o del nombre del archivo
## removeDuplicateRecords: (same species, same station, same cameraID if defined and same time)
## 

folders <- list.dirs(dir, full.names = T)

files_per_folder <- lapply(folders[-1], function(x){list.files(x)}) 


rec.db.species0 <- recordTable(inDir  = dir,
                               IDfrom = "directory",
                               removeDuplicateRecords = F,
                               timeZone = "UTC",
                               video = list(file_formats = c("jpg","AVI","mp4","m4v"), dateTimeTag = "QuickTime:CreateDate"))

setdiff(files_per_folder[[1]],rec.db.species0$FileName)
