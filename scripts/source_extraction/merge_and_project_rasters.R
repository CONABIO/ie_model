library('terra')
library('ggplot2')
library('tidyterra')

# merges rasters in folder and projects to r_mask's extent, epsg and resolution
input_folder <- 'data/sources/dem90/raw'
output_file <- 'data/sources/dem90/processed/dem90_max.tif'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'
projection_method <- 'max'

r_mask <- terra::rast(mask_file)

# load sentinel rasters and merge them
file_list <- list.files(input_folder, "tif$", 
                  full.names=TRUE)
ic <- sprc(lapply(file_list, rast))
r_raster <- mosaic(ic)

r_raster_projected <- project(r_raster, r_mask, method=projection_method)
r_raster_projected <- mask(r_raster_projected, r_mask)

ggplot() +
  geom_spatraster(data = r_raster_projected)

writeRaster(r_raster_projected, output_file, overwrite=TRUE)