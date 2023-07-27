library("tidyverse")
library("bnlearn")
library("gRain")
library("terra")
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

# read data
crs_text <- readRDS("data/model_input/crs_text.RData")
ie_adj <- read.csv("data/model_input/networks/ienet.csv", header = TRUE, 
                   row.names = 1, stringsAsFactors = FALSE)
df <- list.files('data/model_input/dataframe', full.names = TRUE) %>%
  map_dfr(read_csv)
# df <- read_csv('data/model_input/df_input_model_5.csv')

# Remove unwanted variables
# remove_var <- c('mad_mex_bosque','mad_mex_matorral')
remove_var <- c('')
df <- df[,!(names(df) %in% remove_var)]

# Transform to factors
df <- df  %>% 
  mutate(across(all_of(c("hemerobia","holdridge")), as.factor))
df <- discretizeCols(df,setdiff(names(df), c("x","y",
                                            "hemerobia","holdridge")))

# Create a graph
ie_adj[is.na(ie_adj)] <- 0
ie_adj <- ie_adj[!(row.names(ie_adj) %in% remove_var),!(names(ie_adj) %in% remove_var)]
ie_graph <- empty.graph(rownames(ie_adj))
amat(ie_graph) <- as.matrix(ie_adj)
# plot(ie_graph)

# Fit bayesian network.
fitted <- bn.fit(ie_graph, data.frame(df[,3:ncol(df)]), method = "bayes")

# We use the junction tree algorithm to create 
# an independence network that we can query
prior <- compile(as.grain(fitted))

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

ggplot() +
  geom_spatraster(data = r_cat)
freq(r_cat)
table(as.factor(as.numeric(category)),df$hemerobia)
sqrt(mean((as.numeric(df$hemerobia) - expectancy)^2))

# save rasters
writeRaster(r_exp, 'output/ie_exp.tif', overwrite=TRUE)
writeRaster(r_cat, 'output/ie_cat.tif', overwrite=TRUE)

# save model
saveRDS(fitted, file="output/fitted.RData")
saveRDS(prior, file="output/prior.RData")