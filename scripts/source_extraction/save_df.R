library(terra)
library(ggplot2)
library(tidyterra)


# List all the raster files in the folder
folder_path <- "data/model_input/rasters"
raster_files <- list.files(folder_path, ".tif$", full.names = TRUE)
col_names <- gsub('.tif','',raster_files)
col_names <- gsub(paste0(folder_path,'/'),'',col_names)

# load one part of sentinel to crop the rest of the rasters
r_sentinel_1 <- terra::rast('data/sources/sentinel/vh/raw/2017/VH_annual_raster4.tif')
new_extent <- ext(r_sentinel_1)

# Create an empty list to store the modified rasters
raster_list <- c()

# Loop through the raster files
for (i in seq_along(raster_files)) {
  # Read the raster
  raster <- rast(raster_files[i])
  
  # Change the extent of the raster
  raster <- crop(raster,new_extent)
  
  # Add the raster to the list
  raster_list <- append(raster_list,c(raster))
}

# ggplot() +
#   geom_spatraster(data = raster_list[[1]])

# convert to dataframe
df_raster <- terra::as.data.frame(raster_list,
                                  xy = TRUE, na.rm = TRUE) 
names(df_raster)[3:ncol(df_raster)] <- col_names
write.csv(df_raster, 'data/model_input/dataframe/df_input_model_4.csv', 
          row.names = FALSE)
