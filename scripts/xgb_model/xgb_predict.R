# Predict ecological integrity raster with XGBoost trained model and input data

library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')
library('ggplot2')
library('caret')
library('sf')
library('fasterize')

set.seed <- 1

# ======================Input============================
input_folder <- 'data/model_input/slic/2022'
output_files <- c('ie' = 'output/ie_xgb_slic/march_sv_edgedistancecorrected/ie_xgb_slic_2022.tif',
                  'probability' = 'output/ie_xgb_slic/march_sv_edgedistancecorrected/ie_xgb_slic_2022_prob.tif')
model_folder <- 'output/models/xgb slic v11'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'
categorical_variables <- c('holdridge',
                           'land_cover')
# remove_variables <- c('hemerobia','edge_distance')
remove_variables <- c('hemerobia')

is_slic <- TRUE # TRUE if the model uses SLIC, FALSE if not

# ==================Processing data======================
# Read data
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv)
xgb.fit <- xgb.load(paste0(model_folder,'/xgb.fit'))
variables_list <- read.csv(paste0(model_folder,'/variables_list.csv'))
r_mask <- terra::rast(mask_file)
if(is_slic){
  sf <- terra::vect(paste0(input_folder,'/slic.shp'))
  coordinates_var <- c('ID')
} else {
  coordinates_var <- c('x','y')
}

df <- df %>% 
  select_if(!names(.) %in% remove_variables) %>%
  drop_na() %>% 
  mutate(across(all_of(categorical_variables), 
                as.factor))

# Create dummies for categorical
df <- dummy_cols(df, select_columns = categorical_variables)

# Check if we have all the input variables
missing_var <- setdiff(variables_list$x,names(df)) 
missing_var
setdiff(names(df),variables_list$x)
if(!identical(missing_var, character(0))) {
  df[missing_var] <- 0
}

# Transform the data set into xgb.Matrix
xgb.matrix <- xgb.DMatrix(data=as.matrix(df %>% 
                                         select(variables_list$x)))
all(colnames(xgb.matrix)==variables_list$x)
# ====================Predicting==========================
xgb.pred <- as.data.frame(predict(xgb.fit,xgb.matrix,reshape=T))
# Hemerobia used in training doesn't have categories 0 and 17
colnames(xgb.pred) <- c(seq(1,16,by=1),18)
df$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])
df$prob <- apply(xgb.pred, 1, max)
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
  
  sf$prob <- as.numeric(df$prob)
  r_prob <- rasterize(sf, r_mask, field="prob")
  
} else {
  # Create raster
  r_pred <- terra::rast(df %>% 
                          select(x, y, prediction))
  crs(r_pred) <- crs(r_mask)
  
  r_prob <- terra::rast(df %>% 
                          select(x, y, prob))
  crs(r_prob) <- crs(r_mask)
}

plot(-r_pred)
plot(r_prob)
writeRaster(r_pred, 
            output_files['ie'], 
            overwrite=TRUE)
writeRaster(r_prob, 
            output_files['probability'], 
            overwrite=TRUE)