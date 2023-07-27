library(terra)
library(ggplot2)
library(tidyterra)

r_base <- terra::rast('data/sources/hemerobia/raw/2017/hemerobia.tif')

# load sentinel rasters and merge them
output_file <- 'data/sources/sentinel/vh_glcm/processed/2017/vh_entropy.tif'
img <- list.files('data/sources/sentinel/vh_glcm/raw/2017', "tif$", 
                  full.names=TRUE)
ic <- sprc(lapply(img, rast))
r_sentinel <- mosaic(ic)

r_sentinel <- project(r_sentinel, r_base)

# ggplot() +
#   geom_spatraster(data = r_sentinel)

writeRaster(r_sentinel, output_file, overwrite=TRUE)

# r_sentinel_1 <- r_sentinel['VH_sent']
# writeRaster(r_sentinel_1, 'data/sources/sentinel/vh_glcm/processed/2017/VH_sent.tif',
#             overwrite=TRUE)