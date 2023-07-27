library(terra)
library(ggplot2)
library(tidyterra)

r_base <- terra::rast('data/sources/hemerobia/raw/2017/hemerobia.tif')

# create rasters from mad_mex
r_madmex <- terra::rast('data/sources/mad_mex/raw/2018/mad_mex.tif')
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
# 29 = asentamientos, 30 = suelo_desnudo
# 32 = cultivos_pastizales, 33 = matorral, 34 = selva, 35 = bosque
madmex_val <- c(29,30,32,33,34,35)
madmex_name <- c('asentamientos','suelo_desnudo','cultivos_pastizales',
                 'matorral','selva','bosque')
for (i in 2:length(madmex_val)) {
  print(i)
  mad_mex_cat_value <- madmex_val[[i]]
  f_pct_cat <- function(v){sum(v==mad_mex_cat_value, na.rm = TRUE)/length(v)}
  r_madmex_v <- aggregate(r_madmex, 8, f_pct_cat)
  r_madmex_v <- project(r_madmex_v, r_base)
  writeRaster(r_madmex_v, paste0('data/sources/mad_mex/processed/2018/mad_mex_',
                                 madmex_name[[i]],'.tif'), 
              overwrite=TRUE)
}
ggplot() +
  geom_spatraster(data = r_madmex_v)