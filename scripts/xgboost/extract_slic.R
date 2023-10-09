library('tidyverse')
library('terra')
library('ggplot2')
library('tidyterra')
library('collapse')
library('sf')
# creates dataframe from rasters over polygons

input_folder <- 'data/model_input/rasters'
output_folder <- 'data/model_input/xgboost'

sf <- terra::vect('data/model_input/slic/slic.shp')

raster_files <- list.files(input_folder, ".tif$", full.names = TRUE)
col_names <- gsub('.tif','',raster_files)
col_names <- gsub(paste0(input_folder,'/'),'',col_names)

r_variables <- rast(raster_files)
names(r_variables) <- col_names



# coord <- c(3890523, 3900316, 888945.4, 900515)
# r_variables <- terra::crop(r_variables,coord)
# sf <- crop(sf,coord)

r_cat <- r_variables[[c(5,6,7)]]
r_num <- r_variables[[-c(5,6,7)]]

extract_cat <- terra::extract(r_cat, sf, fun='modal',
                               na.rm=TRUE)
extract_num <- terra::extract(r_num, sf, fun='mean',
                              na.rm=TRUE)

df_final <- extract_num %>% 
  left_join(extract_cat, by=c('ID'))

write.csv(df_final, 'data/model_input/xgboost/df_xgb_input_slic.csv',
          row.names = FALSE)



sf$hem <- as.numeric(extract_cat$hemerobia)

ggplot(sf) +
tidyterra::geom_spatvector(aes(fill = hem), color = "white")
ggplot() +
  tidyterra::geom_spatraster(data=r_cat[[1]])