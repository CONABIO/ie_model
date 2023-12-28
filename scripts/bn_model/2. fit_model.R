# Creates Bayesian network based on adjacency matrix, 
# trains it with input data 
# and saves the trained model

library('tidyverse')
library('bnlearn')
library('gRain')

matrix_file <- 'data/model_input/network/ienet.csv'
data_file <- 'data/model_input/discretized_df/df_input.csv'
output_file <- 'data/model_input/prior/prior.RData'

ie_adj <- read.csv(matrix_file, header = TRUE, 
                   row.names = 1, stringsAsFactors = FALSE)
df <- read_csv(data_file)

ie_adj[is.na(ie_adj)] <- 0
df <- df  %>% 
  mutate_at(vars(-x, -y), as.factor)

# Create graph
ie_graph <- empty.graph(rownames(ie_adj))
amat(ie_graph) <- as.matrix(ie_adj)

# Fit Bayesian network
fitted <- bn.fit(ie_graph, 
                 data.frame(df[,3:ncol(df)]), 
                 method = "bayes")

# Use the junction tree algorithm to create 
# an independence network that can be query
prior <- compile(as.grain(fitted))

saveRDS(prior, file=output_file)