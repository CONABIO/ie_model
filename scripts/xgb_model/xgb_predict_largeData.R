# Predict ecological integrity raster with XGBoost trained model
# with sparse matrix

library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')
library('ggplot2')
library('caret')
library('Matrix')

set.seed <- 1

# ======================Input============================
input_folder <- 'xgboost/data'
output_folder <- 'xgboost/output'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'
categorical_variables <- c('land_cover',
                           'holdridge')

# ==================Processing data======================
# Read data
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv) 
xgb.fit <- xgb.load(paste0(output_folder,'/xgb.fit.20'))

df <- df  %>% 
  select_if(!names(.) %in% c('hemerobia')) %>% 
  mutate(across(all_of(categorical_variables),
                as.factor))

# Create dummy variables
spm <- sparse.model.matrix( ~ ., data = df %>% 
                                    select(-c('x','y')))[,-1]

# Transform the two data sets into xgb.Matrix
xgb.matrix <- xgb.DMatrix(data=spm)

# ====================Predicting==========================
xgb.pred <- as.data.frame(predict(xgb.fit,xgb.matrix,reshape=T))
# Hemerobia used in training doesn't have categories 0 and 17
colnames(xgb.pred) <- c(seq(1,16,by=1),18)
df$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])

# =================Creating raster========================
r_pred <- terra::rast(df %>% 
                        select(x, y, prediction))
crs(r_pred) <- crs(r_mask)
plot(-r_pred)
writeRaster(r_pred, paste0(output_folder,'/ie_xgb.tif'), 
            overwrite=TRUE)