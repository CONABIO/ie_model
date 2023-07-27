# load packages
library("bnlearn")
library("gRain")
library("raster")
library("ggplot2")
library("tidyterra")

df <- read_csv('data/model_input/df_input_model_5.csv')
prior <- readRDS('output/prior_test.RData')

# prediction
prediction <- predict(prior,
                      response="hemerobia",
                      newdata=df,
                      type="distribution")
probabilities <- prediction$pred$hemerobia

# raster with standardized expectancy
expectancy <- probabilities %*%  as.numeric(colnames(probabilities)) 
expectancy <- (18-expectancy)/(18)
r_exp <- terra::rast(data.frame(x=df$x,y=df$y,ie=expectancy))
crs(r_exp) <- crs_text

# raster with most probable category
category <- colnames(probabilities)[apply(probabilities,1,which.max)]
r_cat <- terra::rast(data.frame(x=df$x,y=df$y,ie=category))
crs(r_cat) <- crs_text

# ggplot() +
#   geom_spatraster(data = r_cat)
# freq(r_exp)

# save rasters
writeRaster(r_exp, 'output/ie_exp_test.tif', overwrite=TRUE)
writeRaster(r_cat, 'output/ie_cat_test.tif', overwrite=TRUE)