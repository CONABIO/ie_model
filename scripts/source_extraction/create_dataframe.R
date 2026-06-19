# Creates dataframes from rasters by partitioning in nx*ny tiles

library('terra')
library('ggplot2')
library('tidyterra')
library('SpaDES.tools')

create_dataframe <- function(input_folder = 'data/model_input/rasters/2024',
                             output_folder = 'data/model_input/dataframe/2024',
                             nx = 3,
                             ny = 2) {
  dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

  # Read rasters.
  raster_files <- list.files(input_folder, "\\.tif$", full.names = TRUE)
  raster_list <- terra::rast(raster_files)

  # Save rasters' names to name dataframe columns.
  col_names <- tools::file_path_sans_ext(basename(raster_files))

  # Split rasters in nx*ny tiles and iterate through them.
  raster_splited <- SpaDES.tools::splitRaster(raster_list, nx = nx, ny = ny)
  output_files <- character(nx * ny)

  for (r in seq_len(nx * ny)) {
    print(r)
    raster <- raster_splited[[r]]

    # Convert to dataframe and save it.
    df_raster <- terra::as.data.frame(raster,
                                      xy = TRUE,
                                      na.rm = TRUE)
    names(df_raster)[3:ncol(df_raster)] <- col_names

    output_files[r] <- file.path(output_folder,
                                 paste0('df_input_model_', r, '.csv'))
    write.csv(df_raster, output_files[r], row.names = FALSE)
  }

  invisible(output_files)
}
