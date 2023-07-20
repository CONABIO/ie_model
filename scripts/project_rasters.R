library(terra)
library(ggplot2)
library(tidyterra)

# load sentinel rasters and merge them
img <- list.files('data/sentinel/vh/raw/2017', "tif$", full.names=TRUE)
ic <- sprc(lapply(img, rast))
r_sentinel <- mosaic(ic)
writeRaster(r_sentinel, 'data/sentinel/vh/processed/2017/vh.tif', 
            overwrite=TRUE)

r_sentinel <- terra::rast('data/sources/sentinel/vh/processed/2017/vh.tif')

# project each raster to sentinel's extent, epsg and resolution
input_file <- 'data/sources/hemerobia/raw/2017/hemerobia.tif'
output_file <- 'data/sources/hemerobia/processed/2017/hemerobia.tif'
projection_method <- 'mode'
r_raster <- terra::rast(input_file)
r_raster <- project(r_raster, r_sentinel, method = projection_method)
writeRaster(r_raster, output_file, overwrite=TRUE)

ggplot() +
  geom_spatraster(data = r_raster)
freq(r_raster)

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
  geom_spatraster(data = r_madmex_v)


###########
r_modis <- terra::rast('data/modis/raw/2017/modis_sd.tif')
r_madmex <- terra::rast('data/mad_mex/raw/2018/mad_mex.tif')
r_hemerobia <- terra::rast('data/hemerobia/raw/2017/hemerobia.tif')
r_dem90 <- terra::rast('data/dem90/CEM_15m_ITRF08.tif')
r_sentinel_1 <- terra::rast('data/sentinel/bands/raw/2017/VH_annual_raster1.tif')
r_sentinel_glcm <- terra::rast('data/sentinel/glcm/raw/2017/VH_glcm_annual_raster1.tif')
r_madmex_asent <- terra::rast('data/mad_mex/processed/2018/mad_mex_bosque.tif')
r_hol <- terra::rast('data/holdridge/processed/zvh_31_lcc_h.tif')
distance(cbind(0,-21), cbind(0,-21.002245788), lonlat=TRUE)


r_hol <- project(r_hol, "epsg:4326")
r_modis <- project(r_modis, r_sentinel)
r_madmex <- project(r_madmex, r_sentinel)
r_hemerobia <- project(r_hemerobia, r_sentinel)
r_dem90 <- project(r_dem90, r_sentinel)

writeRaster(r_modis, "data/modis/processed/2017/modis_rainy.tif", overwrite=TRUE)

#r_madmex <- terra::project(r_madmex, "epsg:4326")
#r_madmex <- crop(r_madmex, ext(r_sentinel))

ggplot() +
  geom_spatraster(data = r_hol)