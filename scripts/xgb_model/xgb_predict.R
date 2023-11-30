# predict ecological integrity raster with xgb model

library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')
library('ggplot2')
library('caret')

set.seed <- 1

input_folder <- 'data/model_input/dataframe'
output_folder <- 'output'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'
categorical_variables <- c('land_cover',
                           'holdridge')

# read data
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv)
xgb.fit <- xgb.load(paste0(output_folder,'/xgb v1/xgb.fit'))
r_mask <- terra::rast(mask_file)

df <- df %>% 
  select_if(!names(.) %in% c('hemerobia'))

df <- df  %>% 
  mutate(across(all_of(categorical_variables), 
                as.factor))

# Create dummy variables:
df <- dummy_cols(df, select_columns = categorical_variables)

# Transform the data set into xgb.Matrix
xgb.matrix <- xgb.DMatrix(data=as.matrix(df %>% 
                                         select(-c('x','y',
                                                   categorical_variables
                                                   ))),
                        label=as.integer(df$hemerobia)-1)

# Predict outcomes
xgb.pred <- as.data.frame(predict(xgb.fit,xgb.matrix,reshape=T))
colnames(xgb.pred) <- c(seq(1,16,by=1),18)
df$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])

# Create raster
r_pred <- terra::rast(df)
crs(r_pred) <- crs(r_mask)
plot(-r_pred)
writeRaster(r_pred, paste0(output_folder,'/ie_xgb_2021.tif'), 
            overwrite=TRUE)