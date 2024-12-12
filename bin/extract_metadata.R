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
library(stringr)
library(data.table)
library(tidyverse)


## Ruta al directorio parental que contiene todas las carpetas.
dir <- "/mnt/STORAGE/csar/pipo_images"

## Genera tabla con metadatos de las imagenes. 
## Station: nombre del folder que contiene las fotos
## IDfrom: (directory name or metadata if it has tags)
## cameraID: puede extraer el id de la camara del directorio o del nombre del archivo
## removeDuplicateRecords: (same species, same station, same cameraID if defined and same time)
## 

# Extract list of folders
folders <- list.dirs(dir, full.names = T)

# Extract file names from folders, construct basic path metadata
file_names <- lapply(seq_along(folders)[-1], function(x){data.frame(OrigFolder = str_remove(folders[[x]],"/mnt/STORAGE/csar/pipo_images/"), 
                                                                    FolderPath = folders[[x]],
                                                                    OrigFile = list.files(folders[[x]]))})
file_df <- do.call(rbind,file_names)
file_df <- mutate(file_df, path = paste0(FolderPath,"/",OrigFile))

# Extract additional metadata from files (date,time)
metadata <- recordTable(inDir  = dir,
                               IDfrom = "directory",
                               removeDuplicateRecords = F,
                               timeZone = "UTC",
                               video = list(file_formats = c("jpg","AVI","mp4","m4v"), dateTimeTag = "QuickTime:CreateDate"))

metadata <- mutate(metadata, path = paste0(Directory,"/",FileName))

# Join tables (not all files could be analized with metadata because they did not contain date and time)

RawDF <- left_join(file_df, metadata, by = c("OrigFile"="FileName","OrigFolder"="Species", "path"="path")) %>% data.table()

# Subset to keep only jpg, add columns for classification (one class per label), labels and path
df_jpg <- RawDF[str_detect(OrigFile,".JPG"), .(OrigFolder,OrigFile,DateTimeOriginal,path)][,OrigFolder:= str_remove(OrigFolder,"_2022")]

df_jpg[, classification := .GRP - 1, by = OrigFolder]

df_jpg <- df_jpg[,.(path,classification,label = OrigFolder, Photo_Time = DateTimeOriginal,Location = OrigFolder)]

# Save file.
# 1044 files
#                    AVES     BASSSEISCUS_ASTUTUS    CONEPATUS_LEUCONOTUS 
#                     307                       2                      14 
#    DIDELPHIS_VIRGINIATA                  GANADO         LEOPARDU_wiedii 
#                       6                      13                       3 
#              LYNX_RUFUS        MEPITIS_MACROURA            NASUA_NARICA 
#                       3                       1                       4 
#  ODOCOILEUS_VIRGINIANUS           PECARI_TAJACU           PUMA_CONCOLOR 
#                     344                     212                      24 
#        SCIURUS_OCOLATUS      SPILOGALE_GRACILIS           SYLVILAGUS_SP 
#                       6                       2                      31 
# UROCYON_CINEREORGENTEUS 
#                      72 

write.csv(df_jpg,file = "data/annotations_jpg.csv", row.names = F)

### Copy the jpg files to img folder

# Create the new folder if it doesn't exist
if (!dir.exists("data/img")) {
  dir.create("data/img")
}

df_jpg[, new_path := file.path("/home/sofia/Documentos/pipeline_CameraTrap/data/img", basename(path))]

df_jpg[, file.copy(path, new_path)]

df_jpg[, path := new_path][,new_path := NULL]
df_jpg[, path := file.path("img", basename(path))]

write.csv(df_jpg, file = "data/updated_annotations_jpg.csv", row.names = FALSE)

table(df_jpg$label)

# --- Join Pipo metadata with naturalista metadata ---

pipo <- fread('data/updated_annotations_jpg.csv')
naturalista <- fread('data/naturalista_annotations_jpg.csv')

join <- rbind(pipo,naturalista) 
table(join$label)

fwrite(join, 'data/joinPipoNaturalista_annotations.csv', row.names = F)
