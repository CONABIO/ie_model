# Creates dataframe with values from rasters over SLIC shapefile polygons

library('tidyverse')
library('terra')
library('collapse')
library('sf')

input_folder <- 'data/model_input/rasters'
slic_folder <- 'data/model_input/slic/2022'
categorical_variables <- c(
                           # "hemerobia",
                           "holdridge",
                           "land_cover")

# Read files
sf <- terra::vect(paste0(slic_folder,'/slic.shp'))
raster_files <- list.files(input_folder, ".tif$", full.names = TRUE)
r_variables <- rast(raster_files)

# Assign name to rasters
col_names <- gsub('.tif','',raster_files)
col_names <- gsub(paste0(input_folder,'/'),'',col_names)
names(r_variables) <- col_names

# Divide rasters into categorical and numerical
numerical_variables <- setdiff(col_names, categorical_variables)
r_cat <- r_variables[[categorical_variables]]
r_num <- r_variables[[numerical_variables]]

# Extract values over shapefile with mode for categorical and mean for numerical
extract_cat <- terra::extract(r_cat, sf, fun='modal',
                               na.rm=TRUE)
extract_num <- terra::extract(r_num, sf, fun='mean',
                              na.rm=TRUE)

# Join categorical and numerical and save dataframe
df_final <- extract_num %>% 
  left_join(extract_cat, by=c('ID'))
write.csv(df_final, paste0(slic_folder,'/df_xgb_input_slic.csv'),
          row.names = FALSE)