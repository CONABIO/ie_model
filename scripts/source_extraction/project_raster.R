# Projects raster to mask's extent, epsg and resolution

library('terra')
library('tidyterra')
 
input_file <- 'data/sources/sentinel/raw/2023/march/VH.tif'
output_file <- 'data/sources/sentinel/processed/2023/march/vh_median.tif'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'  # reference raster
# projection_method <- 'near'  # interpolation method for categorical data
projection_method <- 'bilinear'  # interpolation method for numerical data

r_mask <- terra::rast(mask_file)
r_raster <- terra::rast(input_file)

# Only use to fill MODIS GPP NA values with 0, otherwise comment out
# r_raster <- ifel(is.na(r_raster), 0, r_raster)

# Project raster to mask's extent, epsg and resolution
r_raster <- project(r_raster, r_mask, method=projection_method)

# Assign NA to raster when mask is NA
r_raster <- mask(r_raster, r_mask)

writeRaster(r_raster, output_file, overwrite=TRUE)