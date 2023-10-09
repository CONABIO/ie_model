library('tidyverse')
library('bnlearn')
library('gRain')
library('igraph')

df <- read.csv('data/model_input/discretized_df/df_input.csv')
whitelist <- read.csv('data/model_input/network/whitelist.csv')
blacklist <- read.csv('data/model_input/network/blacklist.csv')
  
df <- df  %>% 
  mutate_at(vars(-x, -y), as.factor)

network <-hc(df %>% select(-c('x','y')),
             whitelist = whitelist,
             blacklist = blacklist)

# Fit bayesian network.
fitted <- bn.fit(network, data.frame(df[,3:ncol(df)]), method = "bayes")

# We use the junction tree algorithm to create 
# an independence network that we can query
prior <- compile(as.grain(fitted))

# Plot network
gig <- as(prior$dag, "igraph")
jpeg(file="output/red.png", width = 465, height = 225, units='mm', res = 300)
plot(gig, edge.arrow.size = .2)
dev.off()

saveRDS(prior, file="data/model_input/prior/prior.RData")