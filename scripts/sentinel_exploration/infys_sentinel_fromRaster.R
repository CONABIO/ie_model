library(terra)
library(ggplot2)
library(fuzzyjoin)
library(ggpubr)
library(gridExtra)
library(tidyterra)

r_sentinel <- terra::rast('data/sentinel/sentinel_mm_year_40.tif')
# r_sentinel <- terra::project(r_sentinel, "epsg:4326")
terra::res(r_sentinel)
distance(cbind(0,-21), cbind(0,-21.0001388889), lonlat=TRUE)

ggplot() +
  geom_spatraster(data = r_sentinel)

# df_sentinel <- terra::as.data.frame(r_sentinel, xy = TRUE, na.rm = FALSE) 
# hist(df_sentinel$VV)

##### extract from point
df_sentinel <- terra::extract(r_sentinel, 
                              df_infys_arb %>% 
                                select(X_C3,Y_C3), 
                              xy = TRUE)

df_sentinel <- df_sentinel %>% 
  #drop_na(VV) %>% 
  rename(X_C3=x, Y_C3=y) #%>% 
  #left_join(df_infys_arb, by=c('X_C3','Y_C3'))


df_sentinel <- df_sentinel %>% 
  difference_inner_join(df_infys_arb,
                        max_dist = 0.001,
                        by=c('X_C3','Y_C3'))

var_plot <- c('Altura_mean','Altura_sd','Altura_median',
              'Altura_min','Altura_max','n')
p <- list()
for (i in 1:6) {
  p[[i]] <- ggplot(df_sentinel, aes(y=.data[[var_plot[i]]], x=VV)) +
    geom_point() +
    ylab(var_plot[i]) +
    stat_cor(method = "pearson")
}

grid.arrange(p[[1]], p[[2]], p[[3]], p[[4]], p[[5]], p[[6]],
             nrow = 2)

##### extract from neighborhood 
cell_indices <- cellFromXY(r_sentinel, as.matrix(df_infys_arb %>% 
                             select(X_C3,Y_C3)))

cell_adj <- adjacent(r_sentinel, directions = "8",
                     include=TRUE,
                     cells = cell_indices)

df_sentinel_adj <- list()
df_sentinel_adj[[1]] <- cell_indices
for(i in 1:ncol(cell_adj)) {
  val <- terra::extract(r_sentinel, y=cell_adj[,i])
  df_sentinel_adj[[i+1]] <- val
}
df_sentinel_adj = do.call(cbind, df_sentinel_adj)

df_sentinel_adj$raster_value <- rowMeans(df_sentinel_adj[,2:ncol(df_sentinel_adj)])
df_sentinel_adj <- cbind(df_sentinel_adj,xyFromCell(r_sentinel,df_sentinel_adj[,1]))

df_sentinel_adj <- df_sentinel_adj %>% 
  select(x,y,raster_value) %>% 
  rename(X_C3=x, Y_C3=y)

df_sentinel_adj <- df_sentinel_adj %>% 
  difference_inner_join(df_infys_arb,
                        max_dist = 0.001,
                        by=c('X_C3','Y_C3'))

var_plot <- c('Altura_mean','Altura_sd','Altura_median',
              'Altura_min','Altura_max','n')
p <- list()
for (i in 1:6) {
  p[[i]] <- ggplot(df_sentinel_adj, aes(y=.data[[var_plot[i]]], x=raster_value)) +
    geom_point() +
    ylab(var_plot[i]) +
    stat_cor(method = "pearson")
}

grid.arrange(p[[1]], p[[2]], p[[3]], p[[4]], p[[5]], p[[6]], 
             nrow = 2,
             top = "Spring")

ggplot(df_sentinel_adj, aes(y=n, x=raster_value)) +
  geom_point() +
  ylab('n') +
  stat_cor(method = "pearson")

##### estimate texture
# library(GLCMTextures)
# glcm <- glcm_textures(
#   r_sentinel,
#   w = c(27, 27),
#   n_levels=16,
#   shift = list(c(1, 0), c(1, 1), c(0, 1), c(-1, 1)),
#   metrics = c("glcm_entropy", 
#               "glcm_mean", 
#               "glcm_variance"),
#   quantization = 'equal range'
#   )