# Estimates accuracy of ecological integrity estimation

library('tidyverse')
library('terra')

r_ei <- terra::rast('output/ie_xgb_slic/march/ie_xgb_slic_2017_march.tif')
r_hemerobia <- terra::rast('output/models/xgb slic v7/hemerobia_slic.tif')

df_is_train <- read_csv('output/models/xgb slic v7/is_train.csv') # Indicator of training
slic_file <- 'data/model_input/slic/2017/slic.shp'
is_slic <- TRUE

r_hemerobia <- project(r_hemerobia, r_ei)

if(is_slic) {
  sf <- terra::vect(slic_file)
  # Add missing IDs
  df_aux <- as.data.frame(1:max(df_is_train$ID))
  names(df_aux) <- 'ID'
  df_is_train <- df_is_train %>% 
    right_join(df_aux) %>% 
    arrange(ID)
  
  # Create raster
  sf$is_train <- as.numeric(df_is_train$is_train)
  r_is_train <- rasterize(sf, r_ei, field="is_train")
  
} else {
  # Create raster
  r_is_train <- terra::rast(df_is_train)
  crs(r_is_train) <- crs(r_ei)
}

# Get dataframe
df <- terra::as.data.frame(c(r_hemerobia,
                             r_is_train,
                             r_ei),
                     xy = TRUE, na.rm = TRUE) 

# Separate in training and testing
df_train <- df %>% 
  filter(is_train==1)
df_test <- df %>% 
  filter(is_train==0)

# Estimate overall, training and testing accuracy
mean(df$prediction==df$hemerobia)
mean(df_train$prediction==df_train$hemerobia)
mean(df_test$prediction==df_test$hemerobia)
confusionMatrix(as.factor(df_test$hemerobia), as.factor(df_test$prediction))

# Estimate accuracy and area covered stratified by holdridge
df_accuracy_train <- df_train %>% 
  select(holdridge,prediction,hemerobia) %>% 
  group_by(holdridge) %>% 
  summarise(acc_pct = round(mean(prediction == hemerobia)*100,2),
            area_pct = round(n()/nrow(df_train)*100,2))
df_accuracy_test <- df_test %>% 
  select(holdridge,prediction,hemerobia) %>% 
  group_by(holdridge) %>% 
  summarise(acc_pct = round(mean(prediction == hemerobia)*100,2),
            area_pct = round(n()/nrow(df_test)*100,2))