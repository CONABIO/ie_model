library('terra')
library('ggplot2')
library('tidyterra')
library('tidyverse')

exp_folder <- 'output/bn v2/df_expectancy'
cat_folder <- 'output/bn v2/df_categorical'
crs_file <- 'data/model_input/crs/crs.RData'
output_folder <- 'output/bn v2'

df_exp <- list.files(exp_folder, full.names = TRUE) %>%
  map_dfr(read_csv)
df_cat <- list.files(cat_folder, full.names = TRUE) %>%
  map_dfr(read_csv)
crs_text <- readRDS(crs_file)

# raster with standardized expectancy
r_exp <- terra::rast(df_exp)
crs(r_exp) <- crs_text

# raster with most probable category
r_cat <- terra::rast(df_cat)
crs(r_cat) <- crs_text

ggplot() +
  geom_spatraster(data = r_exp) +
  scale_fill_gradient2(low = "red",
                         mid = "beige",
                         high="darkgreen",
                         midpoint = 0.5)
ggplot() +
  geom_spatraster(data = r_cat) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9)

# save rasters
writeRaster(r_exp, paste0(output_folder,'/ie_exp.tif'), 
            overwrite=TRUE)
writeRaster(r_cat, paste0(output_folder,'/ie_cat.tif'), 
            overwrite=TRUE)