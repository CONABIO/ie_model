library(terra)
library(ggplot2)
library(fuzzyjoin)
library(ggpubr)
library(gridExtra)
library(tidyterra)

project_and_save <- function(r_base,input_file,
                             projection_method=NULL) {
  r_raster <- terra::rast(input_file)
  r_raster <- project(r_raster, r_base)
  output_file <- gsub("raw", "processed", input_file)
  if (!is.null(projection_method)) {
    output_file <- gsub(".tif", paste0(projection_method,'.tif'), output_file)
  } 
  writeRaster(r_raster, output_file, overwrite=TRUE)
}

# load sentinel rasters and merge them
img <- list.files('data/sentinel/vh/raw/2017', "tif$", full.names=TRUE)
ic <- sprc(lapply(img, rast))
r_sentinel <- mosaic(ic)
writeRaster(r_sentinel, 'data/sentinel/vh/processed/2017/vh.tif', 
            overwrite=TRUE)
r_sentinel_test <- terra::rast('data/sentinel/vh/processed/2017/vh.tif')

# project each raster to sentinel's extent, epsg and resolution
input_file <- paste0('data/dem90/raw/2013/CEM_15m_ITRF08.tif')
output_file <- paste0('data/dem90/processed/2013/dem90_max.tif')
r_raster <- terra::rast(input_file)
r_raster <- project(r_raster, r_sentinel)
writeRaster(r_raster, output_file, overwrite=TRUE)

# create rasters from mad_mex
# 29 = asentamientos, 30 = suelo_desnudo
# 32 = cultivos_patizales, 33 = matorral, 34 = selva, 35 = bosque
r_madmex <- terra::rast('data/mad_mex/raw/2018/mad_mex.tif')
freq(r_madmex)
# aggregate categories
r_madmex <- subst(r_madmex, 
                    from=c(27,28,
                           4,5,13:20,
                           7:12,
                           1:3,6), 
                    to=c(32,32,
                         rep(33,10),
                         rep(34,6),
                         rep(35,4))
)
freq(r_madmex)
# estimate percentage of each level 
mad_mex_cat_value <- 35
f_pct_cat <- function(v){sum(v==mad_mex_cat_value, na.rm = TRUE)/length(v)}
r_madmex_v <- aggregate(r_madmex, 8, f_pct_cat)
r_madmex_v <- project(r_madmex_v, r_sentinel)
writeRaster(r_madmex_v, 'data/mad_mex/processed/2018/mad_mex_bosque.tif', 
            overwrite=TRUE)

ggplot() +
  geom_spatraster(data = r_sentinel_test)


r_modis <- terra::rast('data/modis/raw/2017/modis_sd.tif')
r_madmex <- terra::rast('data/mad_mex/raw/2018/mad_mex.tif')
r_hemerobia <- terra::rast('data/hemerobia/hemerobia_2017.tif')
r_dem90 <- terra::rast('data/dem90/CEM_15m_ITRF08.tif')
r_sentinel_1 <- terra::rast('data/sentinel/bands/raw/2017/VH_annual_raster1.tif')
r_sentinel_glcm <- terra::rast('data/sentinel/glcm/raw/2017/VH_glcm_annual_raster1.tif')
r_madmex_asent <- terra::rast('data/mad_mex/processed/2018/mad_mex_bosque.tif')
distance(cbind(0,-21), cbind(0,-21.002245788), lonlat=TRUE)



r_modis <- project(r_modis, r_sentinel)
r_madmex <- project(r_madmex, r_sentinel)
r_hemerobia <- project(r_hemerobia, r_sentinel)
r_dem90 <- project(r_dem90, r_sentinel)

writeRaster(r_modis, "data/modis/processed/2017/modis_rainy.tif", overwrite=TRUE)

#r_madmex <- terra::project(r_madmex, "epsg:4326")
#r_madmex <- crop(r_madmex, ext(r_sentinel))

ggplot() +
  geom_spatraster(data = r_madmex_v)

df_raster <- terra::as.data.frame(c(r_sentinel,
                                    r_hemerobia,
                                    r_modis,
                                    r_madmex,
                                    r_dem90), 
                                  xy = TRUE, na.rm = FALSE) 
df_raster <- df_raster %>% 
  drop_na()

plot(df_raster$x,df_raster$y)



# df_sentinel <- terra::as.data.frame(r_sentinel, xy = TRUE, na.rm = FALSE) 
# hist(df_sentinel$VV)

df_coordinates <- read.csv("data/infys/infys_coordinates.csv")

df_sentinel <- terra::extract(r_madmex,df_coordinates[,1:2], 
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
