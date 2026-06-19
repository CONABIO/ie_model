# Predict ecological integrity raster with XGBoost trained model and input data

library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')

set.seed(1)

xgb_predict <- function(input_folder = 'data/model_input/dataframe/2024',
                        output_files = c(
                          'ie' = 'output/predictions/xgb/v4/ie_xgb_2024.tif',
                          'probability' = 'output/predictions/xgb/v4/ie_xgb_2024_prob.tif'
                        ),
                        model_folder = 'output/models/xgb/v4',
                        mask_file = 'data/sources/mex_mask/Mask_IE2018.tif',
                        categorical_variables = c('holdridge',
                                                  'land_cover'),
                        ignore_variables = c('hemerobia'),
                        is_slic = FALSE) {
  # ==================Processing data======================
  # Read data
  df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
    map_dfr(read_csv)
  xgb.fit <- xgb.load(file.path(model_folder, 'xgb.fit'))
  model_variables <- read.csv(file.path(model_folder, 'variables_list.csv'))$x
  r_mask <- terra::rast(mask_file)
  if (is_slic) {
    slic_polygons <- terra::vect(file.path(input_folder, 'slic.shp'))
  }

  df <- df %>%
    select(-any_of(ignore_variables)) %>%
    drop_na() %>%
    mutate(across(all_of(categorical_variables),
                  as.factor))

  # Create dummies for categorical
  df <- dummy_cols(df, select_columns = categorical_variables)

  # Keep only the variables used to train the model, in the training order.
  missing_variables <- setdiff(model_variables, names(df))
  if (length(missing_variables) > 0) {
    stop(
      'Missing model variables in prediction dataframe: ',
      paste(missing_variables, collapse = ', ')
    )
  }
  df_model <- df %>%
    select(all_of(model_variables))

  # Transform the data set into xgb.Matrix
  xgb.matrix <- xgb.DMatrix(data = as.matrix(df_model))
  # ====================Predicting==========================
  xgb.pred <- as.data.frame(predict(xgb.fit, xgb.matrix, reshape = T))
  colnames(xgb.pred) <- seq(0, ncol(xgb.pred) - 1)
  df$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred, 1, which.max)])
  df$prob <- apply(xgb.pred, 1, max)
  # =================Creating raster========================
  if (is_slic) {
    # Add missing IDs
    df_aux <- as.data.frame(1:max(df$ID))
    names(df_aux) <- 'ID'
    df <- df %>%
      right_join(df_aux, by = 'ID') %>%
      arrange(ID)

    # Create raster
    slic_polygons$prediction <- as.numeric(df$prediction)
    r_pred <- terra::rasterize(slic_polygons, r_mask, field = "prediction")

    slic_polygons$prob <- as.numeric(df$prob)
    r_prob <- terra::rasterize(slic_polygons, r_mask, field = "prob")

  } else {
    # Create raster
    r_pred <- terra::rast(df %>%
                            select(x, y, prediction))
    terra::crs(r_pred) <- terra::crs(r_mask)

    r_prob <- terra::rast(df %>%
                            select(x, y, prob))
    terra::crs(r_prob) <- terra::crs(r_mask)
  }

  dir.create(dirname(output_files['ie']), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(output_files['probability']), recursive = TRUE, showWarnings = FALSE)
  terra::writeRaster(r_pred,
                     output_files['ie'],
                     overwrite = TRUE)
  terra::writeRaster(r_prob,
                     output_files['probability'],
                     overwrite = TRUE)

  invisible(list(prediction = r_pred,
                 probability = r_prob))
}
