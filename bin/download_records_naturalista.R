######
# Script : Download inaturalist images for each species 
# Author: Sofía Zorrilla
# Date: 2024-12-10
# Description: Search and download complementary images from naturalista.
#######

# --- Load packages ---

library(rinat)
library(data.table)
library(stringr)
library(rgbif)
library(lubridate)


# --- Functions ---

capitalize_first_word <- function(string) {
  substr(string, 1, 1) <- toupper(substr(string, 1, 1))
  return(string)
}

select_columns_with_na <- function(df, columns) {
  #' Select Columns from DataFrame and Assign NA to Non-Existent Columns
  #'
  #' This function selects a list of columns from a dataframe and assigns NA to any column that doesn't exist.
  #'
  #' @param df A dataframe from which to select columns.
  #' @param columns A character vector of column names to select.
  #' @return A dataframe with the specified columns. Columns that do not exist in the original dataframe will be filled with NA.
  
  # Create a copy of the dataframe to avoid modifying the original
  df_copy <- df
  
  # Iterate over the list of columns
  for (col in columns) {
    # Check if the column exists in the dataframe
    if (!col %in% names(df_copy)) {
      # If the column doesn't exist, add it with NA values
      df_copy[[col]] <- NA
    }
  }
  
  # Select the specified columns (including those added with NA values)
  df_selected <- df_copy[, columns, drop = FALSE]
  
  return(df_selected)
}


# --- Normalize taxonomic data ---

taxon_names <- fread("taxons.txt", drop = 1)
taxon_names[,folder_name := capitalize_first_word(tolower(str_replace(label,'_',' ')))]


resultados <- apply(taxon_names, 1, function(fila) {
  name_backbone(
    name = fila["folder_name"],
    kingdom = 'Animalia'
  )
}) 

res <- lapply(resultados, select_columns_with_na, c("verbatim_name","scientificName","class","confidence","phylum","order","family","genus","species")) %>% do.call(rbind,.) %>% setDT()
res[5,2:9] <- NA
res$label <- taxon_names$label
res$classification <- taxon_names$classification

# --- Download data ---

taxons <- as.list(res$species[!is.na(res$species)])
place_id <- 8150
max_results <- 150

# Download observations from iNaturalist
observations <- lapply(taxons, function(taxon, place = 8150, max_results = 150) {
    print(paste("Downloading:", taxon))
    result <- try(get_inat_obs(taxon_name = taxon, place = place, maxresults = max_results, quality = "research"), silent = TRUE)
    if (inherits(result, "try-error")) {
      print(paste("Error downloading:", taxon))
      return(NULL)
    }
    return(result)
  })

df_ls <- lapply(observations[-12],select_columns_with_na,c("scientific_name","datetime","latitude","longitude","image_url"))
df_ls <- lapply(df, function(x){
  setDT(x)
  temp_df <- merge(x,res[,.(verbatim_name, label, species, classification)],by.x = "scientific_name", by.y = "species")
  temp_df[, datetime := ymd_hms(datetime, tz = "Etc/GMT+6")]
  temp_df[, datetime := format(datetime, "%Y-%m-%d %H:%M:%S")]
  temp_df[, filename := paste0(str_remove(tools::toTitleCase(scientific_name),' '),'_',sprintf('%02d',.I),'.JPG')]
  return(temp_df)
})

library(httr)
library(tools)

process_dataframes <- function(df_list) {
  lapply(df_list, function(df) {
    # Ensure the dataframe has the necessary columns
    if (!all(c("label", "image_url", "filename") %in% names(df))) {
      stop("Dataframe must contain 'label', 'image_url', and 'filename' columns")
    }
    
    # Create folders based on the label column
    unique_labels <- unique(df$label)
    sapply(unique_labels, function(label) {
      dir_path <- file.path("img", label)
      if (!dir.exists(dir_path)) {
        dir.create(dir_path, recursive = TRUE)
      }
    })
    
    # Download files and set their names
    df[, {
      label_dir <- file.path("img", label)
      file_path <- file.path(label_dir, filename)
      download_success <- try(GET(image_url, write_disk(file_path, overwrite = TRUE)), silent = TRUE)
      if (inherits(download_success, "try-error")) {
        message(paste("Failed to download:", image_url))
      }
    }, by = 1:nrow(df)]
  })
}

process_dataframes(df_ls)

metadata_raw <- do.call(rbind,df_ls) %>% data.table()

# --- Update dataframes based on the manual revision of images ---

# Extract list of folders
folders <- list.dirs('img', full.names = T)

# Extract file names from folders, construct basic path metadata
file_names <- lapply(seq_along(folders)[-1], function(x){data.frame(OrigFolder = str_remove(folders[[x]],"img/"), 
                                                                    FolderPath = folders[[x]],
                                                                    OrigFile = list.files(folders[[x]]))})
file_df <- do.call(rbind,file_names)

# Filter to only keep revised files
metadata <- metadata_raw[filename %in% file_df$OrigFile,]

#fwrite(metadata, 'inaturalist_image_metadata.csv')

#--- Construct the annotations file and copy images to a single folder ---
# I ran this in my local computer so the files were transfered after


annotation <- merge(metadata,file_df,by.x = "filename", by.y = "OrigFile")
annotation[,path := file.path(FolderPath,filename)]
annots <- annotation[,.(path,classification,label,Photo_Time = datetime, Location = OrigFolder)]

if (!dir.exists("img/img")) {
  dir.create("img/img")
}

annots[, new_path := file.path("img/img",basename(path))]
annots[, file.copy(path, new_path)]
annots[, path := new_path][,new_path := NULL]
annots[, path := file.path("img", basename(path))]

fwrite(annots,"naturalista_annotations_jpg.csv", row.names = F)

# rsync -avz img/img/ sofia@100.126.235.53:/home/sofia/Documentos/pipeline_CameraTrap/data/img/
# rsync -avz naturalista_annotations_jpg.csv sofia@100.126.235.53:/home/sofia/Documentos/pipeline_CameraTrap/data/
