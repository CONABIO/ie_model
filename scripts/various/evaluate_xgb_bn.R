library('terra')
library('ggplot2')
library('tidyterra')
library('tidyverse')
library('cowplot')

crs_text <- readRDS(paste0('data/model_input/crs/crs.RData'))
r_ie_2018 <- terra::rast('data/sources/ie_2018/ie_2018_st_v2.tif')
r_ie_2018_cat <- round(-1*(r_ie_2018*18-18),0)
r_hem <- terra::rast('data/model_input/rasters/hemerobia.tif')
r_xgb <- terra::rast('output/xgb v1/ie_xgb.tif')
r_xgb <- project(r_xgb, r_hem)
r_xgb_slic <- terra::rast('output/ie_xgb_slic.tif')
r_bn <- terra::rast('output/bn v1/ie_cat.tif')
r_bn <- project(r_bn, r_hem)
r_hold <- terra::rast('data/model_input/rasters/holdridge.tif')

r_tag_slic <- terra::rast('output/r_tag.tif')
df_train <- read_csv('output/xgb v1/df_train.csv') %>% select(x,y)
df_test <- read_csv('output/xgb v1/df_test.csv') %>% select(x,y)
df_train$train <- 1
df_test$train <- 0
r_tag <- terra::rast(rbind(df_train,df_test))
crs(r_tag) <- crs_text
r_tag <- project(r_tag, r_hem)
rm(df_train)
rm(df_test)

df_raster <- terra::as.data.frame(c(r_hem, 
                                    r_xgb,
                                    r_xgb_slic,
                                    r_bn),
                                  xy = TRUE, na.rm = TRUE) 
names(df_raster) <- c('x','y',
                      'hemerobia',
                      'xgb',
                      'xgb_slic',
                      'bn')
df_raster2 <- terra::as.data.frame(c(r_tag,
                                     r_tag_slic,
                                     r_ie_2018_cat,
                                     r_hold),
                                  xy = TRUE, na.rm = TRUE) 
names(df_raster2) <- c('x','y',
                       'tag',
                       'tag_slic',
                       'ie_2018',
                       'hold')

df_raster <- df_raster %>% 
  left_join(df_raster2, by=c('x','y'))
rm(df_raster2)

mean(df_raster$hemerobia == df_raster$ie_2018, na.rm=TRUE)
mean(df_raster$hemerobia == df_raster$bn, na.rm=TRUE)
mean(df_raster$hemerobia == df_raster$xgb, na.rm=TRUE)
mean(df_raster$hemerobia == df_raster$xgb_slic, na.rm=TRUE)

df_raster <- df_raster %>% 
  mutate(acc_ie_2018 = ifelse( (ie_2018 <= hemerobia + 1) & 
                            (ie_2018 >= hemerobia - 1),
                          1,0)) %>% 
  mutate(acc_bn = ifelse( (bn <= hemerobia + 1) & 
                                 (bn >= hemerobia - 1),
                               1,0)) %>% 
  mutate(acc_xgb = ifelse( (xgb <= hemerobia + 1) & 
                            (xgb >= hemerobia - 1),
                          1,0)) %>% 
  mutate(acc_xgb_slic = ifelse( (xgb_slic <= hemerobia + 1) & 
                             (xgb_slic >= hemerobia - 1),
                           1,0)) 
mean(df_raster$acc_ie_2018)
mean(df_raster$acc_bn)
mean(df_raster$acc_xgb)
mean(df_raster$acc_xgb_slic)

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
  filter(tag_slic==1) %>% 
  group_by() %>% 
  summarise(mean(hemerobia==xgb_slic))
df_raster %>%
  filter(tag_slic==0) %>% 
  group_by() %>% 
  summarise(mean(hemerobia==xgb_slic))

df_raster %>%
  filter(tag==1) %>% 
  group_by() %>% 
  summarise(mean(hemerobia==xgb))
df_raster %>%
  filter(tag==0) %>% 
  group_by() %>% 
  summarise(mean(hemerobia==xgb))


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
  geom_spatraster(data =  crop(r_xgb,coord)) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9) +
  ggtitle('2017 IE XGB')
plot_grid(plt_hem, plt_ie_cat, plt_xgb,
          labels = "AUTO")




plt_xgb <- ggplot() +
  geom_spatraster(data =  crop(r_xgb,coord)) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9) + 
  theme(legend.position = "none") +
  ggtitle('XGB predicción')

plt_slic <- ggplot(sf) +
  tidyterra::geom_spatvector(aes(fill = hem), 
                             color = "white") +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9) + 
  theme(legend.position = "none") +
  ggtitle('SLIC')

plt_hem <- ggplot() +
  tidyterra::geom_spatraster(data=r_cat[[1]]) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9) + 
  theme(legend.position = "none") +
  ggtitle('Hemerobia')

plot_grid(plt_hem, plt_xgb, plt_slic,
            labels = "AUTO", ncol=3)
ggsave('output/slic_comparison.jpg')
