library("tidyverse")
library("terra")
library("ggplot2")
library("tidyterra")


r_hem_2017 <- terra::rast('data/sources/hemerobia/raw/2017/hemerobia.tif')
r_hem_2008 <- terra::rast('data/sources/hemerobia/raw/2008/hemerobia.tif')

val_hem_2017 <- values(r_hem_2017)
values(r_hem_2017) <- (18-val_hem_2017)/18

ggplot() +
  geom_spatraster(data = r_hem_2008)
ggplot() +
  geom_spatraster(data = r_hem_2017)

r_diff <- diff(c(r_hem_2017,r_hem_2008))
ggplot() +
  geom_spatraster(data = r_diff)


library(corrplot)

df <- read_csv('data/model_input/df_input_model_5.csv')
df <- df %>% 
  dplyr::select(-c('mad_mex_bosque','mad_mex_matorral'))

df <- list.files('data/model_input/dataframe', full.names = TRUE) %>%
  map_dfr(read_csv)
res <- cor(df)
corrplot(res, type = "upper", order = "hclust", 
         tl.col = "black", tl.srt = 90)
plot(df$modis_dry,df$modis_rainy)
