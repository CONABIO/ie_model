# create rasters from mad_mex with the proportion of each category 

library('terra')
library('ggplot2')
library('tidyterra')

input_file <- 'data/sources/mad_mex/raw/2017/madmex_landsat_2017_31.tif'
output_folder <- 'data/sources/mad_mex/processed/2017'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'

r_mask <- terra::rast(mask_file)
r_madmex <- terra::rast(input_file)

# aggregate categories
# 29 = asentamientos, 30 = suelo_desnudo
# 32 = cultivos_pastizales, 33 = matorral, 34 = selva, 35 = bosque
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

# estimate percentage of each level 
madmex_val <- c(29,30,32,33,34,35)
madmex_name <- c('asentamientos','suelo_desnudo','cultivos_pastizales',
                 'matorral','selva','bosque')
for (i in 1:length(madmex_val)) {
  print(i)
  mad_mex_cat_value <- madmex_val[[i]]
  # create raster with value 1 if the pixel belongs to 
  # certain category
  r_madmex_v <- ifel(r_madmex == mad_mex_cat_value, 1, 0)
  # project from 30m to 250m resolution
  # and with average we get the proportion of each category
  r_madmex_v <- project(r_madmex_v, r_mask, method='average')
  r_madmex_v <- mask(r_madmex_v, r_mask)
  writeRaster(r_madmex_v, paste0(output_folder,'/mad_mex_',
                                 madmex_name[[i]],'.tif'), 
              overwrite=TRUE)
}