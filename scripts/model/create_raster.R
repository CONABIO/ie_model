library("terra")
library("ggplot2")
library("tidyterra")
library("tidyverse")

df_exp <- list.files('output/df_expectancy', full.names = TRUE) %>%
  map_dfr(read_csv)
df_cat <- list.files('output/df_categorical', full.names = TRUE) %>%
  map_dfr(read_csv)
crs_text <- readRDS("data/prediction_input/crs.RData")
# df_hem <- read.csv('data/prediction_input/df_input_test.csv')

# raster with standardized expectancy
r_exp <- terra::rast(df_exp)
crs(r_exp) <- crs_text

# raster with most probable category
r_cat <- terra::rast(df_cat)
crs(r_cat) <- crs_text

ggplot() +
  geom_spatraster(data = r_exp)
ggplot() +
  geom_spatraster(data = r_cat)
# table(df_cat$ie,df_hem$hemerobia)
# sqrt(mean((as.numeric(df_hem$hemerobia) - df_cat$ie)^2))

# save rasters
# writeRaster(r_exp, 'output/ie_exp.tif', overwrite=TRUE)
# writeRaster(r_cat, 'output/ie_cat.tif', overwrite=TRUE)