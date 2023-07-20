library(terra)
library(tidyverse)
library(ggplot2)
library(tidyterra)

r_hemerobia <- terra::rast('data/hemorobia/hemerobia2008.tif')
df_snmb <- read.csv("data/snmb/df_an_im.csv")
r_hemerobia <- terra::project(r_hemerobia, "epsg:4326")


ggplot() +
  geom_spatraster(data = r_hemerobia)


df_coordinates <- df_snmb %>% 
  group_by(latitude,longitude) %>% 
  summarise()
plot(df_coordinates$longitude,df_coordinates$latitude)

df_hemerobia <- terra::extract(r_hemerobia, 
                               df_snmb %>% 
                                group_by(longitude,latitude) %>% 
                                summarise(), 
                              xy = TRUE)
df_counts <- df_snmb %>% 
  filter(label=='Tapirella bairdii') %>% 
  group_by(latitude, longitude,date,image_id,label) %>% 
  summarise(count=n()) %>% 
  group_by(latitude, longitude,date,label) %>% 
  summarise(count=max(count)) %>% 
  group_by(latitude, longitude,label) %>% 
  summarise(count=sum(count)) %>% 
  spread(label,count) %>% 
  rename(x = longitude, y = latitude)
df_counts$total_count <- rowSums(df_counts[,3:ncol(df_counts)],
                                 na.rm = TRUE)

df_hemerobia_counts <- df_hemerobia %>% 
  difference_inner_join(df_counts, max_dist = 0.001, by=c('x','y'))

plot(df_hemerobia_counts$hemerobia2008,df_hemerobia_counts$total_count)
plot(df_hemerobia_counts$x.x,df_hemerobia_counts$y.x)
summary(df_hemerobia_counts$total_count)


ggplt <- ggplot() +
  geom_spatraster(data = r_hemerobia) +
  scale_fill_viridis_c(alpha=0.8) +
  geom_point(data = df_hemerobia_counts, aes(x = x.x, y = y.x, col=total_count),
             shape=9) +
  scale_colour_gradient(low = "pink", high = "red")
ggplt
ggsave(filename = "data/snmb/hemerobia_snmb.png", ggplt,
       width = 10, height = 7, dpi = 1000, units = "in", device='png',
       bg='white')


sort(unique(df_snmb$label))


df_aux <- df_snmb %>% 
  filter(label=='Leopardus wiedii')
