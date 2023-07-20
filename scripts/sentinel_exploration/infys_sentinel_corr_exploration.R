library(tidyverse)
library(ggplot2)
library(ggpubr)
library(gridExtra)


df_sentinel_mean <- read.csv("data/sentinel/raster_infysPoints.csv")
df_sentinel_glcm <- read.csv("data/sentinel/glcm_infysPoints.csv")


df_sentinel_infys <- df_sentinel_mean %>% 
  left_join(df_sentinel_glcm, by='plot_id') %>% 
  left_join(df_infys_arb, by='plot_id')


var_plot <- c('Altura_mean','Altura_sd','Altura_median',
              'Altura_min','Altura_max','n')
var_x <- c('mean','VV_contrast','VV_savg','VV_corr')

p <- list()
for (i in 1:6) {
  p[[i]] <- ggplot(df_sentinel_infys, aes(y=.data[[var_plot[i]]], x=VH_corr)) +
    geom_point() +
    ylab(var_plot[i]) +
    stat_cor(method = "pearson")
}

grid.arrange(p[[1]], p[[2]], p[[3]], p[[4]], p[[5]], p[[6]],
             nrow = 2)
