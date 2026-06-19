# Projects raster to mask's extent, epsg and resolution

library('terra')
library('tidyterra')

project_raster <- function(input_file = 'data/sources/sentinel/raw/2024/VH.tif',
                           output_file = 'data/model_input/rasters/2024/vh.tif',
                           mask_file = 'data/sources/mex_mask/Mask_IE2018.tif',
                           projection_method = 'bilinear',
                           fill_na_value = NULL) {
  r_mask <- terra::rast(mask_file)
  r_raster <- terra::rast(input_file)

  if (!is.null(fill_na_value)) {
    r_raster <- terra::ifel(is.na(r_raster), fill_na_value, r_raster)
  }

  # Project raster to mask's extent, epsg and resolution.
  r_raster <- terra::project(r_raster, r_mask, method = projection_method)

  # Assign NA to raster when mask is NA.
  r_raster <- terra::mask(r_raster, r_mask)

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  terra::writeRaster(r_raster, output_file, overwrite = TRUE)

  invisible(r_raster)
}
