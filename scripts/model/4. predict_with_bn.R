# load packages
library("bnlearn")
library("terra")
library("ggplot2")
library("tidyterra")

df <- read.csv('data/prediction_input/df_input_test.csv')
prior <- readRDS('data/prediction_input/prior_test.RData')
crs_text <- readRDS("data/prediction_input/crs.RData")

# prediction
start.time <- Sys.time()
prediction <- predict(prior,
                      response="hemerobia",
                      newdata=df,
                      type="distribution")
end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

probabilities <- prediction$pred$hemerobia

# raster with standardized expectancy
expectancy <- probabilities %*%  as.numeric(colnames(probabilities)) 
expectancy <- (18-expectancy)/(18)
df_exp <- data.frame(x=df$x,y=df$y,ie=expectancy)
r_exp <- terra::rast(df_exp)
crs(r_exp) <- crs_text

# raster with most probable category
category <- colnames(probabilities)[apply(probabilities,1,which.max)]
df_cat <- data.frame(x=df$x,y=df$y,ie=category)
r_cat <- terra::rast(df_cat)
crs(r_cat) <- crs_text

ggplot() +
  geom_spatraster(data = r_exp)
ggplot() +
  geom_spatraster(data = r_cat)
table(as.factor(as.numeric(category)),df$hemerobia)
sqrt(mean((as.numeric(df$hemerobia) - expectancy)^2))

# save rasters
writeRaster(r_exp, 'output/ie_exp_test.tif', overwrite=TRUE)
writeRaster(r_cat, 'output/ie_cat_test.tif', overwrite=TRUE)