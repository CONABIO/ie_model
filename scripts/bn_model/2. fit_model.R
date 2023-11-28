# creates Bayesian network based on matrix, trains it with input data 
# and saves the trained model

library('tidyverse')
library('bnlearn')
library('gRain')

matrix_file <- 'data/model_input/network/ienet.csv'
data_file <- 'data/model_input/discretized_df/df_input.csv'
output_file <- 'data/model_input/prior/prior.RData'

# read data
ie_adj <- read.csv(matrix_file, header = TRUE, 
                   row.names = 1, stringsAsFactors = FALSE)
df <- read.csv(data_file)
df <- df  %>% 
  mutate_at(vars(-x, -y), as.factor)

# Create a graph
ie_adj[is.na(ie_adj)] <- 0
ie_adj <- ie_adj[!(row.names(ie_adj) %in% remove_var),!(names(ie_adj) %in% remove_var)]
ie_graph <- empty.graph(rownames(ie_adj))
amat(ie_graph) <- as.matrix(ie_adj)

# Fit bayesian network.
fitted <- bn.fit(ie_graph, data.frame(df[,3:ncol(df)]), method = "bayes")

# We use the junction tree algorithm to create 
# an independence network that we can query
prior <- compile(as.grain(fitted))

# save model
saveRDS(prior, file=output_file)