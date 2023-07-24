library("tidyverse")
library("bnlearn")
library("gRain")
library("terra")
library("ggplot2")
library("tidyterra")


# Discretize list of numeric valued variables
discretizeCols <- function(bnbrik_df,
                          numeric_var_vec,
                          breaks_vec=rep(5,length(numeric_var_vec)),
                          method="interval"){
  
  bnbrik_df[,numeric_var_vec] = bnlearn::discretize(bnbrik_df[,numeric_var_vec],
                                                    breaks=breaks_vec,
                                                    method=method)
  return(bnbrik_df)
}

remove_var <- c('mad_mex_bosque','mad_mex_matorral')
# remove_var <- c('')


# df <- list.files('data/model_input/dataframe', full.names = TRUE) %>%
  # map_dfr(read_csv)
 
df <- read_csv('data/model_input/df_input_model_5.csv')

df <- df[,!(names(df) %in% remove_var)]

# User must know which variables are factors and coerce them to factor.
df <- df  %>% 
  mutate(across(all_of(c("hemerobia","holdridge")), as.factor))

# User must know which variables are numeric and discretize them.
names_df <- names(df)
df <- discretizeCols(df,setdiff(names_df, c("x","y",
                                            "hemerobia","holdridge")))
summary(df)

# Load adjacency matrix from csv.
ie_adj <- read.csv("data/model_input/networks/ienet.csv", header = TRUE, 
                   row.names = 1, stringsAsFactors = FALSE)
ie_adj[is.na(ie_adj)] <- 0

# Remove variables
ie_adj <- ie_adj[!(row.names(ie_adj) %in% remove_var),!(names(ie_adj) %in% remove_var)]

# Create a graph based on this adjacency matrix.
ie_graph <- empty.graph(rownames(ie_adj))
amat(ie_graph) <- as.matrix(ie_adj)

# Visualize graph
plot(ie_graph)

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
