library('terra')
library('ggplot2')
library('tidyterra')

# project raster to r_mask's extent, epsg and resolution
input_file <- 'data/sources/modis/raw/2018/modis_sd.tif'
output_file <- 'data/sources/modis/processed/2018/modis_sd.tif'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'
projection_method <- 'near'
# projection_method <- 'average'

r_mask <- terra::rast(mask_file)
r_raster <- terra::rast(input_file)

r_raster <- ifel(is.na(r_raster), 0, r_raster) # fill modis gpp NA
r_raster <- project(r_raster, r_mask, method=projection_method)
r_raster <- mask(r_raster, r_mask)

ggplot() +
  geom_spatraster(data = r_raster)

writeRaster(r_raster, output_file, overwrite=TRUE)