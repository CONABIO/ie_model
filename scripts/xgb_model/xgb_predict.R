# Predict ecological integrity raster with XGBoost trained model and input data

library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')
library('ggplot2')
library('caret')
library('sf')
library('fasterize')

# ======================Input============================
input_folder <- 'data/model_input/dataframe'
output_folder <- 'output'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'
categorical_variables <- c('land_cover',
                           'holdridge')
is_slic <- TRUE # TRUE if the model uses SLIC, FALSE if not

# ==================Processing data======================
# Read data
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv)
xgb.fit <- xgb.load(paste0(output_folder,'/xgb v1/xgb.fit'))
r_mask <- terra::rast(mask_file)
if(is_slic){
  sf <- terra::vect(paste0(input_folder,'/slic.shp'))
  coordinates_var <- c('ID')
} else {
  coordinates_var <- c('x','y')
}

df <- df %>% 
  select_if(!names(.) %in% c('hemerobia')) %>% 
  drop_na() %>% 
  mutate(across(all_of(categorical_variables), 
                as.factor))

# Create dummies for categorical
df <- dummy_cols(df, select_columns = categorical_variables)

# Transform the data set into xgb.Matrix
xgb.matrix <- xgb.DMatrix(data=as.matrix(df %>% 
                                         select(-c(coordinates_var,
                                                   categorical_variables
                                                   ))))

# ====================Predicting==========================
xgb.pred <- as.data.frame(predict(xgb.fit,xgb.matrix,reshape=T))
# Hemerobia used in training doesn't have categories 0 and 17
colnames(xgb.pred) <- c(seq(1,16,by=1),18)
df$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])

# =================Creating raster========================
if(is_slic) {
  # Add missing IDs
  df_aux <- as.data.frame(1:max(df$ID))
  names(df_aux) <- 'ID'
  df <- df %>% 
    right_join(df_aux) %>% 
    arrange(ID)
  
  # Create raster
  sf$prediction <- as.numeric(df$prediction)
  r_pred <- rasterize(sf, r_mask, field="prediction")
  
} else {
  # Create raster
  r_pred <- terra::rast(df %>% 
                          select(x, y, prediction))
  crs(r_pred) <- crs(r_mask)
}

plot(-r_pred)
writeRaster(r_pred, paste0(output_folder,'/ie_xgb_2021.tif'), 
            overwrite=TRUE)