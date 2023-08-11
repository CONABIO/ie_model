# load packages
library("bnlearn")

#' Function to predict ie
#' @param df_total Dataframe
#' @param prior RData trained Bayesian network
#' @param n_parts Number of partitions
#' @param i_cluster i-th partition of the dataframe

predict_ie_bn <- function(df_total, prior, n_parts=200, i_cluster) {
  # split data
  n_row <- nrow(df_total)
  size <- trunc(n_row/n_parts)
  n_fin <- i_cluster*(size+1)
  n_ini <- n_fin-size
  
  if(n_fin>n_row) {
    n_fin <- n_row
  }
  
  df <- df_total[n_ini:n_fin,]
  
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
  
  # raster with most probable category
  category <- colnames(probabilities)[apply(probabilities,1,which.max)]
  df_cat <- data.frame(x=df$x,y=df$y,ie=category)
  
  # save rasters
  write.csv(df_exp,paste0('output/df_expectancy/df_exp_',i_cluster,'.csv'), 
            row.names = FALSE)
  write.csv(df_cat,paste0('output/df_categorical/df_cat_',i_cluster,'.csv'), 
            row.names = FALSE)
}

# df_total <- read.csv('data/prediction_input/df_input_test.csv')
# prior <- readRDS('data/prediction_input/prior_test.RData')
# n_parts <- 200
# 
# for (i in 1:1) {
#   print(i)
#   predict_ie_bn(df_total, prior, n_parts, i)
# }