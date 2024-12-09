######
# Script : Download files from google drive
# Author: Sofía Zorrilla
# Date: `r Sys.Date()`
# Description: Download shared files in google drive to local folder
# Arguments:
#   - Input: 
#   - Output: 
#######

# --- Load packages ---
library(googledrive)

drive_auth()

# --- List files ---

# Extract file ids
parent_folder_id <- "1q672mV_e2cWqOnpYX_ZK-HP04amaw9JX"

# Get all directories
folders <- drive_ls(as_id(parent_folder_id))
folders$local_name <- str_replace_all(folders$name," ","_")

# Create local base directory
base_dir <- "/mnt/STORAGE/csar/pipo_images"

# Create local folders
sapply(folders$name, function(folder) {
  dir.create(file.path(base_dir, folder), recursive = TRUE, showWarnings = FALSE)
})

# Loop through each file and download it
# Function to download files with error handling

download_files <- function(files, localPath) {
  # Ensure the local directory exists
  dir.create(localPath, recursive = TRUE, showWarnings = FALSE)
  
  for (i in 1:nrow(files)) {
    # Define the local file path
    file_path <- file.path(localPath, files$name[i])
    
    # Check if the file already exists
    if (!file.exists(file_path)) {
      # Try to download the file
      try({
        drive_download(
          file = as_id(files$id[i]),   # File ID
          path = file_path,            # Save to local directory
          overwrite = FALSE            # Overwrite set to FALSE
        )
        cat(paste("Downloaded:", files$name[i], "\n"))
      }, silent = TRUE)
    } else {
      cat(paste("Skipped (already exists):", files$name[i], "\n"))
    }
  }
}

# Main loop to process folders
for (i in 2:nrow(folders)) {
  # List files in the current folder
  files <- drive_ls(as_id(folders$id[i]))
  
  # Define the local path for the folder
  localPath <- file.path(base_dir, folders$local_name[i])
  
  # Download files
  download_files(files, localPath = localPath)
}


# Confirm download completion
cat("All files have been downloaded to the 'downloaded_files' folder.")

