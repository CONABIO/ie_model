# Estimates accuracy of ecological integrity estimation

library('tidyverse')
library('terra')

r_ei <- terra::rast('output/bn v1/ie_cat.tif')
r_hemerobia <- terra::rast('data/model_input/rasters/hemerobia.tif')
df_is_train <- read_csv('output/xgb v1/is_train.csv') # Indicator of training

r_hemerobia <- project(r_hemerobia, r_ei)
r_is_train <- terra::rast(df_is_train)
crs(r_is_train) <- crs(r_ei)

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
mean(df$ie==df$hemerobia_raw)
mean(df_train$prediction==df_train$hemerobia)
mean(df_test$prediction==df_test$hemerobia)
confusionMatrix(df_test$hemerobia, as.factor(df_test$prediction))

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