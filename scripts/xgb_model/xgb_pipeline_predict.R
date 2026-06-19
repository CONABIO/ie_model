# Pipeline to project rasters, create model input dataframes, and predict IE.

library('yaml')

source('scripts/source_extraction/project_raster.R')
source('scripts/source_extraction/create_dataframe.R')
source('scripts/xgb_model/xgb_predict.R')

config <- yaml::read_yaml('scripts/xgb_model/xgb_pipeline_predict.yml')

for (raster_config in config$rasters) {
  message('Projecting raster: ', raster_config$name)

  project_raster(
    input_file = raster_config$input_file,
    output_file = raster_config$output_file,
    mask_file = config$mask_file,
    projection_method = raster_config$projection_method,
    fill_na_value = raster_config$fill_na_value
  )
}

message('Creating dataframe tiles...')
create_dataframe(
  input_folder = config$dataframe$input_folder,
  output_folder = config$dataframe$output_folder,
  nx = config$dataframe$nx,
  ny = config$dataframe$ny
)

message('Predicting ecological integrity...')
xgb_predict(
  input_folder = config$prediction$input_folder,
  output_files = unlist(config$prediction$output_files),
  model_folder = config$prediction$model_folder,
  mask_file = config$mask_file,
  categorical_variables = unlist(config$prediction$categorical_variables),
  ignore_variables = unlist(config$prediction$ignore_variables),
  is_slic = config$prediction$is_slic
)

message('Pipeline complete.')
