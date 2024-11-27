# Estimates accuracy of ecological integrity estimation

library('tidyverse')
library('terra')
library('caret')

r_ei <- terra::rast('output/ie_xgb_slic/march_sv_landcovercorrected/ie_xgb_slic_2017.tif')
r_hemerobia <- terra::rast('data/model_input/slic/2017/hemerobia_slic.tif')

df_is_train <- read_csv('output/models/xgb slic v10/is_train.csv') # Indicator of training
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
                     xy = TRUE, na.rm = FALSE) 
df <- df %>% 
  filter(!is.na(hemerobia))

# Separate in training and testing
df_train <- df %>% 
  filter(is_train==1)
df_test <- df %>% 
  filter(is_train==0 
         | is.na(is_train)
         )

# Estimate overall, training and testing accuracy
mean(df$prediction==df$hemerobia, na.rm=T)
mean(df_train$prediction==df_train$hemerobia, na.rm=T)
mean(df_test$prediction==df_test$hemerobia, na.rm=T)

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

# Confusion matrix
cm <- confusionMatrix(factor(df_test$prediction), factor(df_test$hemerobia), 
                      dnn = c("Prediction", "Reference"))

plt <- as.data.frame(cm$table)
plt <- plt %>% 
  group_by(Reference) %>% 
  mutate(n = sum(Freq)) %>% 
  ungroup() %>% 
  mutate(Freq = round((Freq/n)*100))

ggplot(plt, aes(Prediction,Reference, fill= Freq)) +
  geom_tile() + geom_text(aes(label=Freq)) +
  scale_fill_gradient(low="white", high="blue") +
  labs(x = "Prediction",y = "Reference") 


# df_aux <- df_test %>% 
#   mutate(mistake = ifelse((prediction == 1 & hemerobia == 4), 1, 0))
# 
# writeRaster(rast(df_aux %>%
#                    select(c(x,y,mistake))), 
#             "output/models/xgb slic v11/r_mistake_4.tif")