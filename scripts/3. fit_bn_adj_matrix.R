# load packages
library("raster")
library("gRain")
library("bnlearn")

# load misc functions
source("./R/0. misc_functions.R")

# List of independent variable rasters.
indep_var_paths = list_files_with_exts("./indep_var_paths/",
                                  exts = "tif")

# Load dependent variable raster (will be used as base raster).
dep_var_path = "./delta_vp/hemerobia_250m.tif"

# Create raster brick where bands are [dep_var,indep_var_1,...,indep_var_n].
bnbrik = bnBrick(dep_var_path,indep_var_paths)

# To df and drop incomplete rows
bnbrik_df = data.frame(rasterToPoints(bnbrik))
bnbrik_df = bnbrik_df[complete.cases(bnbrik_df),]

# User must know which variables are factors and coerce them to factor.
bnbrik_df = factorCols(bnbrik_df,
                       c("hemerobia_250m", "zvh_31_lcc_h"))

names(bnbrik_df)

# User must know which variables are numeric and discretize them.
bnbrik_df = discretizeCols(bnbrik_df,
                           names(bnbrik_df)[3:24])

# Load adjacency matrix from csv.
ie_adj <- read.csv("./networks/ienet_v2.csv", header = TRUE, row.names = 1, stringsAsFactors = FALSE)
ie_adj[is.na(ie_adj)] <- 0

# Create a graph based on this adjacency matrix.
ie_graph = empty.graph(rownames(ie_adj))
amat(ie_graph) = as.matrix(ie_adj)

# Fit bayesian network.
fitted = bn.fit(ie_graph, bnbrik_df[,3:25], method = "bayes")

# We use the junction tree algorithm to create 
# an independence network that we can query
prior <- compile(as.grain(fitted))


