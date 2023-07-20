# Load packages
library("bnlearn")
#library("gRain")
library("tools")
library("tidyverse")

# load misc functions
source("scripts/0. misc_functions.R")

# Read a file with an associated adjacency matrix
adj_csv <- read.table("data/model_input/networks/ienet.csv",
                     header=TRUE,
                     row.names=1,
                     sep=",",
                     stringsAsFactors=FALSE)

adj_csv <- adj_csv %>% 
  replace(is.na(.), 0)
  

# Initialize an empty graph of appropriate size
bngraph <- initAdj(adj_csv)

# Set graph arcs based on adjacency matrix
amat(bngraph) <- as.matrix(adj_csv)

# Visualize graph
plot(bngraph)
