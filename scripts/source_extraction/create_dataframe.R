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
  output_files <- character(0)

  for (r in seq_len(nx * ny)) {
    message('Processing tile ', r, ' of ', nx * ny)
    raster <- raster_splited[[r]]

    # Convert to dataframe and save it.
    df_raster <- terra::as.data.frame(raster,
                                      xy = TRUE,
                                      na.rm = TRUE)
    if (nrow(df_raster) == 0) {
      message('  skipped empty tile')
      next
    }

    names(df_raster)[3:ncol(df_raster)] <- col_names

    output_file <- file.path(output_folder, paste0('df_input_model_', r, '.csv'))
    write.csv(df_raster, output_file, row.names = FALSE)
    output_files <- c(output_files, output_file)
  }

  invisible(output_files)
}
