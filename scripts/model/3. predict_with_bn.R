# load packages
library("bnlearn")
library("gRain")
library("raster")
library("ggplot2")
library("tidyterra")

# prediction
prediction <- predict(prior,
                     response="hemerobia",
                     newdata=df,
                     type="distribution")


probabilities <- prediction$pred$hemerobia

ie_expectancy <- list()
for (i in 1:nrow(probabilities)){
  print(i)
  expect <- sum(as.numeric(colnames(probabilities)) * probabilities[i,])
  print(expect)
  ie_expectancy[[i]] <- expect
}

ie <- unlist(ie_expectancy)
ie <- (18-ie)/(18)

final_raster <- data.frame(x=df$x,y=df$y,ie=ie)
summary(final_raster)
final_raster <- rast(final_raster)

ggplot() +
  geom_spatraster(data = final_raster)

# save raster
writeRaster(final_raster, 'output/output_test.tif', overwrite=TRUE)
