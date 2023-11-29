# creates dataframe with values from rasters over slic shapefile polygons

library('tidyverse')
library('terra')
library('collapse')
library('sf')

input_folder <- 'data/model_input/rasters'
slic_folder <- 'data/model_input/slic'
categorical_variables <- c("hemerobia",
                           "holdridge",
                           "land_cover")

sf <- terra::vect(paste0(slic_folder,'/slic.shp'))

raster_files <- list.files(input_folder, ".tif$", full.names = TRUE)
col_names <- gsub('.tif','',raster_files)
col_names <- gsub(paste0(input_folder,'/'),'',col_names)

r_variables <- rast(raster_files)
names(r_variables) <- col_names
numerical_variables <- setdiff(col_names, categorical_variables)

# coord <- c(3950523, 3960316, 888945.4, 900515)
# r_variables <- terra::crop(r_variables,coord)
# sf <- crop(sf,coord)

r_cat <- r_variables[[categorical_variables]]
r_num <- r_variables[[numerical_variables]]

extract_cat <- terra::extract(r_cat, sf, fun='modal',
                               na.rm=TRUE)
extract_num <- terra::extract(r_num, sf, fun='mean',
                              na.rm=TRUE)

df_final <- extract_num %>% 
  left_join(extract_cat, by=c('ID'))

write.csv(df_final, paste0(slic_folder,'/df_xgb_input_slic.csv'),
          row.names = FALSE)