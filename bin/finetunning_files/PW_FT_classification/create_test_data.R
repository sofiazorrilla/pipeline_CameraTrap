######
# Script : Create subset of Pipo's data for testing training algorithm
# Author: Sofía Zorrilla
# Date: `r Sys.Date()`
# Description: 
# Arguments:
#   - Input: 
#   - Output: 
#######

# --- Load packages ---

library(data.table)
library(stringr)


# --- Load data ---

data <- fread('test_data/imgs/annotation_example.csv')

subset <- data[,.SD[sample(.N, 3, replace = F)], by = label]

dir.create('data/imgs', recursive = T)

subset[,current_path := file.path("test_data/imgs",basename(path))]
subset[,file.copy(current_path,file.path("data/imgs",basename(path)), overwrite = F)]
subset[,current_path := NULL]
subset[, path := str_remove(path,"imgs/")]
fwrite(subset, "data/imgs/annotation_example.csv",row.names = F)
