library("tidyverse")
library("bnlearn")

df_total <- list.files('data/model_input/dataframe', full.names = TRUE) %>%
  map_dfr(read_csv)

df_total <- read_csv('data/model_input/dataframe/df_input_model_1.csv')

df <- sample_n(df_total, 1000)
plot(df$x, df$y)

# User must know which variables are factors and coerce them to factor.
df <- df  %>% 
  mutate(across(all_of(c("hemerobia","holdridge")), as.factor))
names(df)

# User must know which variables are numeric and discretize them.
df <- discretizeCols(df,
                           names(df)[3:24])

# Load adjacency matrix from csv.
ie_adj <- read.csv("data/networks/ienet.csv", header = TRUE, 
                   row.names = 1, stringsAsFactors = FALSE)
ie_adj[is.na(ie_adj)] <- 0

# Create a graph based on this adjacency matrix.
ie_graph <- empty.graph(rownames(ie_adj))
amat(ie_graph) <- as.matrix(ie_adj)

# Fit bayesian network.
fitted <- bn.fit(ie_graph, df[,3:25], method = "bayes")

# We use the junction tree algorithm to create 
# an independence network that we can query
prior <- compile(as.grain(fitted))
