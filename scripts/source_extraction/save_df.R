library(terra)
library(ggplot2)
library(tidyterra)


# List all the raster files in the folder
folder_path <- "data/model_input/rasters"
raster_files <- list.files(folder_path, ".tif$", full.names = TRUE)
col_names <- gsub('.tif','',raster_files)
col_names <- gsub(paste0(folder_path,'/'),'',col_names)

# load one part of sentinel to crop the rest of the rasters
r_sentinel <- terra::rast('data/sources/sentinel/vh/raw/2017/VH_annual_raster1.tif')
new_extent <- ext(r_sentinel)
  
# xmin <- -89.73915847117459
# xmax <- -89.19670852000272
# ymax <- 21.10739725000344
# ymin <- 20.753379789634703
# new_extent <- c(xmin, xmax, ymin, ymax)

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

write.csv(df_raster, 'data/model_input/dataframe/df_input_model_1.csv', 
          row.names = FALSE)

# r_raster <- terra::rast('data/model_input/rasters/hemerobia.tif')
# r_raster <- crop(r_raster,new_extent)
# ggplot() +
#   geom_spatraster(data = r_raster)
# 
