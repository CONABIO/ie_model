# load packages
library("bnlearn")
library("gRain")
library("raster")
library("ggplot2")
library("tidyterra")

# Discretize list of numeric variables wder
discretizeCols <- function(bnbrik_df, numeric_var_vec,
                           breaks_vec=rep(5,length(numeric_var_vec)),
                           method="interval"){
  
  bnbrik_df[,numeric_var_vec] = bnlearn::discretize(bnbrik_df[,numeric_var_vec],
                                                    breaks=breaks_vec,
                                                    method=method)
  return(bnbrik_df)
}

df <- list.files('data/model_input/dataframe', full.names = TRUE) %>%
  map_dfr(read_csv)
# df <- read_csv('data/model_input/df_input_model_5.csv')
prior <- readRDS('output/prior_test.RData')
crs_text <- readRDS("data/model_input/crs_text.RData")

# Remove unwanted variables
# remove_var <- c('mad_mex_bosque','mad_mex_matorral')
remove_var <- c('')
df <- df[,!(names(df) %in% remove_var)]

# Transform to factors
df <- df  %>% 
  mutate(across(all_of(c("hemerobia","holdridge")), as.factor))
df <- discretizeCols(df,setdiff(names(df), c("x","y",
                                             "hemerobia","holdridge")))

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
writeRaster(r_exp, 'output/ie_exp.tif', overwrite=TRUE)
writeRaster(r_cat, 'output/ie_cat.tif', overwrite=TRUE)