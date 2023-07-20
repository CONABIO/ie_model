# load packages
library("bnlearn")
library("gRain")
library("raster")

# load misc functions
source("./R/0. misc_functions.R")

# prediction
prediction <- predict(prior,
                     response="hemerobia_250m",
                     newdata=bnbrik_df,
                     type="distribution")


probabilities <- prediction$pred$Adelt_vp_250m

ie_expectancy <- list()
for (i in 1:nrow(probabilities)){
  print(i)
  expect <- sum(as.numeric(colnames(probabilities)) * probabilities[i,])
  print(expect)
  ie_expectancy[[i]] <- expect
}

ie <- unlist(ie_expectancy)
ie <- (18-ie)/(18)

final_raster <- data.frame(ie=ie,x=bnbrik_df$x,y=bnbrik_df$y)
head(final_raster)

coordinates(final_raster)=~x+y
gridded(final_raster)=TRUE
final_raster = raster(final_raster)
projection(final_raster)=projection(bnbrik)

# save raster
rf <- writeRaster(final_raster, filename="ie_yucatan.tif",
                  format="GTiff", overwrite=TRUE)