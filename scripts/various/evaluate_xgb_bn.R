library('terra')
library('ggplot2')
library('tidyterra')
library('tidyverse')
library('cowplot')

crs_text <- readRDS(paste0('data/model_input/crs/crs.RData'))
r_ie_2018 <- terra::rast('data/sources/ie_2018/ie_2018_st_v2.tif')
r_hem <- terra::rast('data/model_input/rasters/hemerobia.tif')
r_ie_cat <- round(-1*(r_ie_2018*18-18),0)
r_xgboost <- terra::rast('output/ie_xgb.tif')
r_xgboost <- project(r_xgboost, r_hem)
r_hold <- terra::rast('data/model_input/rasters/holdridge.tif')

df_train <- read_csv('output/df_train.csv') %>% select(x,y)
df_test <- read_csv('output/df_test.csv') %>% select(x,y)
df_train$train <- 1
df_test$train <- 0
r_tag <- terra::rast(rbind(df_train,df_test))
crs(r_tag) <- crs_text
r_tag <- project(r_tag, r_hem)
rm(df_train)
rm(df_test)

plt_hem <- ggplot() +
  geom_spatraster(data =  r_hem) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9) +
  ggtitle('2017 Hem')
plt_ie_cat <- ggplot() +
  geom_spatraster(data =  r_ie_cat) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9) +
  ggtitle('2018 IE cat')
plt_xgb <- ggplot() +
  geom_spatraster(data =  r_xgboost) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9) +
  ggtitle('2017 IE XGB')
plot_grid(plt_hem, plt_ie_cat, plt_xgb,
          labels = "AUTO")

df_raster <- terra::as.data.frame(c(r_hem, 
                                    r_xgboost,
                                    r_hold,
                                    r_tag),
                                  xy = TRUE, na.rm = TRUE) 
df_ie_2018 <- terra::as.data.frame(c(r_ie_cat),
                                  xy = TRUE, na.rm = TRUE) 
df_raster <- df_raster %>% 
  left_join(df_ie_2018, by=c('x','y'))
rm(df_ie_2018)

mean(df_raster$hemerobia_raw == df_raster$ie_2018_st_v2)
mean(df_raster$hemerobia_raw == df_raster$prediction)

df_raster <- df_raster %>% 
  mutate(acc_bn = ifelse( (ie_2018_st_v2 <= hemerobia_raw + 2) & 
                            (ie_2018_st_v2 >= hemerobia_raw - 2),
                          1,0)) %>% 
  mutate(acc_xgb = ifelse( (prediction <= hemerobia_raw + 2) & 
                            (prediction >= hemerobia_raw - 2),
                          1,0)) 
mean(df_raster$acc_bn)
mean(df_raster$acc_xgb)

r_acc <- terra::rast(df_raster[,c('x','y','acc_xgb')])
ggplot() +
  geom_spatraster(data =  r_acc) +
  scale_fill_gradient2(low = "red",
                       high="beige",
                       midpoint = 0.5)
writeRaster(r_acc, 'output/xgb_err.tif', 
            overwrite=TRUE)


# Accuracy
df_raster %>%
  filter(train==1) %>% 
  group_by() %>% 
  summarise(mean(hemerobia_raw==prediction))
df_raster %>%
  filter(train==0) %>% 
  group_by() %>% 
  summarise(mean(hemerobia_raw==prediction))

confusionMatrix(as.factor(df_raster %>%
                  filter(train==0) %>% 
                  pull(hemerobia_raw)), 
                as.factor(df_raster %>%
                  filter(train==0) %>% 
                  pull(prediction)))

df_accuracy_train <- df_raster %>%
  filter(train==1) %>% 
  select(zonas_reducidas,prediction,hemerobia_raw) %>% 
  group_by(zonas_reducidas) %>% 
  summarise(acc_pct = round(mean(prediction == hemerobia_raw)*100,2),
            area_pct = round(n()/nrow(df_raster %>%
                                        filter(train==1))*100,2))

df_accuracy_test <- df_raster %>%
  filter(train==0) %>% 
  select(zonas_reducidas,prediction,hemerobia_raw) %>% 
  group_by(zonas_reducidas) %>% 
  summarise(acc_pct = round(mean(prediction == hemerobia_raw)*100,2),
            area_pct = round(n()/nrow(df_raster %>%
                                        filter(train==0))*100,2))

df_accuracy_bn <- df_raster %>% 
  select(zonas_reducidas,ie_2018_st_v2,hemerobia_raw) %>% 
  group_by(zonas_reducidas) %>% 
  summarise(acc_pct = round(mean(ie_2018_st_v2 == hemerobia_raw)*100,2),
            area_pct = round(n()/nrow(df_raster)*100,2))

