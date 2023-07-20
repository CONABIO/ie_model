library(tidyverse)
library(ggplot2)
library(ggpubr)
library(gridExtra)
library(sf)
library(ggh4x)

plot_list_var <- function(df, var_list, var) {
  df_aux <- df %>% 
    gather('var','value', var_list)
  
  plt <- ggplot(df_aux, aes(y=value,x=.data[[var]])) +
    geom_point(alpha=0.1, size=0.1) +
    stat_cor(method = "pearson",label.y.npc="top", label.x.npc = "left") +
    ylab('') +
    theme_minimal() +
    facet_wrap(~ var, scales = "free")
  
  return(plt)
}

plot_list_var_by <- function(df,var_list,var,var_by) {
  df_aux <- df %>% 
    gather('var_aux','value', var_list)
  
  glp <- ggplot(df_aux, aes(y=value, x=.data[[var]])) +
    geom_point(alpha=0.1, size=0.1) +
    stat_cor(method = "pearson") +
    theme_minimal() +
    ylab('') +
    ggh4x::facet_grid2(var_aux ~ .data[[var_by]] , scales = "free")
  
  return(glp)
}

df_sentinel_mean <- read.csv("data/sentinel/raster_infysPoints.csv")
df_sentinel_glcm <- read.csv("data/sentinel/glcm_infysPoints.csv")
sf_ecor <- st_read("data/ecorregiones/ecort08gw.shp")

df_sentinel_mean <- df_sentinel_mean %>% 
  rename(VH = mean)

df_sentinel_infys <- df_infys_arb %>% 
  left_join(df_sentinel_glcm, by='plot_id') %>% 
  left_join(df_sentinel_mean, by='plot_id')


df_sentinel_infys = st_as_sf(df_sentinel_infys, coords = c("X_C3", "Y_C3"), 
                             crs = 'WGS84')

df_sentinel_infys <- st_join(sf_ecor[,c('DESECON1', 'geometry')], 
                    df_sentinel_infys, left=FALSE)

VH_names <- c(grep("^[VH]", names(df_sentinel_infys), value=TRUE))
infys_names <- c('Altura_mean','Altura_sd','Altura_median',
              'Altura_min','Altura_max','n', 'Diametro_median')

### plot VH mean vs Altura_median by ecorregiones
ggplt <- ggplot(df_sentinel_infys, aes(y=Altura_median, x=VH)) +
  geom_point(alpha=0.1, size=0.1) +
  stat_cor(method = "pearson",label.y.npc="bottom") +
  theme_minimal() +
  facet_wrap(~ DESECON1, scales = "free")
ggplt
ggsave(filename = "data/sentinel_infys/VHmean_AlturaMedian_ecorr.png", ggplt,
       width = 10, height = 7, dpi = 300, units = "in", device='png',
       bg='white')



##### plot variable list vs variable
VH_names_plot <- c('VH','VH_corr','VH_imcorr2','VH_savg','VH_sent')
ggplt <- plot_list_var(df_sentinel_infys, VH_names_plot, 'Altura_median')
ggplt
ggsave(filename = "data/sentinel_infys/VHvalues_AlturaMedian.png", ggplt,
       width = 10, height = 7, dpi = 300, units = "in", device='png',
       bg='white')

ggplt <- plot_list_var(df_sentinel_infys, infys_names, 'VH')
ggplt
ggsave(filename = "data/sentinel_infys/InfysValues_VH.png", ggplt,
       width = 10, height = 7, dpi = 300, units = "in", device='png',
       bg='white')

### plot variable list vs variable by ecorregiones
VH_names <- c('VH','VH_corr','VH_imcorr2','VH_savg','VH_sent')
df_aux <- as.data.frame(df_sentinel_infys) %>% 
  gather('var_VH','value_VH', VH_names)
ggplt <- plot_list_var_by(df_aux, infys_names, 'value_VH', 'var_VH')
ggplt
ggsave(filename = "data/sentinel_infys/VHvalues_infysValue.png", ggplt,
       width = 10, height = 7, dpi = 300, units = "in", device='png',
       bg='white')

VH_names <- c('VH','VH_corr','VH_imcorr1','VH_imcorr2','VH_savg','VH_sent')
ggplt <- plot_list_var_by(df_sentinel_infys, VH_names, 'Altura_median', 'DESECON1')
ggplt
ggsave(filename = "data/sentinel_infys/VHvalues_AlturaMedian_ecorr.png", ggplt,
       width = 10, height = 7, dpi = 300, units = "in", device='png',
       bg='white')

ggplt <- plot_list_var_by(df_sentinel_infys, infys_names, 'VH', 'DESECON1')
ggplt
ggsave(filename = "data/sentinel_infys/VH_infysValues_ecorr.png", ggplt,
       width = 10, height = 7, dpi = 300, units = "in", device='png',
       bg='white')






#### lr
VH_names <- grep("^[VH]", names(df_sentinel_infys), value=TRUE)
  
df_aux <- as.data.frame(df_sentinel_infys %>% 
                          filter(DESECON1=='Sierras Templadas') %>% 
                          select(all_of(c('Altura_median',VH_names)))) %>% 
  select(-geometry)

lm_Altura = lm(Altura_median ~ ., data = df_aux)
summary(lm_Altura)
plot(lm_Altura)

summary(as.factor(df_sentinel_infys$DESECON1))
