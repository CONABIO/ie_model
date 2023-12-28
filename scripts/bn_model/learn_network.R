# Learns the structure of the Bayesian network, 
# trains it with input data 
# and saves the trained model

library('tidyverse')
library('bnlearn')
library('gRain')
library('igraph')

# Input data
df <- read.csv('data/model_input/discretized_df/df_input.csv')
# Set of arcs to be included in the graph
whitelist <- read.csv('data/model_input/network/whitelist.csv')
# Set of arcs not to be included in the graph
blacklist <- read.csv('data/model_input/network/blacklist.csv')
  
df <- df  %>% 
  mutate_at(vars(-x, -y), as.factor)

# Learn the structure of the network 
network <-hc(df %>% select(-c('x','y')),
             whitelist = whitelist,
             blacklist = blacklist)

# Fit Bayesian network
fitted <- bn.fit(network, data.frame(df[,3:ncol(df)]), method = "bayes")

# Use the junction tree algorithm to create 
# an independence network that can be query
prior <- compile(as.grain(fitted))

# Plot network
gig <- as(prior$dag, "igraph")
jpeg(file="output/red.png", width = 465, height = 225, units='mm', res = 300)
plot(gig, edge.arrow.size = .2)
dev.off()

saveRDS(prior, file="data/model_input/prior/prior.RData")