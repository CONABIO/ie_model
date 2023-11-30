library('tidyverse')
library('terra')

r_ei <- terra::rast('output/bn v1/ie_cat.tif')
r_hemerobia <- terra::rast('data/model_input/rasters/hemerobia.tif')
r_hemerobia <- project(r_hemerobia, r_ei)
df_is_train <- read_csv('output/xgb v1/is_train.csv')

r_is_train <- terra::rast(df_is_train)
crs(r_is_train) <- crs(r_ei)

df <- terra::as.data.frame(c(r_hemerobia,
                             # r_is_train,
                             r_ei),
                     xy = TRUE, na.rm = TRUE) 

mean(df$ie==df$hemerobia_raw)


df_train <- df %>% 
  filter(is_train==1)
df_test <- df %>% 
  filter(is_train==0)

mean(df_train$prediction==df_train$hemerobia)
mean(df_test$prediction==df_test$hemerobia)

table(df_test$hemerobia, df_test$prediction)
confusionMatrix(df_test$hemerobia, as.factor(df_test$prediction))

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
