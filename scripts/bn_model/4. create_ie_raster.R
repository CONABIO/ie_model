# Creates raster based on csv with coordinates and values

library('terra')
library('tidyverse')

input_folder <- 'output/bn v2/df_expectancy'
output_file <- 'output/bn v2/ie_exp.tif'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'

df <- list.files(input_folder, full.names = TRUE) %>%
  map_dfr(read_csv)
r_mask <- terra::rast(mask_file)

# Convert to raster
raster <- terra::rast(df)
crs(raster) <- crs(r_mask)

# Save raster
writeRaster(r_exp, paste0(output_folder,'/ie_exp.tif'), 
            overwrite=TRUE)