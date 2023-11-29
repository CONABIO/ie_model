# creates dataframes from rasters by partitioning in nx*ny tiles

library('terra')
library('ggplot2')
library('tidyterra')
library('SpaDES.tools')

input_folder <- 'data/model_input/rasters'
output_folder <- 'data/model_input/dataframe'
nx <- 3
ny <- 2

raster_files <- list.files(input_folder, ".tif$", full.names = TRUE)

col_names <- gsub('.tif','',raster_files)
col_names <- gsub(paste0(input_folder,'/'),'',col_names)

raster_list <- rast(raster_files)
raster_splited <- splitRaster(raster_list, nx=nx, ny=ny)

for (r in 1:(nx*ny)) {
  print(r)
  raster <- raster_splited[[r]]
  
  # convert to dataframe
  df_raster <- terra::as.data.frame(raster,
                                    xy = TRUE, na.rm = TRUE) 
  
  names(df_raster)[3:ncol(df_raster)] <- col_names
  
  write.csv(df_raster, paste0(output_folder,'/df_input_model_',
                              r,'.csv'),
            row.names = FALSE)
}