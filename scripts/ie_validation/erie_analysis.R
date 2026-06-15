library(tidyverse)
library(broom)
library(terra)
library(ROCit)

# Mapa de IE
r_ei <- terra::rast('data/ie/ie_xgb_slic_2023.tif')
r_ei <- terra::project(r_ei, "epsg:4326", method='near')

# Mapa de Hemerobia
r_hem <- terra::rast('data/hemerobia/hemerobia_slic.tif')
r_hem <- terra::project(r_hem, "epsg:4326", method='near')

# Mapa de IE red bayesiana
r_ei_bn <- terra::rast('data/ie/ie2018_250mgw.tif')
r_ei_bn <- terra::project(r_ei_bn, "epsg:4326", method='near')


# Número de individuos de cierta especie en una foto
df <- read.csv('data/erie/ERIE_integridad.csv')

# Extraer el valor de IE por coordenadas
df$ie_value <- terra::extract(r_ei, 
                              df %>% select(longitud_gps,
                                            latitud_gps),
                              method='exact')$prediction
df$ie <- ifelse(df$ie_value >= 4, 'Degradado', 'Integro')

df$hem_value <- terra::extract(r_hem, 
                              df %>% select(longitud_gps,
                                            latitud_gps),
                              method='exact')$hemerobia
df$hem <- ifelse(df$hem_value >= 4, 'Degradado', 'Integro')

df$ie_bn_value <- terra::extract(r_ei_bn, 
                                 df %>% select(longitud_gps,
                                               latitud_gps),
                                 method='exact')$ie2018_250mgw
df$ie_bn <- ifelse(df$integrity_250m_2018 >= 0.75, 'Integro', 'Degradado')

df$erie <- ifelse(df$valor >= 70, 'Integro', 'Degradado')

ggplot(data=df, aes(valor, -ie_value)) +
  geom_point()

ggplot(data=df, aes(valor, integrity_250m_2018)) +
  geom_point()

ggplot(data=df, aes(valor, color=ie)) +
  geom_density()

ggplot(data=df, aes(valor, color=ie_bn)) +
  geom_density()


df %>% 
  group_by(ie) %>% 
  summarise(mean = mean(valor))

tb <- table(df$ie, df$erie)
tb
tb_bn <- table(df$ie_bn, df$erie)
tb_bn

(tb[1,1]+tb[2,2])/sum(tb)
(tb_bn[1,1]+tb_bn[2,2])/sum(tb)

tb[2,1]/sum(tb)
tb_bn[2,1]/sum(tb_bn)



## Warning: package 'ROCit' was built under R version 3.5.2
ROCit_obj <- rocit(score=df$valor,class=df$ie_bn)
plot(ROCit_obj)
