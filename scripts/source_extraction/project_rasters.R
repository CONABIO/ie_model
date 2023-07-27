library(terra)
library(ggplot2)
library(tidyterra)

r_base <- terra::rast('data/sources/hemerobia/raw/2017/hemerobia.tif')

# project each raster to r_base's extent, epsg and resolution
input_file <- 'data/sources/holdridge/raw/zvh_mx3gw.tif'
output_file <- 'data/sources/holdridge/processed/holdridge.tif'

r_raster <- terra::rast(input_file)

# projection_method <- 'min'
# r_raster <- ifel(is.na(r_raster), 0, r_raster) # fill modis NA
r_raster <- project(r_raster, r_base)

ggplot() +
  geom_spatraster(data = r_raster)
# freq(r_raster)

writeRaster(r_raster, output_file, overwrite=TRUE)

# distance(cbind(0,-21), cbind(0,-21.002245788), lonlat=TRUE)