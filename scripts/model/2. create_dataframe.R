library(terra)
library(ggplot2)
library(tidyterra)

# m_extent <- list(c(-94.23, -86.59, 14.38, 21.73),
#               c(-108.24, -94.23, 15.06, 22.33),
#               c(-117.89, -103.91, 22.33, 33.04),
#               c(-103.91, -94.54, 22.33, 30.21))
m_extent <- list(c(3343523, 4083316, 288945.4, 1164515),
                 c(1825751, 3295904, 356462.2, 1167037),
                 c(874873, 2320048, 1235591, 2331944),
                 c(2304263, 3218948, 1146775, 3218948))
# m_extent <- list(c(-89.74, -89.20, 20.75, 21.11))
# m_extent <- list(c(3769778, 3822024, 1025675, 1070085))


# List all the raster files in the folder
folder_path <- "data/model_input/rasters"
raster_files <- list.files(folder_path, ".tif$", full.names = TRUE)
col_names <- gsub('.tif','',raster_files)
col_names <- gsub(paste0(folder_path,'/'),'',col_names)

for (r in 1:length(m_extent)) {
  print(r)
  new_extent <- m_extent[[r]]
  
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
  
  # convert to dataframe
  df_raster <- terra::as.data.frame(raster_list,
                                    xy = TRUE, na.rm = TRUE) 
  names(df_raster)[3:ncol(df_raster)] <- col_names
  
  write.csv(df_raster, paste0('data/model_input/dataframe/df_input_model_',
                              r,'.csv'),
            row.names = FALSE)
}

# save crs
crs_text <- crs(raster_list[[1]])
saveRDS(crs_text, "data/prediction_input/crs.RData")  

# ggplot() +
#   geom_spatraster(data = raster_list[[16]])